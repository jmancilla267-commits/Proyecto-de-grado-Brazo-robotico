// --- Colores_Estilos.dart: Paleta y estilos tipográficos centralizados ---
import 'package:flutter/cupertino.dart';

class AppColores {
  static const Color primaro = Color(0xFF03187C);
  static const Color secundario = Color(0xFF08014B);
  static const Color acento = Color(0xFFFFFFFF);

  //color de los elemntos
  static const Color fondoelementos = Color(0xFF0E0146);
  static const Color fondoComponentes = Color(0xFF11015A);
  static const Color fondoComponentesSelecionados = Color(0xFF14068A);

  
  static const Color textosColor = Color(0xFFFFFFFF);
}
class AppEstilos {
  static const TextStyle textoTitulo = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColores.textosColor,
  );
  static const TextStyle textoSubtitulo = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColores.textosColor,
  );
  static const TextStyle textoCuerpo = TextStyle(
    fontSize: 14,
    color: AppColores.textosColor,
  );
}