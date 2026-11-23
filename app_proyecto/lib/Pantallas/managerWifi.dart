// ============================================================================
// Pantalla: Managerwifi
// Propósito: Permitir al usuario ingresar SSID y contraseña de una red Wi-Fi,
//            enviarlos al ESP32 en modo AP para su conexión a la red local (LAN)
//            y comprobar el estado del enlace.
// ============================================================================
import 'package:app_proyecto/colores/Colores_Estilos.dart';
import 'package:app_proyecto/conexiones/WebSocketManager.dart';
import 'package:app_proyecto/estilo_botones/Botones.dart';
import 'package:app_proyecto/estilo_botones/popup.dart';
import 'package:app_proyecto/estilo_textos/cajaTextos.dart';
import 'package:flutter/material.dart';

String nombreWifi = "";
String contraWifi = "";
ESP32WebSocket Wifi = ESP32WebSocket();// Instancia compartida de comunicación

class Managerwifi extends StatefulWidget {
  const Managerwifi({super.key});

  @override
  State<Managerwifi> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<Managerwifi> {
  String estadoDeConect = "Desconectado"; // Estado inicial

  @override
  void initState() {
    super.initState();
    // Esta línea escucha cualquier mensaje que venga del ESP32
    Wifi.onStatusUpdate = (nuevoEstado) {
      if (mounted) {
        // Verificamos si el widget sigue en pantalla
        setState(() {
          estadoDeConect = nuevoEstado;
        });
        if (nuevoEstado == "Conectado") {
          AppPopup.mostrarExito(context, "Conectado a la web del robot");
        }
      }
    };
    // Notificaciones de error (Pop-up tipo SnackBar)
    Wifi.onErrorPopup = (mensajeError) {
      if (mounted) {
        AppPopup.mostrarError(context, mensajeError);
      }
    };
    Wifi.onMostrarPopup = (mensaje) {
      if (mounted) {
        AppPopup.mostrar(context, mensaje);
      }
    };
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColores.fondoComponentes,
      appBar: AppBar(
        backgroundColor: AppColores.primaro,
        title: Text('Wifi', style: AppEstilos.textoTitulo),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Gestor de conexiones Wifi', style: AppEstilos.textoSubtitulo),
            // Aquí puedes agregar más widgets para gestionar las conexiones Wifi
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 16,
                      bottom: 8,
                      left: 16,
                      right: 16,
                    ),
                    child: Cajatextos(
                      Textoinicial: "Nombre de la red Wifi",
                      textoIntroducido: (value) {
                        nombreWifi = value;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
                    child: Cajatextos(
                      Textoinicial: "Contraseña de la red Wifi",
                      textoIntroducido: (value) {
                        contraWifi = value;
                      },
                    ),
                  ),
                  Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Estado de la conexión: ',
                        style: AppEstilos.textoCuerpo,
                      ),
                      Text(
                        estadoDeConect,
                        style: AppEstilos.textoCuerpo.copyWith(
                          color: estadoDeConect == "Conectado"
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 50.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Conecta al AP, envía credenciales y espera transición del ESP32 a LAN
                        Botones(
                          texto: "Enviar Datos",
                          oprimir: () async {
                            setState(() => estadoDeConect = "Conectando...");
                            if (nombreWifi.isNotEmpty) {
                              bool ok = await Wifi.connect(lan: false);
                              if (!ok) {
                                AppPopup.mostrarError(
                                  context,
                                  "Error al conectar, intenta de nuevo",
                                );
                                Wifi.onStatusUpdate?.call("Desconectado"); // Actualizamos el estado a desconectado
                              } else {
                                Wifi.sendValueNet(nombreWifi, contraWifi);
                                AppPopup.mostrarExito(
                                  context,
                                  "Datos enviados correctamente",
                                );
                                // Espera mientras el ESP32 intenta unirse a la red Wi-Fi local
                                await Future.delayed(Duration(seconds: 20)); // Espera para que el ESP32 procese los datos
                                Wifi.connect(lan: true);// Intentamos conectar a la web del robot después de enviar los datos
                                await Future.delayed(Duration(seconds: 10));
                                if (Wifi.isConnected) {
                                  AppPopup.mostrarExito(
                                    context,
                                    "Conectado a la web del robot",
                                  );
                                  Wifi.onStatusUpdate?.call("Conectado");// Actualizamos el estado a conectado
                                } else {
                                  AppPopup.mostrarError(
                                    context,
                                    "No se pudo conectar a la web del robot, intenta de nuevo",
                                  );
                                  Wifi.onStatusUpdate?.call("Desconectado"); // Actualizamos el estado a desconectado
                                }
                              }
                            } else {
                              AppPopup.mostrarError(
                                context,
                                "Por favor, ingresa el nombre de la red Wifi y la contraseña",
                              );
                            }
                          },
                        ),
                        // Intenta enlazar directamente por LAN (útil si el ESP32 ya está en la red)
                        Botones(
                          texto: "Conectar con web del robot",
                          oprimir: () async {
                            setState(() => estadoDeConect = "Conectando...");
                            bool ok = await Wifi.connect(lan: true);
                            if (!ok) {
                              AppPopup.mostrarError(
                                context,
                                "Error al conectar, intenta de nuevo",
                              );
                              Wifi.onStatusUpdate?.call("Desconectado"); // Actualizamos el estado a desconectado
                            } else {
                              AppPopup.mostrarExito(
                                context,
                                "Conectado a la web del robot",
                              );
                              Wifi.onStatusUpdate?.call("Conectado");// Actualizamos el estado a conectado
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
