import 'package:flutter/material.dart';

void showDialogLoging(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return const PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    },
  );
}