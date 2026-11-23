// ============================================================================
// Proyecto de Grado: Brazo Robótico Educativo con Control IoT (ESP32)
// Propósito: Gestionar conexión Wi-Fi (AP / LAN + mDNS), recibir comandos
//            JSON vía WebSocket y mover 6 servomotores mediante PCA9685
//            con interpolación suave cada 20 ms.
// ============================================================================

#include <WiFi.h>
#include <WebSocketsServer.h>
#include <ArduinoJson.h>
#include <ESPmDNS.h>
#include <Wire.h>
#include <Adafruit_PWMServoDriver.h>

// --- Credenciales por defecto para el modo Access Point (AP) ---
// Permite que el dispositivo cree su propia red si aún no está en una red local.
const char *nombreAP = "RobotUnabArm";
const char *contraseñaAP = "RobotUnab";

// Servidor WebSocket escuchando en el puerto 81
WebSocketsServer webSocket = WebSocketsServer(81);

// Temporizador para verificar periódicamente el estado de conexión Wi-Fi
unsigned long tiempoUltimaVerificacion = 0;
const unsigned long intervaloVerificacion = 30000; // Revisión cada 30 s (en ms)

// Controlador PWM de 16 canales por bus I2C (dirección por defecto 0x40)
Adafruit_PWMServoDriver pwm = Adafruit_PWMServoDriver();

// --- Calibración de pulsos PWM (depende de la frecuencia y del servo) ---
// Ajustar SERVOMIN y SERVOMAX si los extremos físicos no coinciden con el ángulo esperado.
#define SERVOMIN  80   // Valor de pulso mínimo
#define SERVOMAX  500  // Valor de pulso máximo

// --- Estado articular (6 canales: 0..4 articulaciones, 5 garra) ---
int angulosActuales[6] = {45, 45, 45, 45, 45, 45}; // Posición actual interpolada
int objetivos[6]       = {0, 0, 0, 0, 0, 0};       // Ángulo objetivo recibido por JSON
unsigned long ultimaActualizacion = 0;

// ----------------------------------------------------------------------------
// conectaWiFi(ssid, pass)
// Intenta conectar el ESP32 a una red Wi-Fi existente (modo STA/LAN).
// Si tiene éxito, desactiva el AP para liberar recursos y publica "BrazoUnab.local" por mDNS.
// ----------------------------------------------------------------------------
void conectarWiFi(String ssid, String pass) {
  Serial.println("Conectando a: " + ssid);

  if (pass.length() > 0) {
    WiFi.begin(ssid.c_str(), pass.c_str());
  } else {
    WiFi.begin(ssid.c_str()); // Red abierta sin contraseña
  }

  // Espera máxima de 10 segundos (20 intentos x 500 ms)
  int intentos = 0;
  while (WiFi.status() != WL_CONNECTED && intentos < 20) {
    delay(500);
    Serial.print(".");
    intentos++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nConectado! IP: " + WiFi.localIP().toString());

    // Notifica a los clientes WebSocket que la conexión LAN fue exitosa
    String jsonRespuesta = "{\"status\": \"Conectado\"}";
    webSocket.broadcastTXT(jsonRespuesta);
    delay(1000);

    // Pasa a modo estación (STA) para operar en la red local
    WiFi.mode(WIFI_STA);
    Serial.println("Modo AP deshabilitado. Operando solo como Cliente.");

    // Inicia mDNS para resolver el host como "BrazoUnab.local" sin depender de IP fija
    if (!MDNS.begin("BrazoUnab")) {
      Serial.println("Error configurando mDNS");
    } else {
      Serial.println("mDNS iniciado: http://BrazoUnab.local");
    }
  } else {
    // Informa a la app que falló la conexión a la red solicitada
    String jsonRespuesta = "{\"status\": \"ErrorConexion\"}";
    webSocket.broadcastTXT(jsonRespuesta);
  }

  // Reinicia/asegura el servidor WebSocket y su callback de eventos
  webSocket.begin();
  webSocket.onEvent(webSocketEvent);
}

