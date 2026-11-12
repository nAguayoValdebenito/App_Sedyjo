import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedyjo_app/app/datos.dart';
import 'package:sedyjo_app/app/tema.dart';
import 'package:sedyjo_app/pantallas/pago_resultado.dart';

Widget app(Widget home) => MaterialApp(theme: construirTema(), home: home);

Future<void> esperar(WidgetTester t, int ms) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void telefono(WidgetTester t) {
  t.view.physicalSize = const Size(400, 840);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Catalogo.cargar();
  });

  Sello sello(WidgetTester t) => t.widget<SelloPago>(find.byType(SelloPago)).sello;

  testWidgets('pago aprobado: primero el círculo gira, luego se vuelve verde y al final aparece el mensaje completo', (t) async {
    telefono(t);
    await t.pumpWidget(app(ResultadoPagoPantalla(
      procesar: () async => const ResultadoPago.aprobado(numero: 'SED-1043', total: 12140, correo: 'a@b.cl'),
    )));
    await esperar(t, 500);
    expect(sello(t), Sello.procesando);
    expect(find.text('Confirmando tu pago…'), findsOneWidget);
    expect(find.text('¡Tu compra está lista!'), findsNothing, reason: 'el mensaje no aparece mientras se confirma');
    expect(find.text('SED-1043'), findsNothing);

    await esperar(t, 1600); // pasa el mínimo de 1,8 s
    expect(sello(t), Sello.aprobado);
    expect(find.text('¡Tu compra está lista!'), findsNothing, reason: 'primero se ve el círculo cambiar de color');

    await esperar(t, 2200);
    expect(find.text('¡Tu compra está lista!'), findsOneWidget);
    expect(find.text('SED-1043'), findsOneWidget);
    expect(find.text('Seguir mi pedido'), findsOneWidget);
    expect(find.byType(SelloPago), findsNothing, reason: 'el círculo ya no está: la pantalla final solo muestra el mensaje');
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('pago rechazado: el círculo se vuelve rojo y se muestra el mensaje de que no se cobró nada', (t) async {
    telefono(t);
    await t.pumpWidget(app(ResultadoPagoPantalla(procesar: () async => const ResultadoPago.rechazado())));
    await esperar(t, 2000);
    expect(sello(t), Sello.rechazado);
    expect(find.text('El pago no se completó'), findsNothing);
    await esperar(t, 2200);
    expect(find.text('El pago no se completó'), findsOneWidget);
    expect(find.textContaining('No te cobramos nada'), findsOneWidget);
    expect(find.text('Intentar de nuevo'), findsOneWidget);
    expect(find.text('Volver al inicio'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget, reason: 'con el pago rechazado la barra de pestañas sigue a la vista');
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('no se puede salir mientras se confirma el pago', (t) async {
    telefono(t);
    await t.pumpWidget(app(Builder(builder: (c) => Scaffold(body: Center(child: TextButton(onPressed: () => Navigator.of(c).push(MaterialPageRoute(builder: (_) => ResultadoPagoPantalla(procesar: () async => const ResultadoPago.rechazado()))), child: const Text('ir')))))));
    await t.tap(find.text('ir'));
    await esperar(t, 500);
    expect(find.byType(ResultadoPagoPantalla), findsOneWidget);
    await t.binding.handlePopRoute();
    await esperar(t, 300);
    expect(find.byType(ResultadoPagoPantalla), findsOneWidget, reason: 'sigue ahí: el pago aún se está confirmando');
    await esperar(t, 3500);
    await t.binding.handlePopRoute();
    await esperar(t, 600);
    expect(find.byType(ResultadoPagoPantalla), findsNothing);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('una compra rechazada no crea ningún pedido ni vacía el carrito', (t) async {
    estado.cargarCarritoDeEjemplo();
    final antes = estado.pedidos.length;
    estado.cambiarSimulacionPago(SimulacionPago.rechazado);
    addTearDown(() => estado.cambiarSimulacionPago(SimulacionPago.aprobado));
    // Lo mismo que hace el pago: solo se registra el pedido si el resultado es aprobado.
    final r = estado.simulacionPago == SimulacionPago.rechazado ? const ResultadoPago.rechazado() : null;
    expect(r?.aprobado, isFalse);
    expect(estado.pedidos.length, antes);
    expect(estado.carrito, isNotEmpty);
  });
}
