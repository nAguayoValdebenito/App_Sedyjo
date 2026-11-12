import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sedyjo_app/app/datos.dart';
import 'package:sedyjo_app/app/tema.dart';
import 'package:sedyjo_app/pantallas/shell.dart';
import 'package:sedyjo_app/pantallas/splash.dart';
import 'package:sedyjo_app/ui/carga.dart';
import 'package:sedyjo_app/ui/componentes.dart';

Widget app(Widget home) => MaterialApp(theme: construirTema(), home: home);

Future<void> avanzar(WidgetTester t, [int ms = 700]) async {
  await t.pump();
  await t.pump(Duration(milliseconds: ms));
}

void telefono(WidgetTester t, [Size tam = const Size(400, 840)]) {
  t.view.physicalSize = tam;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Catalogo.cargar();
  });

  setUp(() {
    estado.cerrarSesion();
    estado.primeraVez = true;
    estado.relampagoSilenciadoHoy = true; // el aviso relámpago no interfiere con estas pruebas
    estado.cambiarSimulacionRed(SimulacionRed.normal);
    estado.cargarCarritoDeEjemplo();
    estado.irAPestana(0);
    Catalogo.forzarVacio = false;
    Catalogo.carga.value = Carga.listo;
    relampago.value = null;
  });

  testWidgets('barra inferior: resalta la pestaña activa y la insignia sigue al carrito', (t) async {
    telefono(t);
    await t.pumpWidget(app(const Shell()));
    await avanzar(t);
    int activa() => t.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;
    expect(activa(), 0);

    await t.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Ofertas')), warnIfMissed: false);
    await avanzar(t);
    expect(activa(), 2, reason: 'el resaltado debe seguir a la pestaña (error de la barra const)');

    final n = estado.cantidadCarrito;
    estado.agregar(Catalogo.porId(7));
    await avanzar(t, 400);
    expect(find.descendant(of: find.byType(IconoCarritoAnimado), matching: find.text('${n + 1}')), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('pantalla ancha: navegación lateral en vez de barra inferior', (t) async {
    telefono(t, const Size(1000, 700));
    await t.pumpWidget(app(const Shell()));
    await avanzar(t);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('tarjeta: "Agregar" se transforma en selector y solo cambia el producto tocado', (t) async {
    telefono(t);
    final p = Catalogo.porId(7);
    estado.carrito.remove(7);
    await t.pumpWidget(app(Scaffold(body: Center(child: SizedBox(width: 200, height: 380, child: TarjetaProducto(p))))));
    await avanzar(t, 300);
    expect(find.text('Agregar'), findsOneWidget);
    expect(find.byIcon(LucideIcons.minus), findsNothing);

    await t.tap(find.text('Agregar'), warnIfMissed: false);
    await avanzar(t, 300);
    expect(estado.carrito[7], 1);
    expect(find.byIcon(LucideIcons.minus), findsOneWidget);
    expect(find.text('Agregar'), findsNothing);

    // Deshacer al quitar: el "−" con 1 unidad lleva a "Quitaste…" y el botón vuelve.
    await t.tap(find.byIcon(LucideIcons.minus), warnIfMissed: false);
    await avanzar(t, 300);
    expect(estado.carrito.containsKey(7), isFalse);
    expect(find.text('Agregar'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('carrito: "Quitar" pliega la línea y deja el aviso con Deshacer', (t) async {
    telefono(t);
    estado.irAPestana(3);
    await t.pumpWidget(app(const Shell()));
    await avanzar(t);
    expect(estado.carrito.containsKey(4), isTrue);
    await t.tap(find.text('Quitar').first, warnIfMissed: false);
    await avanzar(t, 600);
    expect(estado.carrito.containsKey(4), isFalse);
    expect(find.textContaining('Quitaste'), findsOneWidget);
    expect(find.text('Deshacer'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('carga: esqueletos, error de sección con reintento y contenido', (t) async {
    telefono(t);
    Catalogo.forzarVacio = true;
    Catalogo.carga.value = Carga.cargando;
    await t.pumpWidget(app(Scaffold(
      body: SingleChildScrollView(
        child: SeccionCarga(cargando: (_) => const EsqueletoGrilla(n: 2), listo: (_) => const SizedBox(width: double.infinity, child: Text('CONTENIDO'))),
      ),
    )));
    await avanzar(t, 100);
    expect(find.byType(EsqueletoProducto), findsWidgets);
    expect(find.text('CONTENIDO'), findsNothing);

    Catalogo.carga.value = Carga.error;
    await avanzar(t, 300);
    expect(find.text('No pudimos cargar los productos'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);

    Catalogo.forzarVacio = false;
    Catalogo.carga.value = Carga.listo;
    await avanzar(t, 400);
    expect(find.text('CONTENIDO'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  test('actualizar sin red conserva los datos que ya hay', () async {
    estado.cambiarSimulacionRed(SimulacionRed.error);
    final ok = await Catalogo.recargar();
    expect(ok, isFalse);
    expect(Catalogo.productos, isNotEmpty);
    expect(Catalogo.carga.value, Carga.listo);
  });

  testWidgets('pantalla de carga: breve las veces siguientes y espera la carga real', (t) async {
    telefono(t);
    final carga = Completer<void>();
    var termino = false;
    await t.pumpWidget(app(SplashPantalla(completa: false, carga: carga.future, alTerminar: () => termino = true)));
    await t.pump(const Duration(milliseconds: 2000));
    expect(termino, isFalse, reason: 'no avanza mientras la carga real siga en curso');
    carga.complete();
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await t.pump();
    expect(termino, isTrue);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('tocar la pestaña activa devuelve esa pestaña arriba', (t) async {
    telefono(t);
    await t.pumpWidget(app(const Shell()));
    await avanzar(t);
    await t.drag(find.byType(ListView).first, const Offset(0, -900));
    await avanzar(t);
    final lista = t.state<ScrollableState>(find.byType(Scrollable).first);
    expect(lista.position.pixels, greaterThan(300));
    await t.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Inicio')), warnIfMissed: false);
    await avanzar(t, 800);
    expect(t.state<ScrollableState>(find.byType(Scrollable).first).position.pixels, 0);
    await t.pumpWidget(const SizedBox());
  });
}
