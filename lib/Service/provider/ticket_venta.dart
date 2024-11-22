import 'package:flutter/material.dart';

class TicketCompraProvider with ChangeNotifier {
  //datos de empresa
  String _nombre = "TICKS CAFÉ";
  String _direccion = "C 25 CENTRO";
  String _telefono = "9999999999";
  String _correo = "ticks@live.com.mx";
  //Folios
  String _folio = "33498";
  String _comanda = "7785";
  String _app = "COMANDERO MOVIL";
  String _version = " VERSIÓ 1.1.0";
  //datos de venta
  String _mesa="14";
  String _mesero="DANIEL SANDOVAL";
  String _Cajero="JUAN PEREZ";
  double _subtotal = 0.00;

  List<Producto> _productos = [
    Producto(cantidad: 2, descripcion: "CAFÉ AMERICANO", precio: 30.0),
    Producto(cantidad: 1, descripcion: "CROISSANT", precio: 25.0),
    Producto(cantidad: 1, descripcion: "MANTEQUILLA EXTRA", precio: 10.0),
    Producto(cantidad: 3, descripcion: "JUGO DE NARANJA", precio: 20.0),
    Producto(cantidad: 1, descripcion: "HIELO EXTRA", precio: 5.0),
  ];
  
  //gets
  String get nombre => _nombre;
  String get direccion => _direccion;
  String get folio => _folio;
  String get comanda => _comanda;
  String get mesa => _mesa;
  String get mesero => _mesero;
  String get cajero => _Cajero;
  String get telefono => _telefono;
  String get correo => _correo;
  String get app => _app;
  String get version => _version;
  List<Producto> get productos => _productos;

  double get subtotalCompra {
    _subtotal = 0.0;
    for (var producto in _productos) {
      _subtotal += producto.cantidad * producto.precio;
      _subtotal.toStringAsFixed(2);
    }
    return _subtotal;
  }

  double get ivaCompra {
    double iva = 0.0;
    iva = subtotalCompra * 0.16;
    iva.toStringAsFixed(2);
    return iva;
  }
}

class Producto {
  int cantidad;
  String descripcion;
  double precio;

  Producto({required this.cantidad, required this.descripcion, required this.precio});
}
