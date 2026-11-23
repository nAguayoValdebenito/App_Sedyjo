import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sedyjo_app/app/datos.dart';
import 'package:sedyjo_app/app/tema.dart';
import 'package:sedyjo_app/pago/flujo_pago.dart';
import 'package:sedyjo_app/pago/modelos_pago.dart';
import 'package:sedyjo_app/pago/pago.dart';
import 'package:sedyjo_app/pago/pasarela_pago.dart';
import 'package:sedyjo_app/pantallas/bienvenida.dart';
import 'package:sedyjo_app/pantallas/pago_resultado.dart';
import 'package:sedyjo_app/pantallas/shell.dart';
import 'package:sedyjo_app/pantallas/splash.dart';

/// Una pasarela que nunca termina de responder: sirve para ver qué pantalla queda abierta al reanudar el pago.
class _PasarelaQueEspera implements PasarelaPago {
  @override
  Future<InicioPago> iniciar(SolicitudPago solicitud) => throw UnimplementedError();

  @override
  Future<ResultadoPago> resultado(PagoPendiente pendiente, RetornoPago retorno) => Completer<ResultadoPago>().future;
}

PagoPendiente _pendiente() => PagoPendiente(
      numero: 'SED-10482',
      token: 'T' * 64,
      total: 743,
      creado: DateTime.now(),
      solicitud: const SolicitudPago(
        lineas: {1: 1},
        totalVisto: 743,
        nombre: 'Maria Prueba',
        correo: 'prueba@correo.cl',
        telefono: '+56912345678',
        retiro: true,
        direccion: 'Av. Collao 2480, Concepción',
      ),
    );

Future<void> pasar(WidgetTester t, int ms) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  final flujoOriginal = flujoPago;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Catalogo.cargar();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    estado.limpiarPagoPendiente();
    flujoPago = FlujoPago(pasarela: _PasarelaQueEspera());
  });

  tearDown(() {
    estado.limpiarPagoPendiente();
    flujoPago = flujoOriginal;
  });

  Widget app() => MaterialApp(
        theme: construirTema(),
        home: SplashPantalla(completa: false, duracion: const Duration(milliseconds: 200), carga: Future<void>.value()),
      );

  testWidgets('sin pago pendiente: tras la carga se ve la bienvenida', (t) async {
    t.view.physicalSize = const Size(400, 840);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(app());
    await pasar(t, 3500);
    expect(find.byType(BienvenidaPantalla), findsOneWidget);
    expect(find.byType(Shell), findsNothing);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('con un pago por confirmar: se entra directo a la tienda y se reanuda, sin pasar por la bienvenida', (t) async {
    t.view.physicalSize = const Size(400, 840);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    estado.guardarPagoPendiente(_pendiente());
    await t.pumpWidget(app());
    await pasar(t, 3500);
    expect(find.byType(BienvenidaPantalla), findsNothing, reason: 'la bienvenida no debe interponerse al pago pendiente');
    expect(find.byType(ResultadoPagoPantalla), findsOneWidget, reason: 'la tienda reanuda el pago al abrirse');
    expect(find.text('Confirmando tu pago…'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });
}
