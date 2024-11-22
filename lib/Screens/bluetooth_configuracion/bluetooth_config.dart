import 'package:bluetooth_impresion/Screens/bluetooth_configuracion/widgets/show_dialog_loading.dart';
import 'package:bluetooth_impresion/Service/provider/impresora_conf.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class ImpresionConfigScreen extends StatefulWidget {
  const ImpresionConfigScreen({super.key});

  @override
  State<ImpresionConfigScreen> createState() => _ImpresionConfigScreenState();
}

class _ImpresionConfigScreenState extends State<ImpresionConfigScreen> {
  List<BluetoothInfo> _devices = [];
  BluetoothInfo? _selectedDevice;
  bool _isLoading = false;
  String _status = '';
  bool _isConnected = false;
  @override
  void initState() {
    super.initState();
    _requestBluetoothPermission();
    _checkConnectionStatus();
  }

  Future<void> _checkConnectionStatus() async {
    bool isConnected = await PrintBluetoothThermal.connectionStatus;
    setState(() {
      _isConnected = isConnected;
    });
  }

  Future<void> _requestBluetoothPermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (statuses[Permission.bluetooth]!.isGranted &&
        statuses[Permission.bluetoothScan]!.isGranted &&
        statuses[Permission.bluetoothConnect]!.isGranted &&
        statuses[Permission.location]!.isGranted) {
      _getDevices();
    } else {
      setState(() {
        _status =
            'Se requieren permisos de Bluetooth y ubicación para usar esta función.';
      });
    }
  }

  Future<void> _getDevices() async {
    if (await Permission.bluetooth.isGranted) {
      setState(() {
        _isLoading = true;
        _status = 'Buscando dispositivos...';
      });

      try {
        final List<BluetoothInfo> devices =
            await PrintBluetoothThermal.pairedBluetooths;
        setState(() {
          _devices = devices;
          _status = devices.isEmpty ? 'No se encontraron dispositivos' : '';
        });
      } catch (e) {
        print('Error al buscar dispositivos: $e');
        setState(() {
          _status =
              'Error al buscar dispositivos. Asegúrate de que el Bluetooth esté activado.';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _status = 'Se requieren permisos de Bluetooth para usar esta función.';
      });
    }
  }

  Future<void> _connect(BuildContext context, BluetoothInfo device) async {
    ImpresoraConfProvider impresora =
        Provider.of<ImpresoraConfProvider>(context, listen: false);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoading = true;
      _status = 'Conectando...';
    });

    try {
      final bool connected = await PrintBluetoothThermal.connect(
          macPrinterAddress: device.macAdress);
      if (connected) {
        if (mounted) {
          setState(() {
            _selectedDevice = device;
            _status = 'Conectado a ${device.name}';
            impresora.macImpresora = device.macAdress;
            impresora.nombreImpresora = device.name;
            prefs.setString("macImpresora", device.macAdress);
            prefs.setString("nombreImpresora", device.name);
            _checkConnectionStatus();
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _status = 'No se pudo conectar a ${device.name}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'Error al conectar: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _disconnect() async {
    try {
      await PrintBluetoothThermal.disconnect;
      setState(() {
        _selectedDevice = null;
        _status = 'Desconectado';
      });
    } catch (e) {
      setState(() {
        _status = 'Error al desconectar: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    var orientation = MediaQuery.of(context).orientation;
    ImpresoraConfProvider impresora =
        Provider.of<ImpresoraConfProvider>(context);
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Impresión bluetooth',
              style: TextStyle(
                color: Colors.white,
              )),
          backgroundColor: Colors.blue[400],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                    width: double.infinity,
                    child: (impresora.macImpresora.isEmpty)
                        ? Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Text(
                                    'Selecciona una impresora',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge!
                                        .copyWith(
                                          color: Colors.blue[800],
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  Text(_status,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium!
                                          .copyWith(
                                            color: Colors.red,
                                          )),
                                  const SizedBox(height: 16),
                                  _isLoading
                                      ? const CircularProgressIndicator()
                                      : ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: _devices.length,
                                          itemBuilder: (context, index) {
                                            final device = _devices[index];
                                            return ListTile(
                                                leading: Icon(Icons.print,
                                                    color: Colors.blue[800]),
                                                title: Text(device.name,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                subtitle:
                                                    Text(device.macAdress),
                                                trailing:
                                                    _selectedDevice == device
                                                        ? const Icon(
                                                            Icons.check_circle,
                                                            color: Colors.green)
                                                        : null,
                                                onTap: () async {
                                                  await _connect(context, device);
                                                  impresora.formatoImpresora = "58mm";
                                                  SharedPreferences prefs = await SharedPreferences.getInstance();
                                                  prefs.setString("formatoImpresora", "58mm");
                                                });
                                          },
                                        ),
                                ],
                              ),
                            ),
                          )
                        : Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                      Text(
                                        'Impresora emparejada ${Provider.of<ImpresoraConfProvider>(context).formatoImpresora}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge!
                                            .copyWith(
                                              color: Colors.blue[800],
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                  const SizedBox(height: 16),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[50],
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                                color: Colors.blue[200]!),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    (orientation ==
                                                            Orientation
                                                                .portrait)
                                                        ? "Nombre: \n${impresora.nombreImpresora}"
                                                        : "Nombre: ${impresora.nombreImpresora}",
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                    maxLines: 2,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    (orientation ==
                                                            Orientation
                                                                .portrait)
                                                        ? "Dirección MAC: \n${impresora.macImpresora}"
                                                        : "Dirección MAC: ${impresora.macImpresora}",
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                    ),
                                                    maxLines: 2,
                                                  ),
                                                ],
                                              ),
                                              Icon(
                                                (_isConnected)
                                                    ? Icons.check_circle
                                                    : Icons.cancel,
                                                color: (_isConnected)
                                                    ? Colors.green
                                                    : Colors.red,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 3,
                                        child: Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          alignment: WrapAlignment.end,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.only(
                                                  left: 4),
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: Colors.blue,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                    color: Colors.blueAccent),
                                              ),
                                              width: (orientation ==
                                                      Orientation.portrait)
                                                  ? width * 0.18
                                                  : height * 0.18,
                                              height: (orientation ==
                                                      Orientation.portrait)
                                                  ? width * 0.07
                                                  : height * 0.07,
                                              child: MyDropdownButton(
                                                items: const ["58mm", "80mm"],
                                                onSelected: (value) {
                                                  print(value);
                                                },
                                              ),
                                            ),
                                            _buildActionButton(context,
                                                icon: Icons.link,
                                                label: "Conectar",
                                                color: Colors.green,
                                                onPressed: () async {
                                              showDialogLoging(context);
                                              await _connect(
                                                  context,
                                                  BluetoothInfo(
                                                    name: impresora.nombreImpresora,
                                                    macAdress:impresora.macImpresora,
                                                  ));
                                              await _checkConnectionStatus();
                                              Navigator.pop(context);
                                            }),
                                            _buildActionButton(context,
                                                icon: Icons.link_off,
                                                label: "Desconectar",
                                                color: Colors.orange,
                                                onPressed: () {
                                              _disconnect();
                                              _checkConnectionStatus();
                                            }),
                                            _buildActionButton(
                                              context,
                                              icon: Icons.delete_outline,
                                              label: "Desemparejar",
                                              color: Colors.red,
                                              onPressed: () {
                                                _disconnect();
                                                impresora.clearImpresora();
                                                SharedPreferences.getInstance()
                                                    .then((prefs) {
                                                  prefs.remove("macImpresora");
                                                  prefs.remove("nombreImpresora");
                                                  prefs.remove("formatoImpresora");
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ))
              ],
            ),
          ),
        ),
        floatingActionButton: Opacity(
          opacity: impresora.macImpresora.isEmpty ? 1 : 0,
          child: FloatingActionButton(
            onPressed: _getDevices,
            tooltip: 'Buscar dispositivos',
            backgroundColor: Colors.blue[800],
            child: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildActionButton(
  BuildContext context, {
  required IconData icon,
  required String label,
  required Color color,
  required Function() onPressed,
}) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    var orientation = MediaQuery.of(context).orientation;
  return SizedBox(
  height: (orientation ==
          Orientation.portrait)
      ? width * 0.07
      : height * 0.07,
    child: ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label),
    ),
  );
}

