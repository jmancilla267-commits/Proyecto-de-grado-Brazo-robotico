import 'package:app_proyecto/Pantallas/managerWifi.dart';
import 'package:app_proyecto/colores/Colores_Estilos.dart';
import 'package:app_proyecto/estilo_botones/Botones.dart';
import 'package:app_proyecto/estilo_botones/popup.dart';
import 'package:app_proyecto/estilos_deslizadores/Deslizadores.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    const MaterialApp(
      // <--- EL MATERIAL APP VA AQUÍ
      home: MainApp(),
    ),
  );
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  void initState() {
    super.initState();
    // Intentamos conectar al ESP32 al iniciar la app
    Wifi.intentarConectar();
    Wifi.onMostrarPopup = (mensaje) {
      if (mounted) {
        AppPopup.mostrar(context, mensaje);
      }
    };
    Wifi.onErrorPopup = (mensajeError) {
      if (mounted) {
        AppPopup.mostrarError(context, mensajeError);
      }
    };
  }

  String parte = "";

  int anguloGarra = 0;

  int anguloMu2 = 0;

  int anguloMu1 = 0;

  int anguloCodo = 0;

  int anguloHombro = 0;

  int anguloBase = 0;

  List<Map<int, int>> listaPuntos = [];

  int puntosGuardados = 0;
  void enviarAngulo(int ID, int valor) {
    Wifi.sendValueT(ID, valor);
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColores.primaro,
        title: Text('App contro Brazo', style: AppEstilos.textoTitulo),
        //boton de navegacion hacia el wifi manager
        actions: [
          Builder(
            builder: (context) => Padding(
              padding: const EdgeInsets.only(right: 30),
              child: IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Managerwifi()),
                  );
                },
                icon: Icon(Icons.wifi, color: AppColores.textosColor),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          /* barras dezlisadoras y la imagen*/ Expanded(
            child: Container(
              color: AppColores.secundario,
              child: Row(
                children: [
                  /* Imagen*/ Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8, left: 4),
                    child: Image(
                      image: AssetImage('assets/images/Brazo.png'),
                      fit: BoxFit.contain,
                      height: 450,
                    ),
                  ),
                  /* deslizadores*/ Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Deslizadorlateral(
                          min: 0,
                          max: 90,
                          angulo: anguloGarra.toDouble(),
                          nombreParte: 'Garra',
                          cambioValor: (valor) {
                             setState(() {
                              if ( Wifi.isConnected) {
                                anguloGarra = valor.toInt();
                                enviarAngulo(5, valor.toInt());
                              } else {
                                anguloGarra = 0;
                              }
                            });
                          },
                        ),
                        DeslizadorCentral(
                          min: -90,
                          max: 90,
                          angulo: anguloMu2.toDouble(),
                          nombreParte: 'Muñeca 2',
                          cambioValor: (valor) {
                            setState(() {
                              if (Wifi.isConnected) {
                                anguloMu2 = valor.toInt();
                                enviarAngulo(4, valor.toInt());
                              } else {
                                anguloMu2 = 0;
                              }
                            });
                          },
                        ),
                        DeslizadorCentral(
                          min: -135,
                          max: 135,
                          angulo: anguloMu1.toDouble(),
                          nombreParte: 'Muñeca 1',
                          cambioValor: (valor) {
                            setState(() {
                              if (Wifi.isConnected) {
                                anguloMu1 = valor.toInt();
                                enviarAngulo(3, valor.toInt());
                              } else {
                                anguloMu1 = 0;
                              }
                            });
                          },
                        ),
                        DeslizadorCentral(
                          min: -135,
                          max: 135,
                          angulo: anguloCodo.toDouble(),
                          nombreParte: 'Codo',
                          cambioValor: (valor) {
                            setState(() {
                              if (Wifi.isConnected) {
                                anguloCodo = valor.toInt();
                                enviarAngulo(2, valor.toInt());
                              } else {
                                anguloCodo = 0;
                              }
                            });
                          },
                        ),
                        DeslizadorCentral(
                          min: -135,
                          max: 135,
                          angulo: anguloHombro.toDouble(),
                          nombreParte: 'Hombro',
                          cambioValor: (valor) {
                            setState(() {
                              if (Wifi.isConnected) {
                                anguloHombro = valor.toInt();
                                enviarAngulo(1, valor.toInt());
                              } else {
                                anguloHombro = 0;
                              }
                            });
                          },
                        ),
                        DeslizadorCentral(
                          min: -135,
                          max: 135,
                          angulo: anguloBase.toDouble(),
                          nombreParte: 'Base',
                          cambioValor: (valor) {
                            setState(() {
                              if (Wifi.isConnected) {
                                anguloBase = valor.toInt();
                                enviarAngulo(0, valor.toInt());
                              } else {
                                anguloBase = 0;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          /*botones */ Container(
            color: AppColores.secundario,
            height: 100,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    top: 4.0,
                    left: 4,
                    right: 4,
                    bottom: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Botones(
                        oprimir: () {
                          setState(() {
                            puntosGuardados++;
                            listaPuntos.add({
                              0: anguloBase.toInt(),
                              1: anguloHombro.toInt(),
                              2: anguloCodo.toInt(),
                              3: anguloMu1.toInt(),
                              4: anguloMu2.toInt(),
                              5: anguloGarra.toInt(),
                            });
                            print(listaPuntos);
                          });
                          AppPopup.mostrar(
                            context,
                            "Punto guardado exitosamente",
                          );
                        },
                        texto: 'Guardar Punto',
                      ),
                      Botones(
                        oprimir: () {
                          setState(() {
                            puntosGuardados = 0;
                            listaPuntos.clear();
                          });
                          AppPopup.mostrar(
                            context,
                            "Puntos eliminados exitosamente",
                          );
                        },
                        texto: 'Eliminar',
                      ),
                      Botones(
                        oprimir: () async {
                          for (int i = 0; i < listaPuntos.length; i++) {
                            enviarAngulo(0, listaPuntos[i][0]!);
                            enviarAngulo(1, listaPuntos[i][1]!);
                            enviarAngulo(2, listaPuntos[i][2]!);
                            enviarAngulo(3, listaPuntos[i][3]!);
                            enviarAngulo(4, listaPuntos[i][4]!);
                            enviarAngulo(5, listaPuntos[i][5]!);

                            AppPopup.mostrar(
                              context,
                              "Reproduciendo punto ${i + 1} de ${listaPuntos.length}",
                            );
                            setState(() {
                              anguloBase = listaPuntos[i][0]!;
                              anguloHombro = listaPuntos[i][1]!;
                              anguloCodo = listaPuntos[i][2]!;
                              anguloMu1 = listaPuntos[i][3]!;
                              anguloMu2 = listaPuntos[i][4]!;
                              anguloGarra = listaPuntos[i][5]!;
                            });
                            // ⏳ Espera antes de mandar la siguiente posición
                            await Future.delayed(Duration(milliseconds: 10000));
                          }
                        },
                        texto: 'Reproducir',
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Puntos guardados: $puntosGuardados',
                    style: AppEstilos.textoCuerpo,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
