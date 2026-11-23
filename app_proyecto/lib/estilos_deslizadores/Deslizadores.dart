import 'package:app_proyecto/colores/Colores_Estilos.dart';
import 'package:flutter/material.dart';

double valorPrueba = 0;

class DeslizadorCentral extends StatefulWidget {
  final double angulo;
  final double min;
  final double max;
  final String nombreParte;
  final Function cambioValor;
  const DeslizadorCentral({
    super.key,
    required this.angulo,
    required this.nombreParte,
    required this.cambioValor,
    required this.min,
    required this.max,
  });

  @override
  State<DeslizadorCentral> createState() => _DeslizadorCentralState();
}

class _DeslizadorCentralState extends State<DeslizadorCentral> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(widget.nombreParte, style: AppEstilos.textoSubtitulo),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColores.fondoComponentesSelecionados,
            inactiveTrackColor: AppColores.fondoComponentes,
            trackShape: CentrarBarra(),
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            activeColor: AppColores.fondoComponentesSelecionados,
            thumbColor: AppColores.acento,
            value: widget.angulo,
            min: widget.min,
            max: widget.max,
            divisions: (widget.max - widget.min).toInt(),
            label: widget.angulo.round().toString(),
            onChanged: (double value) {
              widget.cambioValor(value);
              setState(() {
                valorPrueba = value;
              });
            },
          ),
        ),
      ],
    );
  }
}

class CentrarBarra extends RoundedRectSliderTrackShape {
  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    double additionalActiveTrackHeight = 0.0,
    required RenderBox parentBox,
    Offset? secondaryOffset,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    required TextDirection textDirection,
    required Offset thumbCenter,
  }) {
    final trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final centerX = (trackRect.left + trackRect.right) / 2;

    final paintInactive = Paint()..color = sliderTheme.inactiveTrackColor!;
    final paintActive = Paint()..color = sliderTheme.activeTrackColor!;

    // Pinta toda la pista como inactiva (fondo)
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(trackRect, Radius.circular(trackRect.height / 2)),
      paintInactive,
    );

    if (thumbCenter.dx > centerX) {
      final Rect activeRect = Rect.fromLTRB(
        centerX,
        trackRect.top,
        thumbCenter.dx,
        trackRect.bottom,
      );
      context.canvas.drawRRect(
        RRect.fromRectAndRadius(
          activeRect,
          Radius.circular(activeRect.height / 2),
        ),
        paintActive,
      );
      final Rect inactiveRect = Rect.fromLTRB(
        thumbCenter.dx,
        trackRect.top,
        trackRect.right,
        trackRect.bottom,
      );
      context.canvas.drawRRect(
        RRect.fromRectAndRadius(
          inactiveRect,
          Radius.circular(inactiveRect.height / 2),
        ),
        paintInactive,
      );
    } else if (thumbCenter.dx < centerX) {
      final Rect inactiveRect = Rect.fromLTRB(
        thumbCenter.dx,
        trackRect.top,
        centerX,
        trackRect.bottom,
      );
      context.canvas.drawRRect(
        RRect.fromRectAndRadius(
          inactiveRect,
          Radius.circular(inactiveRect.height / 2),
        ),
        paintActive,
      );
      final Rect activeRect = Rect.fromLTRB(
        trackRect.left,
        trackRect.top,
        thumbCenter.dx,
        trackRect.bottom,
      );
      context.canvas.drawRRect(
        RRect.fromRectAndRadius(
          activeRect,
          Radius.circular(activeRect.height / 2),
        ),
        paintInactive,
      );
    }
  }
}

class Deslizadorlateral extends StatefulWidget {
  final double angulo;
  final double min;
  final double max;
  final String nombreParte;
  final Function cambioValor;
  const Deslizadorlateral({
    super.key,
    required this.angulo,
    required this.nombreParte,
    required this.cambioValor,
    required this.min,
    required this.max,
  });

  @override
  State<Deslizadorlateral> createState() => _DeslizadorlateralState();
}

class _DeslizadorlateralState extends State<Deslizadorlateral> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(widget.nombreParte, style: AppEstilos.textoSubtitulo),
        Slider(
          activeColor: AppColores.fondoComponentesSelecionados,
          inactiveColor: AppColores.fondoComponentes,
          thumbColor: AppColores.acento,
          value: widget.angulo,
          min: widget.min,
          max: widget.max,
          label: widget.angulo.round().toString(),
          divisions: (widget.max - widget.min).toInt(),
          onChanged: (double value) {
            widget.cambioValor(value);
            setState(() {
              valorPrueba = value;
            });
          },
        ),
      ],
    );
  }
}
