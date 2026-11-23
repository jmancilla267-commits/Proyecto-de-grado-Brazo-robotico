# Brazo Robótico Educativo con Control IoT para Orientación Vocacional STEM

Prototipo de brazo robótico articulado de 5 grados de libertad más efector final (6 actuadores), fabricado mediante impresión 3D (FDM) en PLA y controlado inalámbricamente mediante IoT. Desarrollado como proyecto de grado en la **Universidad Autónoma de Bucaramanga (UNAB)**.

---

## Descripción General

El sistema ofrece una herramienta tecno-pedagógica de bajo costo diseñada para educación secundaria, permitiendo la manipulación remota en tiempo real desde dispositivos móviles. Cuenta con dos modos de operación:
1. **Control directo por ángulos:** Manipulación independiente de cada articulación mediante deslizadores.
2. **Reproducción secuencial:** Almacenamiento de posiciones articulares y ejecución automática en bucle.

---

## Arquitectura y Componentes

* **Microcontrolador:** ESP32 (programado en Arduino IDE).
* **Controlador PWM:** Módulo PCA9685 de 16 canales (comunicación I2C, frecuencia 50 Hz) con filtrado capacitivo de 4700 µF.
* **Actuadores:** 6 servomotores (Base, Hombro, Codo, Muñeca 1, Muñeca 2 y Garra).
* **Alimentación:** Fuente conmutada MEAN WELL LRS-100-5 (5 V / 18 A).
* **Estructura mecánica:** Piezas impresas en PLA (FDM) con efector final tipo *gripper* basado en un mecanismo de cuatro barras.
* **Interfaz de usuario:** Aplicación móvil multiplataforma desarrollada en Flutter (Dart).
* **Comunicación:** Protocolo WebSocket bidireccional con intercambio de datos en formato JSON (soporte para modos **AP** y **LAN** con resolución **mDNS**)[cite: 1].

---

## Estructura del Repositorio

```text
brazo-robotico-iot-stem/
├── README.md                     # Documentación general del repositorio
├── firmware-esp32/               # Código fuente para el microcontrolador ESP32
│   └── brazo_robotico_esp32/
│       └── brazo_robotico_esp32.ino
├── app-flutter/                  # Aplicación móvil de control en Flutter
│   ├── pubspec.yaml
│   └── lib/
│       ├── main.dart
│       ├── Pantallas/
│       │   └── managerWifi.dart
│       ├── colores/
│       │   └── Colores_Estilos.dart
│       ├── conexiones/
│       │   └── WebSocketManager.dart
│       ├── estilo_botones/
│       │   ├── Botones.dart
│       │   └── popup.dart
│       ├── estilo_textos/
│       │   └── cajaTextos.dart
│       └── estilos_deslizadores/
│           └── Deslizadores.dart
└── simulacion-matlab/            # Modelado cinemático del mecanismo de 4 barras
    └── gripper_cuatro_barras.m
