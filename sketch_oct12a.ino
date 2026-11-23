#include <WiFi.h>
#include <WebSocketsServer.h>
#include <ArduinoJson.h>
#include <ESP32Servo.h>

// ---------------- CONFIG ----------------
const char* ap_ssid = "ESP32_AP";
const char* ap_password = "12345678";
const uint16_t WS_PORT = 81;

// Pines de los servos (según lo confirmaste)
const int PinMotor1 = 13; // base
const int PinMotor2 = 14; // hombro
const int PinMotor3 = 15; // codo
const int PinMotor4 = 16; // muñeca rotación
const int PinMotor5 = 17; // muñeca flexión
const int PinMotor6 = 18; // garra

// Rango esperado por la app: -135 .. +135 (para servos 270°)
const int ANG_MIN = -135;
const int ANG_MAX = 135;

// Pulsos microsegundos (ajusta si tu servo requiere otras marcas)
const int PULSE_MIN = 500;   // extremo izquierdo (0.5ms)
const int PULSE_MAX = 2500;  // extremo derecho (2.5ms)

// -----------------------------------------

WebSocketsServer webSocket(WS_PORT);

Servo servo1, servo2, servo3, servo4, servo5, servo6;
bool wifiConnectedAsSTA = false;


// ---------------- util: convertir ángulo (-135..135) a microsegundos ----------------
int angleToPulse(int angle) {
  // clamp
  if (angle < ANG_MIN) angle = ANG_MIN;
  if (angle > ANG_MAX) angle = ANG_MAX;
  // map from [-135,135] -> [PULSE_MIN, PULSE_MAX]
  long shifted = (long)angle - (long)ANG_MIN; // 0 .. 270
  long pulse = map(shifted, 0, (ANG_MAX - ANG_MIN), PULSE_MIN, PULSE_MAX);
  return (int)pulse;
}

// wrapper para escribir
void writeServoAngle(Servo &s, int angle) {
  int pulse = angleToPulse(angle);
  s.writeMicroseconds(pulse);
}

// ---------------- WebSocket helpers ----------------
void sendStatusClient(uint8_t numClient, const char* status, const char* extra = nullptr) {
  StaticJsonDocument<200> doc;
  doc["status"] = status;
  if (extra) doc["info"] = extra;
  char buf[256];
  size_t n = serializeJson(doc, buf);
  webSocket.sendTXT(numClient, buf, n);
}

void sendStatusAllClients(const char* status, const char* extra = nullptr) {
  StaticJsonDocument<200> doc;
  doc["status"] = status;
  if (extra) doc["info"] = extra;
  char buf[256];
  size_t n = serializeJson(doc, buf);
  webSocket.broadcastTXT(buf, n);
}

// ---------------- Manejo de eventos WebSocket ----------------
void onWebSocketEvent(uint8_t num, WStype_t type, uint8_t * payload, size_t length) {
  switch (type) {
    case WStype_CONNECTED: {
      IPAddress ip = webSocket.remoteIP(num);
      Serial.printf("Cliente conectado #%u, ip: %s\n", num, ip.toString().c_str());
      // informar al cliente su estado actual
      StaticJsonDocument<200> doc;
      doc["status"] = wifiConnectedAsSTA ? "connected" : "ap_ready";
      doc["ap_ip"] = WiFi.softAPIP().toString();
      if (wifiConnectedAsSTA) doc["sta_ip"] = WiFi.localIP().toString();
      char buf[256];
      serializeJson(doc, buf);
      webSocket.sendTXT(num, buf);
      break;
    }
    case WStype_DISCONNECTED: {
      Serial.printf("Cliente desconectado #%u\n", num);
      break;
    }
    case WStype_TEXT: {
      // Mensaje de texto recibido (esperamos JSON)
      payload[length] = 0; // aseguramos terminación
      String msg = (char*)payload;
      Serial.printf("MSG de cliente #%u: %s\n", num, msg.c_str());

      // Parsear JSON
      StaticJsonDocument<512> doc;
      DeserializationError err = deserializeJson(doc, msg);
      if (err) {
        Serial.print("JSON parse error: ");
        Serial.println(err.c_str());
        sendStatusClient(num, "error", "invalid_json");
        return;
      }

      // Si trae ssid+pass => intentar conectar STA
      if (doc.containsKey("ssid") && doc.containsKey("pass")) {
        const char* ssid = doc["ssid"];
        const char* pass = doc["pass"];
        Serial.println("Solicitud de conexión STA recibida...");
        // Informar cliente que iniciamos conexión
        sendStatusAllClients("connecting");
        // Intentar conectar (modo STA)
        attemptStaConnect(String(ssid), String(pass), num);
        return;
      }

      // Si trae claves de servos, aplicarlas
      bool anyServo = false;
      // Esperamos nombres: base, hombro, codo, muñeca_rot, muñeca_flex, garra
      if (doc.containsKey("base")) {
        int v = doc["base"];
        writeServoAngle(servo1, v);
        anyServo = true;
      }
      if (doc.containsKey("hombro")) {
        int v = doc["hombro"];
        writeServoAngle(servo2, v);
        anyServo = true;
      }
      if (doc.containsKey("codo")) {
        int v = doc["codo"];
        writeServoAngle(servo3, v);
        anyServo = true;
      }
      if (doc.containsKey("muñeca_rot")) {
        int v = doc["muñeca_rot"];
        writeServoAngle(servo4, v);
        anyServo = true;
      }
      if (doc.containsKey("muñeca_flex")) {
        int v = doc["muñeca_flex"];
        writeServoAngle(servo5, v);
        anyServo = true;
      }
      if (doc.containsKey("garra")) {
        int v = doc["garra"];
        writeServoAngle(servo6, v);
        anyServo = true;
      }

      if (anyServo) {
        sendStatusClient(num, "servo_ok");
        Serial.println("Servos actualizados.");
      } else {
        sendStatusClient(num, "unknown_command");
      }

      break;
    }
    default:
      break;
  }
}

