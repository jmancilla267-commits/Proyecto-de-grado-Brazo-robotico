import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class ESP32WebSocket {
  final String apUrl = 'ws://192.168.4.1:81';
  final String lanUrl = 'ws://BrazoUnab.local:81';
  Map<String, dynamic> _buffer = {}; // Guarda mensajes pendientes

  WebSocketChannel? _channel;
  bool isConnected = false;

  Function()? onConnect;
  Function()? onDisconnect;
  Function(String msg)? onMessage;
  // Nuevo: callback para notificar cambios de estado
  Function(String)? onStatusUpdate;
  Function(String)? onStatusMensajeUpdate;
  Function(String)? onErrorPopup;
  Function(String)? onMostrarPopup;

  Future<bool> connect({
    bool lan = false,
    int timeoutSec = 4,
    Function()? onConnect,
  }) async {
    final url = lan ? lanUrl : apUrl;
    print('🔌 Intentando conectar a $url...');

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));

      // Timeout seguro
      await Future.any([
        _channel!.ready, // espera conexión
        Future.delayed(Duration(seconds: timeoutSec), () {
          throw TimeoutException('⏳ Tiempo agotado');
        }),
      ]);

      isConnected = true;
      onConnect?.call();

      _channel!.stream.listen(
        (message) {
          onMessage?.call(message); // Callback general
          try {
            final Map<String, dynamic> data = jsonDecode(message);

            // Validamos si la llave existe
            if (data.containsKey("statusMensaje")) {
              String valor = data["statusMensaje"];

              if (valor == "ok") {
                onStatusMensajeUpdate?.call("Mensaje recibido: ok");
              } else {
                // Si el valor es algo distinto a "ok", lo tratamos como error
                onStatusMensajeUpdate?.call("Error: mensaje no reconocido");
              }
            } else if (data.containsKey("status")) {
              String valor = data["status"];

              if (valor == "Conectado") {
                onStatusUpdate?.call("Lan reconocida"); // Actualizamos el estado a LAN
              } else if (valor == "ErrorConexion") {
                // Si el ESP32 nos dice que falló la conexión
                onErrorPopup?.call(
                  "El nombre de la red Wifi y la contraseña no son validos",
                );
                onStatusUpdate?.call("Desconectado");
              }
            }
          } catch (e) {
            // JSON inválido: la estructura no es un objeto JSON o está corrupto
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

  void close() {
    _channel?.sink.close();
  }

  void sendValueT(int Id, dynamic angulo) {
    if (!isConnected || _channel == null) {
      print("⚠️ No conectado, mensaje ignorado");
      return;
    }
    // Preparamos el formato exacto que espera el ESP32
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

  void sendValueNet(String nombreWifi, dynamic contraWifi) {
    // Preparamos el formato exacto que espera el ESP32
    final Map<String, dynamic> payload = {
      "red": nombreWifi,
      "contra": contraWifi,
    };

    // Agregamos al buffer
    _buffer =
        payload; // Usamos '=' para sobrescribir y enviar el último dato del slider

    if (!isConnected) {
      print("⚠️ No conectado, mensaje ignorado");
      return;
    }
    // Enviamos inmediatamente el JSON preparado
    _channel!.sink.add(jsonEncode(_buffer));
    print("📤 Enviado a ESP32: ${jsonEncode(_buffer)}");
  }

  Future<void> intentarConectar() async {
  if (isConnected) return;
  // Intenta primero LAN, si falla, intenta AP
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
