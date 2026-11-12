import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sedyjo_app/app/datos.dart';
import 'package:sedyjo_app/app/tema.dart';
import 'package:sedyjo_app/pantallas/producto.dart';
import 'package:sedyjo_app/pantallas/shell.dart';
import 'package:sedyjo_app/ui/componentes.dart';

Widget app(Widget home) => MaterialApp(theme: construirTema(), home: home);

void telefono(WidgetTester t) {
  t.view.physicalSize = const Size(400, 840);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

/// Deja correr el vuelo (560 ms) y luego el abanico (480 ms) hasta el final.
Future<void> terminar(WidgetTester t) async {
  await t.pump(const Duration(milliseconds: 700));
  await t.pump();
  await t.pump(const Duration(milliseconds: 700));
  await t.pump();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Catalogo.cargar();
  });

  setUp(() {
    estado.cerrarSesion();
    estado.relampagoSilenciadoHoy = true;
    estado.reducirMovimiento = false;
    estado.cargarCarritoDeEjemplo();
    estado.irAPestana(2); // Ofertas: el botón dorado "Aprovechar oferta" está a la vista
    relampago.value = null;
  });

  testWidgets('la burbuja sale del botón, aterriza en el carrito y no deja capas colgadas', (t) async {
    telefono(t);
    await t.pumpWidget(app(const Shell()));
    await t.pump(const Duration(milliseconds: 400));
    final antes = estado.cantidadCarrito;
    final llegadas = llegadasCarrito.value;

    // Sale desde el centro del botón que se tocó.
    final boton = t.getCenter(find.widgetWithText(Boton, 'Aprovechar oferta'));
    await t.tap(find.text('Aprovechar oferta'), warnIfMissed: false);
    await t.pump();
    expect(estado.cantidadCarrito, antes + 1);
    expect(find.byType(BurbujaVuelo), findsOneWidget);
    final burbuja = t.widget<BurbujaVuelo>(find.byType(BurbujaVuelo));
    expect((burbuja.inicio - boton).distance, lessThan(2), reason: 'parte del botón tocado');
    expect(burbuja.oscuro, isTrue, reason: 'el botón dorado vive sobre fondo negro');

    // Aterriza en el ícono del carrito de la barra inferior.
    final carrito = t.getCenter(find.byKey(claveCarrito));
    expect((burbuja.fin - carrito).distance, lessThan(2));

    await t.pump(const Duration(milliseconds: 300));
    expect(find.byType(BurbujaVuelo), findsOneWidget, reason: 'sigue en el aire a mitad de camino');
    expect(llegadasCarrito.value, llegadas);

    await t.pump(const Duration(milliseconds: 400)); // 560 ms de vuelo
    await t.pump();
    expect(llegadasCarrito.value, llegadas + 1, reason: 'al llegar se dispara el pulso del carrito');
    await terminar(t); // abanico (480 ms)
    expect(find.byType(BurbujaVuelo), findsNothing);
    expect(entradasDeVueloActivas, 0, reason: 'no debe quedar ningún OverlayEntry colgado');
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('tocar muchas veces seguidas lanza una burbuja por toque sin bloquear las anteriores', (t) async {
    telefono(t);
    await t.pumpWidget(app(const Shell()));
    await t.pump(const Duration(milliseconds: 400));
    for (var i = 0; i < 3; i++) {
      await t.tap(find.text('Aprovechar oferta'), warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 60));
    }
    expect(find.byType(BurbujaVuelo), findsNWidgets(3));
    await terminar(t);
    expect(find.byType(BurbujaVuelo), findsNothing);
    expect(entradasDeVueloActivas, 0);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('en la ficha (que tapa la barra) la burbuja aterriza en el carrito pequeño de la ficha', (t) async {
    telefono(t);
    estado.irAPestana(0);
    await t.pumpWidget(app(const Shell()));
    await t.pump(const Duration(milliseconds: 400));
    final ctx = t.element(find.byType(Shell));
    Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => ProductoPantalla(Catalogo.porId(7))));
    await t.pump();
    await t.pump(const Duration(milliseconds: 800));

    final llegadas = llegadasCarrito.value;
    await t.tap(find.textContaining('Agregar ·'), warnIfMissed: false);
    await t.pump();
    final burbuja = t.widget<BurbujaVuelo>(find.byType(BurbujaVuelo));
    final carritoFicha = t.getCenter(find.byType(IconoCarritoAnimado).last);
    expect((burbuja.fin - carritoFicha).distance, lessThan(2), reason: 'aterriza en el carrito de la ficha');
    await terminar(t);
    expect(llegadasCarrito.value, llegadas + 1);
    expect(entradasDeVueloActivas, 0);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('el "+" del selector de cantidad también lanza la burbuja; el de una ficha, no', (t) async {
    telefono(t);
    await t.pumpWidget(app(Scaffold(
      body: Column(children: [
        Cantidad(valor: 1, vuela: true, cambia: (_) {}),
        Cantidad(valor: 1, cambia: (_) {}),
      ]),
    )));
    final mas = find.byIcon(LucideIcons.plus);
    await t.tap(mas.at(1), warnIfMissed: false);
    await t.pump();
    expect(find.byType(BurbujaVuelo), findsNothing, reason: 'el selector de una ficha todavía no agrega al carrito');
    await t.tap(mas.at(0), warnIfMissed: false);
    await t.pump();
    expect(find.byType(BurbujaVuelo), findsOneWidget);
    await terminar(t);
    expect(entradasDeVueloActivas, 0);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('el vuelo se muestra aunque "reducir movimiento" esté activo', (t) async {
    telefono(t);
    estado.reducirMovimiento = true;
    addTearDown(() => estado.reducirMovimiento = false);
    await t.pumpWidget(app(const Shell()));
    await t.pump(const Duration(milliseconds: 400));
    await t.tap(find.text('Aprovechar oferta'), warnIfMissed: false);
    await t.pump(const Duration(milliseconds: 100));
    expect(find.byType(BurbujaVuelo), findsOneWidget);
    await terminar(t);
    expect(entradasDeVueloActivas, 0);
    await t.pumpWidget(const SizedBox());
  });
}
