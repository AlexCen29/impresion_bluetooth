import 'dart:async';
import 'package:bluetooth_impresion/Screens/bluetooth_configuracion/widgets/show_dialog_loading.dart';
import 'package:bluetooth_impresion/Service/provider/impresora_conf.dart';
import 'package:bluetooth_impresion/Service/provider/ticket_venta.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImpresionTicketScreen extends StatefulWidget {
  @override
  _ImpresionTicketScreenState createState() => _ImpresionTicketScreenState();
}

class _ImpresionTicketScreenState extends State<ImpresionTicketScreen> {
  String _status = '';
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _checkConnectionStatus();
  }

  Future<void> _checkConnectionStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String macImpresora = prefs.getString('macImpresora') ?? '';
    String nombreImpresora = prefs.getString('nombreImpresora') ?? '';
    if (macImpresora.isNotEmpty) {
      bool isConnected = await PrintBluetoothThermal.connectionStatus;
      if (isConnected) {
        setState(() {
          _isConnected = true;
          _status = 'Conectado a $nombreImpresora';
          print('Conectado: $isConnected');
        });
      } else {
        print("❤️❤️❤️");
        print("Conexion: $isConnected");
        await _connect(
            BluetoothInfo(name: nombreImpresora, macAdress: macImpresora));
      }
    }
  }

  Future<void> _connect(BluetoothInfo device) async {
    showDialogLoging(context);
    setState(() {
      _status = 'Conectando...';
    });

    try {
      final bool connected = await PrintBluetoothThermal.connect(
          macPrinterAddress: device.macAdress);
      if (connected) {
        if (mounted) {
          setState(() {
            _isConnected = true;
            device = device;
            _status = 'Conectado a ${device.name}';
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
        });
      }
    }
    Navigator.pop(context);
  }

  Future<void> _printTicket(TicketCompraProvider provider) async {
    String formatoImpresora =
        Provider.of<ImpresoraConfProvider>(context, listen: false)
            .formatoImpresora;
    List<int> ticket;
    showDialogLoging(context);

    try {
      if (formatoImpresora == "58mm") {
        ticket = await _generateTicket58(provider);
      } else {
        //ticket = await _generateTicket80(provider);
        //esto es temporal
        ticket = await _generateTicket58(provider);
      }
      final result = await PrintBluetoothThermal.writeBytes(ticket);
      setState(() {
        _status =
            result ? 'Ticket impreso con éxito' : 'Error al imprimir el ticket';
      });
      //provider.original=false;
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _status = 'Error al imprimir: $e';
      });
    } finally {
      setState(() {
      });
    }
    Navigator.pop(context);
  }

  //checar esto para la imagen
  
  /*final ByteData data = await rootBundle.load('assets/mylogo.jpg');
    final Uint8List bytesImg = data.buffer.asUint8List();
    img.Image? image = img.decodeImage(bytesImg);*/

  Future<List<int>> _generateTicket58(TicketCompraProvider provider) async {
    var now = DateTime.now();
    var dateFormatter = DateFormat('dd/MM/yyyy');
    var timeFormatter = DateFormat('hh:mm a');
    String formattedDate = dateFormatter.format(now);
    String formattedTime = timeFormatter.format(now);
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    //encabezado
    bytes += generator.text(provider.nombre,
        styles: const PosStyles(bold: true, align: PosAlign.center, codeTable: 'CP1252'));
    bytes += generator.feed(1);
    bytes += generator.text(provider.direccion,
        styles: const PosStyles(align: PosAlign.center, codeTable: 'CP1252'));
    bytes += generator.feed(1);
    //fecha y hora
    bytes += generator.row([
      PosColumn(
        text: formattedDate,
        width: 6,
        styles: const PosStyles(
            align: PosAlign.left,
            height: PosTextSize.size1,
            width: PosTextSize.size1),
      ),
      PosColumn(
        text: formattedTime,
        width: 6,
        styles: const PosStyles(
            align: PosAlign.right,
            height: PosTextSize.size1,
            width: PosTextSize.size1),
      ),
    ]);
    bytes += generator.text('CHEQUE DE CONSUMO',
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(1);
    bytes += generator.row([
      PosColumn(
        text: 'Folio: ${provider.folio}',	
        width: 6,
        styles: const PosStyles(
            align: PosAlign.left,
            height: PosTextSize.size1,
            width: PosTextSize.size1),
      ),
      PosColumn(
        text: 'Comanda: ${provider.comanda}',
        width: 6,
        styles: const PosStyles(
            align: PosAlign.right,
            height: PosTextSize.size1,
            width: PosTextSize.size1),
      ),
    ]);
    //detalle de la compra encabezado
    bytes += generator.row([
      PosColumn(
        text: 'CANT',
        width: 3,
        styles: const PosStyles(
            align: PosAlign.left,
            bold: true,
            height: PosTextSize.size1,
            width: PosTextSize.size1),
      ),
      PosColumn(
        text: 'DESCRIPCION',
        width: 6,
        styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size1,
            width: PosTextSize.size1,
            codeTable: 'CP1252'),
      ),
      PosColumn(
        text: 'TOTAL',
        width: 3,
        styles: const PosStyles(
            align: PosAlign.right,
            bold: true,
            height: PosTextSize.size1,
            width: PosTextSize.size1),
      ),
    ]);
    // Detalles de la compra
    for (Producto item in provider.productos ?? []) {
      bytes += generator.row([
        PosColumn(
          text: item.cantidad.toStringAsFixed(2),
          width: 3,
          styles: const PosStyles(
              align: PosAlign.left,
              height: PosTextSize.size1,
              width: PosTextSize.size1),
        ),
        PosColumn(
          text: item.descripcion,
          width: 6,
          styles: const PosStyles(
              align: PosAlign.center,
              height: PosTextSize.size1,
              width: PosTextSize.size1),
        ),
        PosColumn(
          text: '\$${(item.precio*item.cantidad).toStringAsFixed(2)}',
          width: 3,
          styles: const PosStyles(
              align: PosAlign.right,
              height: PosTextSize.size1,
              width: PosTextSize.size1),
        ),
      ]);
      bytes += generator.text('------------------------------',
          styles: const PosStyles(bold: true, align: PosAlign.center));
    }
    //importes de la compra
    bytes += generator.row([
      PosColumn(
        text: '',
        width: 3,
        styles: const PosStyles(
            align: PosAlign.left,
            height: PosTextSize.size1,
            width: PosTextSize.size1),
      ),
      PosColumn(
        text: 'Subtotal',
        width: 6,
        styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size1,
            width: PosTextSize.size1),
      ),
      PosColumn(
        text: provider.subtotalCompra.toString(),
        width: 3,
        styles: const PosStyles(
            align: PosAlign.right,
            height: PosTextSize.size1,
            width: PosTextSize.size1),
      ),
    ]);
    bytes += generator.row([
      PosColumn(
        text: '',
        width: 3,
        styles: const PosStyles(
            align: PosAlign.left,
            height: PosTextSize.size1,
            width: PosTextSize.size1),
      ),
      PosColumn(
        text: 'IVA',
        width: 6,
        styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size1,
            width: PosTextSize.size1),
      ),
      PosColumn(
        text: provider.ivaCompra.toString(),
        width: 3,
        styles: const PosStyles(
            align: PosAlign.right,
            height: PosTextSize.size1,
            width: PosTextSize.size1),
      ),
    ]);
    bytes += generator.feed(1);
    
    //tota con iva
    bytes += generator.row([
      PosColumn(
        text: '',
        width: 2,
        styles: const PosStyles(
            align: PosAlign.left,
            height: PosTextSize.size1,
            width: PosTextSize.size1),
      ),
      PosColumn(
        text: 'Importe Total',
        width: 6,
        styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size1,
            width: PosTextSize.size1),
      ),
      PosColumn(
        text: ((provider.subtotalCompra+provider.ivaCompra).toStringAsFixed(2)).toString(),
        width: 4,
        styles: const PosStyles(
            align: PosAlign.right,
            bold: true,
            height: PosTextSize.size1,
            width: PosTextSize.size1),
      ),
    ]);
    bytes += generator.feed(1);
    
    //detalles
    bytes += generator.row([
      PosColumn(
        text: 'Mesero:',
        width: 4,
        styles: const PosStyles(
            align: PosAlign.left,
            bold: true,
            height: PosTextSize.size1,
            width: PosTextSize.size1,
            codeTable: 'CP1252'),
      ),
      PosColumn(
        text: provider.mesero,
        width: 8,
        styles: const PosStyles(
            align: PosAlign.left,
            height: PosTextSize.size1,
            width: PosTextSize.size1),
      ),
    ]);
    bytes += generator.row([
      PosColumn(
        text: 'Cajero:',
        width: 4,
        styles: const PosStyles(
            align: PosAlign.left,
            bold: true,
            height: PosTextSize.size1,
            width: PosTextSize.size1),
      ),
      PosColumn(
        text: provider.cajero,
        width: 8,
        styles: const PosStyles(
            align: PosAlign.left,
            height: PosTextSize.size1,
            width: PosTextSize.size1,
            codeTable: 'CP1252'),
      ),
    ]);
    bytes += generator.feed(1);

    //Pie de página
    bytes += generator.text(provider.telefono,
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text(provider.correo,
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('¡¡GRACIAS POR SU PREFERENCIA!!',
        styles: const PosStyles(
            align: PosAlign.left, codeTable: 'CP1252'));
    bytes += generator.row([
      PosColumn(
        text: provider.app,
        width: 6,
        styles: const PosStyles(
            align: PosAlign.right,
            bold: true,
            height: PosTextSize.size1,
            width: PosTextSize.size1,
            codeTable: 'CP1252'),
      ),
      PosColumn(
        text: provider.version,
        width: 6,
        styles: const PosStyles(
            align: PosAlign.left,
            bold: true,
            height: PosTextSize.size1,
            width: PosTextSize.size1,
            codeTable: 'CP1252'),
      ),
    ]);
    bytes += generator.feed(1);
    bytes += generator.cut();
    return bytes;
  }

  // Future<List<int>> _generateTicket80(TicketCompraProvider provider) async {
  //   var now = DateTime.now();
  //   var dateFormatter = DateFormat('dd/MM/yyyy');
  //   var timeFormatter = DateFormat('hh:mm a');
  //   String formattedDate = dateFormatter.format(now);
  //   String formattedTime = timeFormatter.format(now);
  //   final profile = await CapabilityProfile.load();
  //   final generator = Generator(PaperSize.mm80, profile);
  //   Empresa empresa = context.read<EmpresaProvider>().empresaList[0];
  //   List<int> bytes = [];

  //   // Encabezado
  //   bytes += generator.text(empresa.nombreComercial,
  //       styles: const PosStyles(bold: true, align: PosAlign.center));
  //   bytes += generator.text(empresa.rfc,
  //       styles: const PosStyles(bold: true, align: PosAlign.center));
  //   bytes += generator.feed(1);
  //   bytes += generator.text(
  //       '${empresa.calle} ${empresa.referencia} Col.: ${empresa.colonia} C.P.: ${empresa.cp} ${empresa.descMunicipio} ${empresa.descEstado}',
  //       styles: const PosStyles(bold: true, align: PosAlign.center));
  //   bytes += generator.feed(2);
  //   bytes += generator.text('ORIGINAL',
  //       styles: const PosStyles(
  //           bold: true,
  //           align: PosAlign.center,
  //           height: PosTextSize.size2,
  //           width: PosTextSize.size2));
  //   bytes += generator.row([
  //     PosColumn(
  //       text: "$formattedDate ",
  //       width: 6,
  //       styles: const PosStyles(
  //           align: PosAlign.right,
  //           height: PosTextSize.size1,
  //           width: PosTextSize.size1),
  //     ),
  //     PosColumn(
  //       text: " $formattedTime",
  //       width: 6,
  //       styles: const PosStyles(
  //           align: PosAlign.left,
  //           height: PosTextSize.size1,
  //           width: PosTextSize.size1),
  //     ),
  //   ]);
  //   bytes += generator.row([
  //     PosColumn(
  //       text: "Ticket#: ${provider.folio}",
  //       width: 6,
  //       styles: const PosStyles(
  //           align: PosAlign.left,
  //           height: PosTextSize.size1,
  //           width: PosTextSize.size1),
  //     ),
  //     PosColumn(
  //       text: "ATENDIO: ${provider.atendio}",
  //       width: 6,
  //       styles: const PosStyles(
  //           align: PosAlign.left,
  //           height: PosTextSize.size1,
  //           width: PosTextSize.size1),
  //     ),
  //   ]);
  //   bytes += generator.row([
  //     PosColumn(
  //         text: '(', width: 1, styles: const PosStyles(align: PosAlign.left)),
  //     PosColumn(
  //       text: 'NORMAL',
  //       width: 10,
  //       styles: const PosStyles(
  //           align: PosAlign.center,
  //           bold: true,
  //           height: PosTextSize.size1,
  //           width: PosTextSize.size1),
  //     ),
  //     PosColumn(
  //         text: ')', width: 1, styles: const PosStyles(align: PosAlign.right)),
  //   ]);
  //   //DAtos del cliente
  //   bytes += generator.feed(2);
  //   bytes += generator.text('DATOS DEL CLIENTE',
  //       styles: const PosStyles(bold: true, align: PosAlign.center));
  //   bytes += generator.text('-------------------',
  //       styles: const PosStyles(
  //           bold: true, align: PosAlign.center, width: PosTextSize.size2));
  //   bytes += generator.text('NOMBRE: ${provider.cliente!.nombreCliente}',
  //       styles: const PosStyles(align: PosAlign.left));
  //   bytes += generator.row([
  //     PosColumn(
  //       text: "RFC: ${provider.cliente!.rfcCliente}",
  //       width: 6,
  //       styles: const PosStyles(
  //           align: PosAlign.left,
  //           height: PosTextSize.size1,
  //           width: PosTextSize.size1),
  //     ),
  //     PosColumn(
  //       text: "TEL: ${provider.cliente!.telCliente}",
  //       width: 6,
  //       styles: const PosStyles(
  //           align: PosAlign.left,
  //           height: PosTextSize.size1,
  //           width: PosTextSize.size1),
  //     ),
  //   ]);
  //   bytes += generator.text('DIRECCION: ${provider.cliente!.dirCliente}',
  //       styles: const PosStyles(align: PosAlign.left));
  //   bytes += generator.feed(1);
  //   //ENCABEZDO de compra
  //   bytes += generator.text("DESCRIPCION",
  //       styles: const PosStyles(
  //           align: PosAlign.left,
  //           bold: true,
  //           width: PosTextSize.size1,
  //           height: PosTextSize.size1));
  //   bytes += generator.row([
  //     PosColumn(
  //       text: 'CANT',
  //       width: 4,
  //       styles: const PosStyles(
  //           align: PosAlign.left,
  //           bold: true,
  //           height: PosTextSize.size1,
  //           width: PosTextSize.size1),
  //     ),
  //     PosColumn(
  //       text: 'P.UNITARIO',
  //       width: 4,
  //       styles: const PosStyles(
  //           align: PosAlign.center,
  //           bold: true,
  //           height: PosTextSize.size1,
  //           width: PosTextSize.size1),
  //     ),
  //     PosColumn(
  //       text: 'IMPORTE',
  //       width: 4,
  //       styles: const PosStyles(
  //           align: PosAlign.right,
  //           bold: true,
  //           height: PosTextSize.size1,
  //           width: PosTextSize.size1),
  //     ),
  //   ]);
  //   bytes += generator.text('-------------------',
  //       styles: const PosStyles(
  //           bold: true, align: PosAlign.center, width: PosTextSize.size2));
  //   // Detalles de la compra
  //   for (DetallesVenta item in provider.listaDetalles ?? []) {
  //     bytes += generator.text(item.descripcion,
  //         styles: const PosStyles(
  //             align: PosAlign.left,
  //             width: PosTextSize.size1,
  //             height: PosTextSize.size1));
  //     bytes += generator.row([
  //       PosColumn(
  //         text: item.cantidad.toStringAsFixed(2),
  //         width: 4,
  //         styles: const PosStyles(
  //             align: PosAlign.left,
  //             bold: true,
  //             height: PosTextSize.size1,
  //             width: PosTextSize.size1),
  //       ),
  //       PosColumn(
  //         text: "\$${item.precioReal.toStringAsFixed(2)}",
  //         width: 4,
  //         styles: const PosStyles(
  //             align: PosAlign.center,
  //             bold: true,
  //             height: PosTextSize.size1,
  //             width: PosTextSize.size1),
  //       ),
  //       PosColumn(
  //         text: '\$${item.importe.toStringAsFixed(2)}',
  //         width: 4,
  //         styles: const PosStyles(
  //             align: PosAlign.right,
  //             bold: true,
  //             height: PosTextSize.size1,
  //             width: PosTextSize.size1),
  //       ),
  //     ]);
  //     bytes += generator.feed(1);
  //   }
  //   bytes += generator.text('-------------------',
  //       styles: const PosStyles(
  //           bold: true, align: PosAlign.center, width: PosTextSize.size2));
  //   //TOTAL CAMBIO DESCUENTO
  //   bytes += generator.row([
  //     PosColumn(
  //       text: '',
  //       width: 4,
  //     ),
  //     PosColumn(
  //       text: 'TOTAL DESCUENTO:',
  //       width: 4,
  //       styles: const PosStyles(
  //           align: PosAlign.center,
  //           height: PosTextSize.size1,
  //           width: PosTextSize.size1),
  //     ),
  //     PosColumn(
  //       text: provider.totalDescuento.toStringAsFixed(2),
  //       width: 4,
  //       styles: const PosStyles(
  //           align: PosAlign.right,
  //           height: PosTextSize.size1,
  //           width: PosTextSize.size1),
  //     ),
  //   ]);
  //   bytes += generator.feed(1);
  //   bytes += generator.row([
  //     PosColumn(
  //       text: '',
  //       width: 4,
  //     ),
  //     PosColumn(
  //       text: 'TOTAL:',
  //       width: 4,
  //       styles: const PosStyles(
  //           align: PosAlign.center,
  //           bold: true,
  //           height: PosTextSize.size1,
  //           width: PosTextSize.size1),
  //     ),
  //     PosColumn(
  //       text: provider.total.toStringAsFixed(2),
  //       width: 4,
  //       styles: const PosStyles(
  //           align: PosAlign.right,
  //           bold: true,
  //           height: PosTextSize.size1,
  //           width: PosTextSize.size1),
  //     ),
  //   ]);
  //   bytes += generator.feed(1);
  //   bytes += generator.row([
  //     PosColumn(
  //       text: 'ENTREGO:',
  //       width: 2,
  //       styles: const PosStyles(
  //           align: PosAlign.center,
  //           bold: true,
  //           height: PosTextSize.size1,
  //           width: PosTextSize.size1),
  //     ),
  //     PosColumn(
  //       text: (provider.total + provider.cambio).toStringAsFixed(2),
  //       width: 4,
  //       styles: const PosStyles(
  //           align: PosAlign.right,
  //           bold: true,
  //           height: PosTextSize.size1,
  //           width: PosTextSize.size1),
  //     ),
  //     PosColumn(
  //       text: 'CAMBIO:',
  //       width: 2,
  //       styles: const PosStyles(
  //           align: PosAlign.center,
  //           bold: true,
  //           height: PosTextSize.size1,
  //           width: PosTextSize.size1),
  //     ),
  //     PosColumn(
  //       text: provider.cambio.toStringAsFixed(2),
  //       width: 4,
  //       styles: const PosStyles(
  //           align: PosAlign.right,
  //           bold: true,
  //           height: PosTextSize.size1,
  //           width: PosTextSize.size1),
  //     ),
  //   ]);
  //   bytes += generator.feed(1);
  //   bytes += generator.text('**************************************',
  //       styles: const PosStyles(align: PosAlign.center));
  //   bytes += generator.feed(1);
  //   //forma de pago
  //   StringBuffer formaPagoBuffer = StringBuffer('FORMA DE PAGO: ');
  //   for (TipoPago item in provider.tiposDePago ?? []) {
  //     if (item.valorPago > 0) {
  //       formaPagoBuffer.write('${item.tipoPago}= \$${item.valorPago} ');
  //     }
  //   }
  //   bytes += generator.text(formaPagoBuffer.toString().trim());
  //   bytes += generator.feed(1);
  //   //Pie de página
  //   bytes += generator.text('**************************************',
  //       styles: const PosStyles(align: PosAlign.center));
  //   bytes += generator.text('¡Gracias por su compra!',
  //       styles: const PosStyles(align: PosAlign.left, bold: true));
  //   bytes += generator.feed(1);
  //   bytes += generator.text('¡Excelente día!',
  //       styles: const PosStyles(
  //           align: PosAlign.left, bold: true, codeTable: 'CP1252'));
  //   bytes += generator.feed(1);
  //   bytes += generator.text('**************************************',
  //       styles: const PosStyles(bold: true, align: PosAlign.center));
  //   bytes += generator.row([
  //     PosColumn(
  //       text: "ATENCION A CLIENTES",
  //       width: 6,
  //       styles: const PosStyles(
  //           align: PosAlign.center,
  //           height: PosTextSize.size1,
  //           width: PosTextSize.size1),
  //     ),
  //     PosColumn(
  //       text: empresa.telefono,
  //       width: 6,
  //       styles: const PosStyles(
  //           align: PosAlign.center,
  //           height: PosTextSize.size1,
  //           width: PosTextSize.size1),
  //     ),
  //   ]);
  //   bytes+=generator.feed(1);
  //   bytes += generator.cut();
  //   return bytes;
  // }

  Widget _buildTicketPreview(TicketCompraProvider provider) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Previsualización del Ticket de venta',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const Text('COMPROBANTE DE VENTA',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Text('Ticket #21'),
            Text('Atendió: ${provider.mesero}'),
            const SizedBox(height: 8),
            Text('CAJERO: ${provider.cajero ?? 'N/A'}'),
            const SizedBox(height: 8),
            const Text('DETALLE DE COMPRA',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            for (var item in provider.productos ?? [])
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${item.cantidad}x ${item.descripcion}'),
                  Text('\$${(item.precio * item.cantidad).toStringAsFixed(2)}'),
                ],
              ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('SUBTOTAL:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('\$${provider.subtotalCompra.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('IVA:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('\$${provider.ivaCompra.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('IMPORTE TOTAL:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('\$${(provider.subtotalCompra + provider.ivaCompra).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            // const SizedBox(height: 8),
            // const SizedBox(height: 8),
            // const Text('¡Gracias por su preferencia!',
            //     style: TextStyle(fontWeight: FontWeight.bold)),
            // const Text('¡Excelente día!'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ticketProvider = Provider.of<TicketCompraProvider>(context);
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    var orientation = MediaQuery.of(context).orientation;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Imprimir Ticket',style:TextStyle(color: Colors.white)),
          //centerTitle: true,
          backgroundColor: Colors.blue[800],
          //elevation: 0,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue[800]!, Colors.blue[50]!],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0, left: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTicketPreview(ticketProvider),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: !_isConnected
                          ? null
                          : () async => await _printTicket(ticketProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Imprimir Ticket',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _status,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: Offset(1.0, 1.0),
                            blurRadius: 3.0,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