// ---------------- Intento de conexión STA (no apaga AP) ----------------
void attemptStaConnect(String ssid, String pass, uint8_t requester) {
  Serial.print("Intentando conectar a STA: ");
  Serial.println(ssid);
  WiFi.begin(ssid.c_str(), pass.c_str());

  sendStatusAllClients("connecting");

  unsigned long start = millis();
  const unsigned long timeout = 20000; // 20s
  while (WiFi.status() != WL_CONNECTED && (millis() - start) < timeout) {
    delay(200);
    // opcional: enviar progreso
  }

  if (WiFi.status() == WL_CONNECTED) {
    wifiConnectedAsSTA = true;
    String ip = WiFi.localIP().toString();
    Serial.println("\n✅ Conectado en STA. IP: " + ip);

    // enviar estado a todos
    StaticJsonDocument<200> okDoc;
    okDoc["status"] = "connected";
    okDoc["ap_ip"] = WiFi.softAPIP().toString();
    okDoc["sta_ip"] = ip;
    char buf[256];
    serializeJson(okDoc, buf);
    webSocket.broadcastTXT(buf);

  } else {
    // fallo, volver a modo AP activo (ya está AP)
    wifiConnectedAsSTA = false;
    Serial.println("\n❌ No se pudo conectar como STA dentro del timeout");
    sendStatusAllClients("error");
    // WiFi.softAP ya estaba activo; dejamos AP para reconexión
  }
}


void setup() {
  Serial.begin(115200);
  delay(100);

  // Iniciar Servos y posiciones iniciales en 0°
  ESP32PWM::allocateTimer(0);
  ESP32PWM::allocateTimer(1);
  ESP32PWM::allocateTimer(2);
  ESP32PWM::allocateTimer(3);

  servo1.attach(PinMotor1);
  servo2.attach(PinMotor2);
  servo3.attach(PinMotor3);
  servo4.attach(PinMotor4);
  servo5.attach(PinMotor5);
  servo6.attach(PinMotor6);

  // Inicializar todos en 0° (ya mecánicamente centrados)
  writeServoAngle(servo1, 0);
  writeServoAngle(servo2, 0);
  writeServoAngle(servo3, 0);
  writeServoAngle(servo4, 0);
  writeServoAngle(servo5, 0);
  writeServoAngle(servo6, 0);

  // Iniciar modo AP (siempre activo)
  WiFi.mode(WIFI_AP_STA); // modo dual desde el inicio (AP + STA)
  WiFi.softAP(ap_ssid, ap_password);
  Serial.println("== ESP32 AP iniciado ==");
  Serial.print("AP IP: ");
  Serial.println(WiFi.softAPIP());

  // Iniciar WebSocket
  webSocket.begin();
  webSocket.onEvent(onWebSocketEvent);
  Serial.printf("WebSocket iniciado en puerto %u\n", WS_PORT);

  // Enviar info inicial por consola
  sendStatusAllClients("ap_ready", WiFi.softAPIP().toString().c_str());
}

void loop() {
  webSocket.loop();
  // Aquí podrías agregar código periódico si necesitas (temperatura, watchdog, etc.)
}


