import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedyjo_app/app/datos.dart';
import 'package:sedyjo_app/app/tema.dart';
import 'package:sedyjo_app/pantallas/auth.dart';
import 'package:sedyjo_app/pantallas/avisos.dart';
import 'package:sedyjo_app/pantallas/ayuda.dart';
import 'package:sedyjo_app/pantallas/bienvenida.dart';
import 'package:sedyjo_app/pantallas/categorias.dart';
import 'package:sedyjo_app/pantallas/direccion.dart';
import 'package:sedyjo_app/pantallas/checkout.dart';
import 'package:sedyjo_app/pantallas/cuenta.dart';
import 'package:sedyjo_app/pantallas/pedidos.dart';
import 'package:sedyjo_app/pantallas/producto.dart';
import 'package:sedyjo_app/pantallas/shell.dart';
import 'package:sedyjo_app/pantallas/splash.dart';
import 'package:sedyjo_app/ui/banners.dart';

/// Humo visual: cada pantalla debe armarse sin excepciones ni desbordes, también con letra grande.
void capturar() {
  FlutterError.onError = (d) {
    final lineas = const LineSplitter().convert(d.toString());
    // ignore: avoid_print
    print(
      'DETALLE: ${lineas.where((l) => l.contains('app_flutter/lib') || l.contains('overflowed')).take(6).join(' | ')}',
    );
  };
}

void verificar(WidgetTester tester) {
  final e = tester.takeException();
  if (e != null) {
    final det = FlutterErrorDetails(exception: e);
    // ignore: avoid_print
    print('ERROR: ${det.exceptionAsString()}');
  }
  expect(e, isNull);
}

void probarPantallas({required bool oscuro, bool incluirSplash = false, List<double> escalas = const [1.0, 1.3, 1.6]}) {
  TestWidgetsFlutterBinding.ensureInitialized();
  final previo = FlutterError.onError;
  FlutterError.onError = (d) {
    // ignore: avoid_print
    final lineas = const LineSplitter().convert(d.toString());
    print(
      'DETALLE: ${lineas.where((l) => l.contains('app_flutter/lib') || l.contains('overflowed')).take(6).join(' | ')}',
    );
    previo?.call(d);
  };

  setUpAll(() async {
    // Nota: en pruebas el texto usa la fuente de prueba (Ahem), más ancha que la real: es una cota conservadora.
    await Catalogo.cargar();
    estado.iniciarSesion();
    estado.cargarCarritoDeEjemplo();
  });

  final pantallas = <String, Widget Function()>{
    'bienvenida': () => const BienvenidaPantalla(),
    'shell': () => const Shell(),
    'categoria': () => const CategoriaPantalla('Bebidas'),
    'catalogo': () => const CategoriaPantalla(null),
    'buscar': () => const BuscarPantalla(),
    'producto': () => ProductoPantalla(Catalogo.porId(4)),
    'ficha_foto_uso': () => ProductoPantalla(Catalogo.porId(2)),
    'agotado': () => ProductoPantalla(Catalogo.porId(28)),
    'sin_conexion': () => const SinConexionPantalla(),
    'sesion_expirada': () => const SesionExpiradaPantalla(),
    'fuera_de_zona': () => const FueraDeZonaPantalla(),
    'elegir_direccion': () => const ElegirDireccionPantalla(),
    'despachos': () => ContenidoPantalla.despachos(),
    'cambios': () => ContenidoPantalla.cambios(),
    'privacidad': () => ContenidoPantalla.privacidad(),
    'checkout': () => const CheckoutPantalla(),
    'exito': () =>
        const ExitoPantalla(numero: 'SED-1043', total: 3966, correo: 'a@b.cl'),
    'error': () => const ErrorPagoPantalla(),
    'ingresar': () => const IngresarPantalla(),
    'registro': () => const RegistroPantalla(),
    'recuperar': () => const RecuperarPantalla(),
    'pedidos': () => const PedidosPantalla(),
    'detalle': () => DetallePedidoPantalla(estado.pedidos.first),
    'seguimiento': () => const SeguimientoPantalla(),
    'direcciones': () => const DireccionesPantalla(),
    'perfil': () => const PerfilPantalla(),
    'avisos': () => const AvisosPantalla(),
    'ayuda': () => const AyudaPantalla(),
  };

  for (final escala in escalas) {
    for (final e in pantallas.entries) {
      testWidgets('${e.key} @ ${escala}x ${oscuro ? 'oscuro' : 'claro'}', (
        tester,
      ) async {
        C.oscuro = oscuro;
        addTearDown(() => C.oscuro = false);
        capturar();
        tester.view.physicalSize = const Size(400, 840);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            theme: construirTema(),
            builder: (c, w) => MediaQuery(
              data: MediaQuery.of(c)
                  .copyWith(textScaler: TextScaler.linear(escala)),
              child: w!,
            ),
            home: e.value(),
          ),
        );
        await tester.pump(const Duration(milliseconds: 600));
        verificar(tester);
      });
    }

    for (var i = 0; i < 5; i++) {
      testWidgets('pestana $i @ ${escala}x ${oscuro ? 'oscuro' : 'claro'}', (
        tester,
      ) async {
        C.oscuro = oscuro;
        addTearDown(() => C.oscuro = false);
        capturar();
        tester.view.physicalSize = const Size(400, 840);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        estado.irAPestana(i);
        await tester.pumpWidget(
          MaterialApp(
            theme: construirTema(),
            builder: (c, w) => MediaQuery(
              data: MediaQuery.of(c)
                  .copyWith(textScaler: TextScaler.linear(escala)),
              child: w!,
            ),
            home: const Shell(),
          ),
        );
        await tester.pump(const Duration(milliseconds: 600));
        verificar(tester);
        // Limpia temporizadores de la pantalla.
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  if (incluirSplash) {
    testWidgets('splash', (tester) async {
      tester.view.physicalSize = const Size(400, 840);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: construirTema(),
          home: SplashPantalla(alTerminar: () {}),
        ),
      );
      for (var i = 0; i < 9; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        verificar(tester);
      }
    });
  }
}