class MyDropdownButton extends StatefulWidget {
  final List<String> items;
  final Function(String) onSelected;

  const MyDropdownButton({super.key, required this.items, required this.onSelected});

  @override
  _MyDropdownButtonState createState() => _MyDropdownButtonState();
}

class _MyDropdownButtonState extends State<MyDropdownButton> {
  String? selectedValue;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      String formatoImpresora = Provider.of<ImpresoraConfProvider>(context, listen: false).formatoImpresora;
      setState(() {
        selectedValue = (formatoImpresora.isNotEmpty) ? formatoImpresora : null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    var orientation = MediaQuery.of(context).orientation;
    String formatoImpresora = Provider.of<ImpresoraConfProvider>(context).formatoImpresora;
    selectedValue = (formatoImpresora.isNotEmpty) ? formatoImpresora : selectedValue;

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        isExpanded: true,
        hint: Center(
          child: Text(
            selectedValue ?? 'Formato',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        value: selectedValue,
        items: <DropdownMenuItem<String>>[
          const DropdownMenuItem<String>(
            value: null,
            enabled: false,
            child: Text(
              'Tamaño de papel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ...widget.items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            );
          }).toList(),
        ],
        onChanged: (String? value) async {
          if (value != null) {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString("formatoImpresora", value);
            Provider.of<ImpresoraConfProvider>(context, listen: false).formatoImpresora = value;
            setState(() {
              selectedValue = value;
            });
            widget.onSelected(value);
          }
        },
        selectedItemBuilder: (BuildContext context) {
          return widget.items.map<Widget>((String item) {
            return Center(
              child: Text(
                selectedValue == item ? item : '58mm',
                style: TextStyle(
                  fontSize: (orientation == Orientation.portrait)
                      ? width * 0.025
                      : height * 0.025,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }).toList();
        },
      ),
    );
  }
}