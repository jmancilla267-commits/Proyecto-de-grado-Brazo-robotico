// ============================================================================
// Módulo: ESP32WebSocket
// Propósito: Administrar la conexión WebSocket con el ESP32 en modo AP
//            (ws://192.168.4.1:81) o modo LAN (ws://BrazoUnab.local:81),
//            enviar comandos de ángulos y credenciales Wi-Fi en JSON, y
//            notificar estados a la interfaz mediante callbacks.
// ============================================================================

import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class ESP32WebSocket {
  final String apUrl  = 'ws://192.168.4.1:81';     // IP por defecto del ESP32 en modo AP
  final String lanUrl = 'ws://BrazoUnab.local:81'; // Host mDNS cuando el ESP32 está en LAN

  Map<String, dynamic> _buffer = {}; // Almacena el último payload de red enviado
  WebSocketChannel? _channel;
  bool isConnected = false;

  // --- Callbacks para comunicar eventos de red hacia las pantallas ---
  Function()? onConnect;
  Function()? onDisconnect;
  Function(String msg)? onMessage;
  Function(String)? onStatusUpdate;        // Actualiza etiqueta de estado (ej. "Conectado")
  Function(String)? onStatusMensajeUpdate; // Estado de confirmación por mensaje ("ok" / error)
  Function(String)? onErrorPopup;          // Muestra SnackBar de error en la UI
  Function(String)? onMostrarPopup;        // Muestra SnackBar informativo en la UI

  /// Abre la conexión WebSocket hacia la red LAN o AP con un tiempo de espera máximo.
  Future<bool> connect({
    bool lan = false,
    int timeoutSec = 4,
    Function()? onConnect,
  }) async {
    final url = lan ? lanUrl : apUrl;
    print('🔌 Intentando conectar a $url...');

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));

      // Espera a que el socket esté listo o lanza TimeoutException si supera timeoutSec
      await Future.any([
        _channel!.ready,
        Future.delayed(Duration(seconds: timeoutSec), () {
          throw TimeoutException('⏳ Tiempo agotado');
        }),
      ]);

      isConnected = true;
      onConnect?.call();

      // Escucha mensajes entrantes desde el ESP32 en formato JSON
      _channel!.stream.listen(
        (message) {
          onMessage?.call(message);
          try {
            final Map<String, dynamic> data = jsonDecode(message);

            if (data.containsKey("statusMensaje")) {
              String valor = data["statusMensaje"];
              if (valor == "ok") {
                onStatusMensajeUpdate?.call("Mensaje recibido: ok");
              } else {
                onStatusMensajeUpdate?.call("Error: mensaje no reconocido");
              }
            } else if (data.containsKey("status")) {
              String valor = data["status"];
              if (valor == "Conectado") {
                onStatusUpdate?.call("Lan reconocida");
              } else if (valor == "ErrorConexion") {
                onErrorPopup?.call(
                  "El nombre de la red Wifi y la contraseña no son validos",
                );
                onStatusUpdate?.call("Desconectado");
              }
            }
          } catch (e) {
            onStatusMensajeUpdate?.call("Error: JSON inválido recibido");
          }
        },
        onDone: () => isConnected = false,
        onError: (e) => isConnected = false,
      );

      return true;
    } catch (e) {
      print("🚫 No se pudo conectar: $e");
      isConnected = false;
      return false;
    }
  }

  /// Cierra el canal WebSocket activo si existe.
  void close() {
    _channel?.sink.close();
  }

  /// Envía el ángulo objetivo de un actuador específico: {"id": Id, "angulo": angulo}.
  void sendValueT(int Id, dynamic angulo) {
    if (!isConnected || _channel == null) {
      print("⚠️ No conectado, mensaje ignorado");
      return;
    }

    final Map<String, dynamic> payload = {
      "id": Id,
      "angulo": angulo,
    };

    try {
      _channel!.sink.add(jsonEncode(payload));
      print("📤 Enviado a ESP32: ${jsonEncode(payload)}");
    } catch (e) {
      print("Error enviando: $e");
      isConnected = false;
    }
  }

  /// Envía credenciales Wi-Fi para que el ESP32 se conecte a la red local: {"red": ..., "contra": ...}.
  void sendValueNet(String nombreWifi, dynamic contraWifi) {
    final Map<String, dynamic> payload = {
      "red": nombreWifi,
      "contra": contraWifi,
    };
    _buffer = payload;

    if (!isConnected) {
      print("⚠️ No conectado, mensaje ignorado");
      return;
    }

    _channel!.sink.add(jsonEncode(_buffer));
    print("📤 Enviado a ESP32: ${jsonEncode(_buffer)}");
  }

  /// Estrategia de conexión automática al iniciar: prueba primero LAN y, si falla, intenta AP.
  Future<void> intentarConectar() async {
    if (isConnected) return;

    bool lanOk = await connect(lan: true);
    if (!lanOk) {
      bool apOk = await connect(lan: false);
      if (!apOk) {
        onErrorPopup?.call("Porfavor conecta el celular a la red Wifi del robot");
      } else {
        onMostrarPopup?.call("Conectado en Modo AP");
      }
    } else {
      onMostrarPopup?.call("Conectado en Modo LAN");
    }
  }
}