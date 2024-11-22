import 'package:bluetooth_impresion/Screens/bluetooth_configuracion/bluetooth_config.dart';
import 'package:bluetooth_impresion/Screens/bluetooth_ticket_visual/ticket_bluetooth.dart';
import 'package:bluetooth_impresion/Service/provider/impresora_conf.dart';
import 'package:bluetooth_impresion/Service/provider/ticket_venta.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ImpresoraConfProvider()),
        ChangeNotifierProvider(create: (_) => TicketCompraProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Impresion Bluetooth Modular'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  heroTag: 'settingsButton',
                  onPressed: () {
                    Navigator.push(context, CupertinoPageRoute(builder: (context) => const ImpresionConfigScreen()));
                  },
                  child: const Icon(Icons.settings),
                ),
                const SizedBox(width: 20),
                FloatingActionButton(
                  heroTag: 'printButton',
                  onPressed: () {
                    Navigator.push(context, CupertinoPageRoute(builder: (context) => ImpresionTicketScreen()));
                  },
                  child: const Icon(Icons.print),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}