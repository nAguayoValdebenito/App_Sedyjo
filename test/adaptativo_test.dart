import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedyjo_app/app/datos.dart';
import 'package:sedyjo_app/app/tema.dart';
import 'package:sedyjo_app/pantallas/categorias.dart';
import 'package:sedyjo_app/pantallas/checkout.dart';
import 'package:sedyjo_app/pantallas/producto.dart';
import 'package:sedyjo_app/pantallas/shell.dart';

import 'soporte_pantallas.dart';

/// Tableta vertical, tableta horizontal y teléfono acostado: ninguna pantalla debe desbordarse ni fallar.
const tamanos = {
  'tableta 800x1200': Size(800, 1200),
  'tableta 1280x800': Size(1280, 800),
  'teléfono acostado 850x390': Size(850, 390),
};

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Catalogo.cargar();
    estado.iniciarSesion();
    estado.cargarCarritoDeEjemplo();
    estado.relampagoSilenciadoHoy = true;
  });

  for (final t in tamanos.entries) {
    for (var i = 0; i < 5; i++) {
      testWidgets('pestaña $i en ${t.key}', (tester) async {
        capturar();
        tester.view.physicalSize = t.value;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        estado.irAPestana(i);
        await tester.pumpWidget(MaterialApp(theme: construirTema(), home: const Shell()));
        await tester.pump(const Duration(milliseconds: 700));
        verificar(tester);
        expect(find.byType(NavigationRail), findsOneWidget, reason: 'en pantalla ancha la navegación va al costado');
        await tester.pumpWidget(const SizedBox());
      });
    }

    final pantallas = <String, Widget Function()>{
      'ficha de producto': () => ProductoPantalla(Catalogo.porId(2)),
      'ficha agotada': () => ProductoPantalla(Catalogo.porId(28)),
      'listado': () => const CategoriaPantalla(null),
      'pago': () => const CheckoutPantalla(),
    };
    for (final e in pantallas.entries) {
      testWidgets('${e.key} en ${t.key}', (tester) async {
        capturar();
        tester.view.physicalSize = t.value;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(MaterialApp(theme: construirTema(), home: e.value()));
        await tester.pump(const Duration(milliseconds: 700));
        verificar(tester);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  testWidgets('la ficha usa dos columnas cuando hay ancho', (tester) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: construirTema(), home: ProductoPantalla(Catalogo.porId(4))));
    await tester.pump(const Duration(milliseconds: 700));
    // Foto a la izquierda y detalle a la derecha: el título del producto empieza en la mitad derecha de la pantalla.
    final titulo = tester.getTopLeft(find.text(Catalogo.porId(4).nombre).first);
    expect(titulo.dx, greaterThan(350));
    await tester.pumpWidget(const SizedBox());
  });
}
