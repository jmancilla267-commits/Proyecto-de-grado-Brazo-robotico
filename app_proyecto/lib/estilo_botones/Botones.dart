import 'package:app_proyecto/colores/Colores_Estilos.dart';
import 'package:flutter/material.dart';

class Botones extends StatefulWidget {
  final String texto;
  final Function() oprimir;
  const Botones({super.key, required this.texto, required this.oprimir});

  @override
  State<Botones> createState() => _BotonesState();
}

class _BotonesState extends State<Botones> {

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: (){widget.oprimir();},
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all (AppColores.fondoComponentesSelecionados),
      ),
      child: Text(widget.texto, style: AppEstilos.textoCuerpo),
    );
  }
}
