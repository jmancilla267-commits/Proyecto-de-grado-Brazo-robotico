// --- cajasTexto.dart: Campo de texto reutilizable con estilo del proyecto ---
import 'package:app_proyecto/colores/Colores_Estilos.dart';
import 'package:flutter/material.dart';

class Cajatextos extends StatefulWidget {
  final String Textoinicial;
  final Function textoIntroducido;
  // ignore: non_constant_identifier_names
  const Cajatextos({
    super.key,
    required this.Textoinicial,
    required this.textoIntroducido,
  });

  @override
  State<Cajatextos> createState() => _CajatextosState();
}

class _CajatextosState extends State<Cajatextos> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: AppColores.fondoelementos,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: AppColores.fondoComponentesSelecionados,
          width: 2,
        ),
      ),
      child: TextField(
        style: AppEstilos.textoCuerpo,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: widget.Textoinicial,
          hintStyle: AppEstilos.textoCuerpo.copyWith(
            color: AppColores.textosColor.withOpacity(0.6),
          ),
        ),
        onChanged: (value) {
          widget.textoIntroducido(value);
        },
      ),
    );
  }
}
