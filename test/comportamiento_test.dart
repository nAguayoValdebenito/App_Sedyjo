import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sedyjo_app/app/datos.dart';
import 'package:sedyjo_app/app/tema.dart';
import 'package:sedyjo_app/pantallas/bienvenida.dart';
import 'package:sedyjo_app/pantallas/checkout.dart';
import 'package:sedyjo_app/pantallas/direccion.dart';
import 'package:sedyjo_app/ui/banners.dart';
import 'package:sedyjo_app/pantallas/shell.dart';
import 'package:sedyjo_app/ui/componentes.dart';

/// Dos cuadros: el primero arma el widget y el segundo deja correr la animación de entrada o salida.
Future<void> avanzar(WidgetTester t) async {
  await t.pump();
  await t.pump(const Duration(milliseconds: 700));
}

Widget app(Widget home) => MaterialApp(theme: construirTema(), home: home);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Catalogo.cargar();
  });

  setUp(() {
    estado.cerrarSesion();
    estado.primeraVez = true;
    estado.saludoPendiente = false;
    estado.relampagoSilenciadoHoy = false;
    estado.consejoInicioVisto = true;
    estado.cargarCarritoDeEjemplo();
    estado.irAPestana(0);
    relampago.value = null;
  });

  testWidgets('bienvenida: primera vez, regreso y regreso con sesión', (t) async {
    t.view.physicalSize = const Size(400, 840);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);

    await t.pumpWidget(app(const BienvenidaPantalla()));
    expect(find.text('Te damos la bienvenida a la aplicación'), findsOneWidget);
    expect(find.text('Comprar sin crear cuenta'), findsOneWidget);

    estado.primeraVez = false;
    estado.refrescar();
    await t.pump();
    expect(find.text('¡Qué bueno verte de nuevo!'), findsOneWidget);
    expect(find.text('Seguir comprando'), findsOneWidget);

    estado.iniciarSesion();
    await t.pump();
    expect(find.text('Hola de nuevo, María'), findsOneWidget);
    expect(find.text('Entrar a la tienda'), findsOneWidget);
  });

  test('al iniciar sesión por primera vez el saludo es de bienvenida; después, de regreso', () {
    estado.primeraVez = true;
    estado.iniciarSesion();
    expect(estado.saludoPendiente, isTrue);
    expect(estado.saludoEsPrimera, isTrue);
    estado.cerrarSesion();
    estado.iniciarSesion();
    expect(estado.saludoEsPrimera, isFalse);
  });

  test('quitar con deshacer: el producto vuelve con su cantidad', () {
    final p = Catalogo.porId(4);
    estado.carrito[4] = 3;
    estado.cambiarCantidad(p, 0);
    expect(estado.carrito.containsKey(4), isFalse);
    estado.agregar(p, 3);
    expect(estado.carrito[4], 3);
  });

  testWidgets('carrito: el "−" se detiene en 1 (no elimina por accidente)', (t) async {
    var valor = 1;
    await t.pumpWidget(app(Scaffold(
      body: StatefulBuilder(builder: (c, set) => Cantidad(valor: valor, minimo: 1, cambia: (v) => set(() => valor = v))),
    )));
    await t.tap(find.byIcon(LucideIcons.minus), warnIfMissed: false);
    await t.pump();
    expect(valor, 1);
  });

  testWidgets('aviso relámpago: no se muestra en Carrito ni Cuenta, sí en Inicio, y no se va solo', (t) async {
    t.view.physicalSize = const Size(400, 840);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    estado.irAPestana(3);
    await t.pumpWidget(app(const Shell()));
    mostrarRelampago();
    await avanzar(t);
    expect(find.text('OFERTA RELÁMPAGO'), findsNothing);

    estado.irAPestana(0);
    await avanzar(t);
    expect(find.text('OFERTA RELÁMPAGO'), findsOneWidget);

    await t.pump(const Duration(seconds: 15)); // más que los 14 s de antes (y menos que el próximo aviso)
    expect(find.text('OFERTA RELÁMPAGO'), findsOneWidget);

    await t.tap(find.byIcon(LucideIcons.x), warnIfMissed: false);
    await avanzar(t);
    expect(find.text('OFERTA RELÁMPAGO'), findsNothing);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('"No mostrar más hoy" silencia los próximos avisos', (t) async {
    t.view.physicalSize = const Size(400, 840);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(app(const Shell()));
    mostrarRelampago();
    await avanzar(t);
    await t.tap(find.text('No mostrar más hoy'), warnIfMissed: true);
    await avanzar(t);
    expect(estado.relampagoSilenciadoHoy, isTrue);
    mostrarRelampago();
    await avanzar(t);
    expect(find.text('OFERTA RELÁMPAGO'), findsNothing);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('pago: si faltan datos aparece el resumen arriba', (t) async {
    t.view.physicalSize = const Size(400, 840);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(app(const CheckoutPantalla()));
    await t.tap(find.text('Continuar'), warnIfMissed: false);
    await avanzar(t);
    expect(find.textContaining('Faltan'), findsOneWidget);
    expect(find.text('Tu nombre y apellido'), findsOneWidget);
  });

  testWidgets('semántica: el botón no se repite y el precio dice cuál es el anterior', (t) async {
    final h = t.ensureSemantics();
    await t.pumpWidget(app(Scaffold(body: Column(children: [
      Boton('Agregar', onTap: () {}),
      PrecioProducto(Catalogo.porId(4)),
    ]))));
    expect(find.bySemanticsLabel('Agregar'), findsOneWidget);
    expect(find.bySemanticsLabel('743 pesos, antes 990 pesos'), findsOneWidget);
    h.dispose();
  });

  testWidgets('pago: no existe el retiro en tienda y la dirección tiene su propia vista', (t) async {
    t.view.physicalSize = const Size(400, 840);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(app(const CheckoutPantalla()));
    await avanzar(t);
    // Hay retiro en tienda: el pago ofrece elegir entre despacho y retiro.
    await t.scrollUntilVisible(find.text('Retiro en tienda'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('Retiro en tienda'), findsOneWidget);
    await t.scrollUntilVisible(find.text('Agregar dirección de entrega'), 200, scrollable: find.byType(Scrollable).first);
    await t.ensureVisible(find.text('Agregar dirección de entrega'));
    await avanzar(t);
    await t.tap(find.text('Agregar dirección de entrega'), warnIfMissed: false);
    await avanzar(t);
    expect(find.text('Usar esta dirección'), findsOneWidget);
  });

  testWidgets('fuera de zona: "Elegir otra dirección" abre la vista de dirección', (t) async {
    t.view.physicalSize = const Size(400, 840);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(app(const FueraDeZonaPantalla()));
    await avanzar(t);
    expect(find.text('Retirar en nuestra tienda'), findsOneWidget, reason: 'fuera de zona se ofrece retirar en la tienda');
    await t.tap(find.text('Elegir otra dirección'), warnIfMissed: false);
    await avanzar(t);
    expect(find.byType(ElegirDireccionPantalla), findsOneWidget);
    expect(find.text('Usar esta dirección'), findsOneWidget);
  });
}