// ----------------------------------------------------------------------------
// webSocketEvent(...)
// Callback ejecutado cuando llega un mensaje o evento desde un cliente WebSocket.
// Soporta dos estructuras JSON:
//   1) {"red": "...", "contra": "..."} -> Configura conexión Wi-Fi LAN.
//   2) {"id": <0..5>, "angulo": <valor>} -> Actualiza ángulo objetivo de un motor.
// ----------------------------------------------------------------------------
void webSocketEvent(uint8_t num, WStype_t type, uint8_t * payload, size_t length) {
  if (type == WStype_TEXT) {
    // Buffer estático de 200 bytes suficiente para tramas cortas de control/red
    StaticJsonDocument<200> doc;
    DeserializationError error = deserializeJson(doc, payload);

    if (error) {
      webSocket.sendTXT(num, "{\"statusMensaje\":\"JSON invalido\"}");
      return;
    }

    // Caso 1: Credenciales de red Wi-Fi enviadas desde el gestor de la app
    if (doc.containsKey("red")) {
      Serial.println("Conectando a la red: " + String(doc["red"].as<String>()) +
                     " con contraseña: " + String(doc["contra"].as<String>()));
      conectarWiFi(doc["red"], doc["contra"]);
      webSocket.sendTXT(num, WiFi.status() == WL_CONNECTED
                             ? "{\"statusMensaje\":\"ok\"}"
                             : "{\"statusMensaje\":\"error\"}");
    }
    // Caso 2: Comando de ángulo para un servomotor específico
    else if (doc.containsKey("id") && doc.containsKey("angulo")) {
      int id     = doc["id"].as<int>();
      int angulo = doc["angulo"].as<int>();

      Serial.println("el Motor ID: " + String(id) + " se tiene que mover hasta: " + String(angulo));
      objetivos[id] = angulo; // El bucle principal acercará angulosActuales[id] a este objetivo
      webSocket.sendTXT(num, "{\"statusMensaje\":\"ok\"}");
    }
  }
}

// ----------------------------------------------------------------------------
// setup()
// Inicializa consola serial, bus I2C (SDA=21, SCL=22), driver PCA9685 a 50 Hz,
// red Wi-Fi en modo AP y servidor WebSocket.
// ----------------------------------------------------------------------------
void setup() {
  Serial.begin(115200);
  delay(1000); // Estabilización del puerto serial al encender

  Wire.begin(21, 22); // Pines I2C estándar en ESP32
  pwm.begin();
  pwm.setPWMFreq(50); // 50 Hz (periodo de 20 ms), estándar para servomotores RC
  delay(1000);

  Serial.println("Todos los servos en posición de reposo (0°)");

  // Modo AP+STA para permitir configuración inicial y transición a red local
  WiFi.mode(WIFI_AP_STA);
  bool success = WiFi.softAP(nombreAP, contraseñaAP);

  webSocket.begin();
  webSocket.onEvent(webSocketEvent);
  Serial.println("Servidor WebSocket iniciado en puerto 81");

  if (success) {
    Serial.println("\n--- SISTEMA INICIADO EN MODO AP ---");
    Serial.print("Nombre de la red (SSID): ");
    Serial.println(nombreAP);
    Serial.print("Direccion IP del Portal: ");
    Serial.println(WiFi.softAPIP()); // Típicamente 192.168.4.1
    Serial.println("El dispositivo ya esta disponible para conexion.");
  } else {
    Serial.println("Error al iniciar el Access Point.");
  }
}

// ----------------------------------------------------------------------------
// loop()
// 1. Atiende eventos WebSocket de forma continua.
// 2. Cada 30 s verifica conexión; si se pierde, reactiva AP de respaldo.
// 3. Cada 20 ms avanza 1° hacia el ángulo objetivo (interpolación escalonada)
//    y envía el pulso correspondiente al PCA9685.
// ----------------------------------------------------------------------------
void loop() {
  webSocket.loop(); // Obligatorio para procesar tramas entrantes/salientes

  // Verificación periódica de conectividad
  if (millis() - tiempoUltimaVerificacion > intervaloVerificacion) {
    tiempoUltimaVerificacion = millis();

    if (WiFi.status() != WL_CONNECTED) {
      Serial.println("Conexión perdida. Activando modo AP de respaldo...");
      WiFi.mode(WIFI_AP_STA);
      WiFi.softAP(nombreAP, contraseñaAP);
    }
  }

  // Control de velocidad e interpolación suave (paso de 1° cada 20 ms)
  if (millis() - ultimaActualizacion > 20) {
    ultimaActualizacion = millis();

    for (int i = 0; i < 6; i++) {
      if (angulosActuales[i] != objetivos[i]) {
        if (angulosActuales[i] < objetivos[i]) {
          angulosActuales[i]++;
        } else {
          angulosActuales[i]--;
        }

        int pulso;
        if (i == 5) {
          // Canal 5 (Garra): restringido estrictamente a 0° - 90° por seguridad mecánica
          int anguloSeguro = constrain(angulosActuales[i], 0, 90);
          pulso = map(anguloSeguro, 0, 90, 360, SERVOMAX);
        } else {
          // Canales 0..4 (articulaciones): rango operativo -135° a 135°
          int anguloSeguro = constrain(angulosActuales[i], -135, 135);
          pulso = map(anguloSeguro, -135, 135, SERVOMIN, SERVOMAX);
        }

        Serial.print("Se esta moviendo ");
        Serial.print(i);
        Serial.print(" hasta ");
        Serial.println(pulso);

        pwm.setPWM(i, 0, pulso); // Inicia el pulso en tick 0 y termina en 'pulso' (0..4095)
      }
    }
  }
}