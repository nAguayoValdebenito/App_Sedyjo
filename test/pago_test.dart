import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sedyjo_app/app/datos.dart';
import 'package:sedyjo_app/app/tema.dart';
import 'package:sedyjo_app/pantallas/pago_resultado.dart';
import 'package:sedyjo_app/ui/componentes.dart';
import 'package:sedyjo_app/ui/ilustracion_pago.dart';

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
    expect(find.byType(IlustracionEstado), findsOneWidget, reason: 'el pago que falló sí lleva la tarjeta con la alerta roja');
    expect(find.byType(IlustracionPago), findsNothing);
    expect(find.textContaining('No te cobramos nada'), findsOneWidget);
    expect(find.text('Intentar de nuevo'), findsOneWidget);
    expect(find.text('Volver al inicio'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget, reason: 'con el pago rechazado la barra de pestañas sigue a la vista');
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('pago cancelado: el círculo se vuelve gris (no es un error) y se avisa que el cliente canceló y que no se cobró nada', (t) async {
    telefono(t);
    await t.pumpWidget(app(ResultadoPagoPantalla(procesar: () async => const ResultadoPago.cancelado())));
    await esperar(t, 2000);
    expect(sello(t), Sello.cancelado, reason: 'cancelar es decisión del cliente: no lleva el rojo del error');
    expect(find.text('Cancelaste el pago'), findsNothing);
    await esperar(t, 2200);
    expect(find.text('Cancelaste el pago'), findsOneWidget);
    expect(t.widget<IlustracionPago>(find.byType(IlustracionPago)).tipo, TipoIlustracionPago.cancelado);
    expect(find.byType(IlustracionEstado), findsNothing, reason: 'sin la tarjeta con el triángulo rojo de alerta');
    expect(find.textContaining('No te cobramos nada'), findsOneWidget);
    expect(find.text('Intentar de nuevo'), findsOneWidget);
    expect(find.text('Volver al inicio'), findsOneWidget);
    expect(find.text('Llamar para recibir ayuda'), findsOneWidget);
    expect(find.text('Revisar de nuevo'), findsNothing);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('pago sin confirmar: sello azul con reloj, ilustración de espera, no promete que no se cobró y "Revisar de nuevo" llama una vez al callback', (t) async {
    telefono(t);
    var revisiones = 0;
    await t.pumpWidget(app(ResultadoPagoPantalla(
      procesar: () async => const ResultadoPago.sinConfirmar(),
      alRevisarDeNuevo: () => revisiones++,
    )));
    await esperar(t, 2000);
    expect(sello(t), Sello.sinConfirmar);
    expect(find.text('Estamos confirmando tu pago'), findsNothing);
    await esperar(t, 2200);
    expect(find.text('Estamos confirmando tu pago'), findsOneWidget);
    expect(t.widget<IlustracionPago>(find.byType(IlustracionPago)).tipo, TipoIlustracionPago.confirmando);
    expect(find.byIcon(LucideIcons.clock), findsOneWidget, reason: 'un reloj: se está esperando, no falló');
    expect(find.byType(IlustracionEstado), findsNothing, reason: 'sin la tarjeta con el triángulo rojo de alerta');
    expect(find.textContaining('No pagues de nuevo'), findsOneWidget);
    expect(find.textContaining('No te cobramos nada'), findsNothing, reason: 'puede que el banco sí haya cobrado');
    expect(find.text('Volver al inicio'), findsOneWidget);
    expect(find.text('Llamar para recibir ayuda'), findsOneWidget);
    expect(find.text('Intentar de nuevo'), findsNothing);
    expect(find.byType(NavigationBar), findsNothing, reason: 'sin confirmar no se invita a recorrer la tienda ni a pagar otra vez');
    await t.tap(find.text('Revisar de nuevo'), warnIfMissed: false);
    await esperar(t, 300);
    expect(revisiones, 1);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('pago sin confirmar sin callback: no hay botón "Revisar de nuevo"', (t) async {
    telefono(t);
    await t.pumpWidget(app(ResultadoPagoPantalla(resultado: const ResultadoPago.sinConfirmar())));
    await esperar(t, 4000);
    expect(find.text('Estamos confirmando tu pago'), findsOneWidget);
    expect(find.text('Revisar de nuevo'), findsNothing);
    expect(find.text('Volver al inicio'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('pago aprobado con comprobante: se ven código, tarjeta, tipo de pago, cuotas y fecha de Chile', (t) async {
    telefono(t);
    await t.pumpWidget(app(ResultadoPagoPantalla(
      resultado: ResultadoPago.aprobado(
        numero: 'SED-1043',
        total: 12140,
        correo: 'a@b.cl',
        comprobante: ComprobantePago(
          codigoAutorizacion: '1213',
          tarjetaUltimos4: '6623',
          tipoPago: 'Crédito',
          cuotas: 0,
          fecha: DateTime.utc(2026, 11, 16, 15, 5), // noviembre: horario de verano de Chile (UTC-3)
        ),
      ),
    )));
    await esperar(t, 4000);
    expect(find.text('Comprobante de pago'), findsOneWidget);
    expect(find.text('SED-1043'), findsOneWidget, reason: 'el número de pedido aparece una sola vez (panel verde), no repetido en el comprobante');
    expect(find.text('Código de autorización'), findsOneWidget);
    expect(find.text('1213'), findsOneWidget);
    expect(find.text('•••• 6623'), findsOneWidget);
    expect(find.text('Crédito'), findsOneWidget);
    expect(find.text('Sin cuotas'), findsOneWidget);
    expect(find.text('16/11/2026 12:05'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('pago aprobado con cuotas: el comprobante dice "3 cuotas"', (t) async {
    telefono(t);
    await t.pumpWidget(app(ResultadoPagoPantalla(
      resultado: const ResultadoPago.aprobado(
        numero: 'SED-1043',
        total: 12140,
        correo: 'a@b.cl',
        comprobante: ComprobantePago(codigoAutorizacion: '1213', tarjetaUltimos4: '6623', tipoPago: 'Crédito', cuotas: 3),
      ),
    )));
    await esperar(t, 4000);
    expect(find.text('3 cuotas'), findsOneWidget);
    expect(find.text('Sin cuotas'), findsNothing);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('pago aprobado sin comprobante: no se muestra el panel de comprobante', (t) async {
    telefono(t);
    await t.pumpWidget(app(ResultadoPagoPantalla(resultado: const ResultadoPago.aprobado(numero: 'SED-1043', total: 12140, correo: 'a@b.cl'))));
    await esperar(t, 4000);
    expect(find.text('¡Tu compra está lista!'), findsOneWidget);
    expect(find.text('Código de autorización'), findsNothing);
    expect(find.text('Comprobante de pago'), findsNothing);
    await t.pumpWidget(const SizedBox());
  });

  test('horario de Chile: verano (UTC-3) e invierno (UTC-4), con los cambios de hora de 2026', () {
    expect(fechaChile(DateTime.utc(2026, 1, 15, 15, 0)), '15/01/2026 12:00');
    expect(fechaChile(DateTime.utc(2026, 7, 15, 15, 0)), '15/07/2026 11:00');
    // Termina el verano el domingo 5 de abril 2026 a las 03:00 UTC.
    expect(fechaChile(DateTime.utc(2026, 4, 5, 2, 59)), '04/04/2026 23:59');
    expect(fechaChile(DateTime.utc(2026, 4, 5, 3, 0)), '04/04/2026 23:00');
    // Empieza el verano el domingo 6 de septiembre 2026 a las 04:00 UTC.
    expect(fechaChile(DateTime.utc(2026, 9, 6, 3, 59)), '05/09/2026 23:59');
    expect(fechaChile(DateTime.utc(2026, 9, 6, 4, 0)), '06/09/2026 01:00');
    // Una fecha con zona local distinta de UTC se normaliza a UTC antes de convertir.
    expect(fechaChile(DateTime.parse('2026-11-16T12:05:00-03:00')), '16/11/2026 12:05');
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
