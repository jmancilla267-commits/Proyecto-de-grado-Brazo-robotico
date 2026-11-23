// --- PopUp.dart: Notificaciones flotantes (SnackBar) para éxito, error o aviso ---
import 'package:flutter/material.dart';

class AppPopup {
  static void mostrar(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Cierra el anterior para que no se acumulen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje, style: TextStyle(color: const Color(0xFF000000))),
        backgroundColor: const Color(0xFFFFFFFF),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void mostrarError(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje, style: TextStyle(color: const Color(0xFF000000))),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void mostrarExito(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje, style: TextStyle(color: const Color(0xFF000000))),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}