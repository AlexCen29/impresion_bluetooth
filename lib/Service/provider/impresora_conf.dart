//provider para almacnerar la impresora seleccionada
import 'package:flutter/material.dart';

class ImpresoraConfProvider with ChangeNotifier{
  String _nombreImpresora = '';
  String _macImpresora = '';
  String _formatoImpresora = '';

  //seters
  set nombreImpresora(String nombreImpresora){
    _nombreImpresora = nombreImpresora;
    notifyListeners();
  }
  set macImpresora(String macImpresora){
    _macImpresora = macImpresora;
    notifyListeners();
  }
  set formatoImpresora(String formatoImpresora){
    _formatoImpresora = formatoImpresora;
    notifyListeners();
  }
  //getes
  String get nombreImpresora => _nombreImpresora;
  String get macImpresora => _macImpresora;
  String get formatoImpresora => _formatoImpresora;

  void clearImpresora(){
    _nombreImpresora = '';
    _macImpresora = '';
    _formatoImpresora = '';
    notifyListeners();
  }
}