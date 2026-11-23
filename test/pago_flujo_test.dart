import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sedyjo_app/app/datos.dart';
import 'package:sedyjo_app/app/tema.dart';
import 'package:sedyjo_app/pago/configuracion_pago.dart';
import 'package:sedyjo_app/pago/flujo_pago.dart';
import 'package:sedyjo_app/pago/modelos_pago.dart';
import 'package:sedyjo_app/pago/pago.dart';
import 'package:sedyjo_app/pago/pasarela_pago.dart';
import 'package:sedyjo_app/pago/pasarela_webpay.dart';
import 'package:sedyjo_app/pantallas/pago_resultado.dart' show ResultadoPagoPantalla;
import 'package:sedyjo_app/ui/componentes.dart';

const _solicitud = SolicitudPago(
  lineas: {1: 2},
  totalVisto: 12990,
  nombre: 'Ana Pérez',
  correo: 'ana@correo.cl',
  telefono: '+56911112222',
  retiro: false,
  direccion: 'Los Aromos 1234, Concepción',
  franja: 'Cualquier horario',
  notas: 'Dejar con el conserje',
);

final _redireccion = Redireccion(
  url: Uri.parse('https://webpay3gint.transbank.cl/webpayserver/initTransaction'),
  token: 'tok-123',
  urlFin: Uri.parse('https://api.sedyjo.cl/api/v1/pagos/webpay/fin'),
);

const _aprobado = ResultadoPago.aprobado(numero: 'SED-10482', total: 12990, correo: 'ana@correo.cl');

/// Pasarela de mentira: lanza los errores pedidos en los primeros `iniciar`, luego inicia
/// el pedido SED-10482; `resultado` responde lo pedido y cuenta las consultas.
class FakePasarela implements PasarelaPago {
  FakePasarela({
    this.errores = const [],
    this.respuesta = _aprobado,
    this.conRedireccion = true,
    this.puerta,
    this.falla,
    this.fallaEn = 1,
  });

  final List<ErrorPago> errores;

  /// Lo que responde `resultado`; se puede cambiar a mitad de una prueba («Revisar de nuevo»).
  ResultadoPago respuesta;
  final bool conRedireccion;

  /// Si existe, `iniciar` espera a que se complete (para probar el doble toque).
  final Completer<void>? puerta;

  /// Si existe, el `iniciar` número [fallaEn] lanza esto: un error inesperado, no un [ErrorPago].
  final Object? falla;
  final int fallaEn;

  final List<SolicitudPago> iniciadas = [];
  final List<RetornoPago> retornos = [];
  int get consultas => retornos.length;

  @override
  Future<InicioPago> iniciar(SolicitudPago solicitud) async {
    iniciadas.add(solicitud);
    if (puerta != null) await puerta!.future;
    if (falla != null && iniciadas.length == fallaEn) throw falla!;
    if (iniciadas.length <= errores.length) throw errores[iniciadas.length - 1];
    return InicioPago(
      PagoPendiente(numero: 'SED-10482', token: 'tok-123', total: solicitud.totalVisto, solicitud: solicitud, creado: DateTime.now()),
      redireccion: conRedireccion ? _redireccion : null,
    );
  }

  @override
  Future<ResultadoPago> resultado(PagoPendiente pendiente, RetornoPago retorno) async {
    retornos.add(retorno);
    return respuesta;
  }
}

/// Almacenamiento del dispositivo (de mentira), vacío al empezar cada prueba.
late SharedPreferences _almacen;

/// `abrirWebpay` de mentira: devuelve [retorno] y anota cada llamada (y qué había guardado en ese momento).
class FakeWebpay {
  FakeWebpay([this.retorno = RetornoPago.completado]);
  final RetornoPago retorno;
  int llamadas = 0;
  String? pendienteAlAbrir;
  String? guardadoAlAbrir;

  Future<RetornoPago> call(BuildContext context, Redireccion r) async {
    // Se lee sin esperar nada antes: si el guardado no terminó al abrir Webpay, aquí aún no está.
    llamadas++;
    pendienteAlAbrir = estado.pagoPendiente?.numero;
    guardadoAlAbrir = _almacen.getString('estado_v1');
    return retorno;
  }
}

/// Cuenta las rutas que se empujan, para saber si el flujo navegó o no.
class _Observador extends NavigatorObserver {
  int empujes = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => empujes++;
}

/// «Pagar» hace lo del checkout; «Reanudar» lo que hace el `Shell` al abrir la app.
Widget _app(FlujoPago flujo, {SolicitudPago solicitud = _solicitud, NavigatorObserver? observador}) => MaterialApp(
      theme: construirTema(),
      navigatorObservers: [?observador],
      home: Scaffold(
        body: Builder(
          builder: (ctx) => Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              ElevatedButton(onPressed: () => flujo.pagar(ctx, solicitud), child: const Text('Pagar')),
              ElevatedButton(onPressed: () => flujo.reanudarSiHay(ctx), child: const Text('Reanudar')),
            ]),
          ),
        ),
      ),
    );

/// Un pendiente como el que deja `pagar` antes de abrir Webpay, creado en [creado] (por defecto, ahora).
PagoPendiente _pendiente({DateTime? creado}) =>
    PagoPendiente(numero: 'SED-10482', token: 'tok-123', total: 12990, solicitud: _solicitud, creado: creado ?? DateTime.now());

/// Toca «Reanudar» y deja correr la pantalla de resultado hasta que muestra el mensaje final.
Future<void> reanudarYEsperar(WidgetTester t) async {
  await t.tap(find.text('Reanudar'));
  await esperar(t, 4500);
}

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

/// Toca «Pagar» y deja correr la pantalla de resultado hasta que muestra el mensaje final.
Future<void> pagarYEsperar(WidgetTester t) async {
  await t.tap(find.text('Pagar'));
  await esperar(t, 4500);
}

void main() {
  late List<Pedido> pedidosIniciales;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Catalogo.cargar();
  });

  setUp(() async {
    // Cada prueba parte con el almacenamiento vacío: lo que guardó una prueba anterior no cuenta para la siguiente.
    SharedPreferences.setMockInitialValues({});
    _almacen = await SharedPreferences.getInstance();
    pedidosIniciales = List.of(estado.pedidos);
    estado.carrito
      ..clear()
      ..addAll({1: 2, 2: 1});
  });

  tearDown(() {
    estado.carrito.clear();
    estado.limpiarPagoPendiente();
    estado.pedidos
      ..clear()
      ..addAll(pedidosIniciales);
  });

  testWidgets('1. aprobado: pedido con el número del servidor y las líneas pagadas; el carrito conserva lo demás', (t) async {
    telefono(t);
    final pasarela = FakePasarela();
    final webpay = FakeWebpay();
    await t.pumpWidget(_app(FlujoPago(pasarela: pasarela, abrirWebpay: webpay.call)));

    await pagarYEsperar(t);

    expect(webpay.llamadas, 1);
    expect(estado.pedidos.first.numero, 'SED-10482');
    expect(estado.pedidos.first.lineas, {1: 2});
    expect(estado.pedidos.first.correo, 'ana@correo.cl');
    expect(estado.pedidos.first.direccion, 'Los Aromos 1234, Concepción');
    expect(estado.pedidos.first.franja, 'Cualquier horario');
    expect(estado.pedidos.first.notas, 'Dejar con el conserje');
    expect(estado.pedidos.where((p) => p.numero == 'SED-10482'), hasLength(1));
    expect(estado.carrito, {2: 1});
    expect(estado.pagoPendiente, isNull);
    expect(find.text('Seguir mi pedido'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('2. rechazado: no hay pedido nuevo, el carrito queda intacto y no queda pendiente', (t) async {
    telefono(t);
    final antes = estado.pedidos.length;
    await t.pumpWidget(_app(FlujoPago(pasarela: FakePasarela(respuesta: const ResultadoPago.rechazado()), abrirWebpay: FakeWebpay().call)));

    await pagarYEsperar(t);

    expect(estado.pedidos, hasLength(antes));
    expect(estado.carrito, {1: 2, 2: 1});
    expect(estado.pagoPendiente, isNull);
    expect(find.text('El pago no se completó'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('3. cancelado: con Webpay cerrado igual se consulta a la pasarela, y se avisa que canceló', (t) async {
    telefono(t);
    final antes = estado.pedidos.length;
    final pasarela = FakePasarela(respuesta: const ResultadoPago.cancelado());
    await t.pumpWidget(_app(FlujoPago(pasarela: pasarela, abrirWebpay: FakeWebpay(RetornoPago.cerrado).call)));

    await pagarYEsperar(t);

    expect(pasarela.consultas, 1, reason: 'el servidor decide aunque el cliente haya cerrado la página');
    expect(pasarela.retornos.single, RetornoPago.cerrado);
    expect(find.text('Cancelaste el pago'), findsOneWidget);
    expect(estado.pedidos, hasLength(antes));
    expect(estado.carrito, {1: 2, 2: 1});
    expect(estado.pagoPendiente, isNull);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('4. sin confirmar: el pendiente se conserva y el carrito queda intacto', (t) async {
    telefono(t);
    final antes = estado.pedidos.length;
    await t.pumpWidget(_app(FlujoPago(pasarela: FakePasarela(respuesta: const ResultadoPago.sinConfirmar()), abrirWebpay: FakeWebpay().call)));

    await pagarYEsperar(t);

    expect(estado.pagoPendiente, isNotNull);
    expect(estado.pagoPendiente!.numero, 'SED-10482');
    expect(estado.carrito, {1: 2, 2: 1});
    expect(estado.pedidos, hasLength(antes));
    expect(find.text('Estamos confirmando tu pago'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('5. error al iniciar: diálogo con el mensaje, nada guardado y Webpay no se abre', (t) async {
    telefono(t);
    final webpay = FakeWebpay();
    final pasarela = FakePasarela(errores: const [ErrorPago('servidor', 'No pudimos…')]);
    await t.pumpWidget(_app(FlujoPago(pasarela: pasarela, abrirWebpay: webpay.call)));

    await t.tap(find.text('Pagar'));
    await esperar(t, 1000);

    expect(find.text('No pudimos iniciar el pago'), findsOneWidget);
    expect(find.text('No pudimos…'), findsOneWidget);
    expect(estado.pagoPendiente, isNull);
    expect(webpay.llamadas, 0);
    expect(pasarela.consultas, 0);

    await t.tap(find.widgetWithText(Boton, 'Entendido'));
    await esperar(t, 1000);
    expect(find.text('No pudimos iniciar el pago'), findsNothing);
    expect(estado.carrito, {1: 2, 2: 1});
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('6a. cambiaron los precios: «Continuar» reintenta una vez con el total nuevo', (t) async {
    telefono(t);
    final webpay = FakeWebpay();
    final pasarela = FakePasarela(errores: const [ErrorPago('precios_cambiaron', 'Los precios cambiaron.', totalNuevo: 12500)]);
    await t.pumpWidget(_app(FlujoPago(pasarela: pasarela, abrirWebpay: webpay.call)));

    await t.tap(find.text('Pagar'));
    await esperar(t, 1000);

    expect(find.text('Cambió el total'), findsOneWidget);
    expect(find.textContaining('\$12.500'), findsOneWidget);
    expect(pasarela.iniciadas, hasLength(1));

    await t.tap(find.widgetWithText(Boton, 'Continuar'));
    await esperar(t, 4500);

    expect(pasarela.iniciadas, hasLength(2));
    expect(pasarela.iniciadas[1].totalVisto, 12500);
    expect(pasarela.iniciadas[1].lineas, {1: 2});
    expect(webpay.llamadas, 1);
    expect(find.text('Seguir mi pedido'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('6b. cambiaron los precios: «Volver al carrito» no reintenta ni deja nada pendiente', (t) async {
    telefono(t);
    final webpay = FakeWebpay();
    final pasarela = FakePasarela(errores: const [ErrorPago('precios_cambiaron', 'Los precios cambiaron.', totalNuevo: 12500)]);
    await t.pumpWidget(_app(FlujoPago(pasarela: pasarela, abrirWebpay: webpay.call)));

    await t.tap(find.text('Pagar'));
    await esperar(t, 1000);
    await t.tap(find.widgetWithText(Boton, 'Volver al carrito'));
    await esperar(t, 1000);

    expect(pasarela.iniciadas, hasLength(1));
    expect(estado.pagoPendiente, isNull);
    expect(webpay.llamadas, 0);
    expect(find.text('Cambió el total'), findsNothing);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('7. el pendiente se guarda (también en el dispositivo) antes de abrir Webpay', (t) async {
    telefono(t);
    final webpay = FakeWebpay();
    await t.pumpWidget(_app(FlujoPago(pasarela: FakePasarela(), abrirWebpay: webpay.call)));
    expect(_almacen.getString('estado_v1'), isNull, reason: 'el dispositivo parte sin nada guardado');

    await pagarYEsperar(t);

    expect(webpay.llamadas, 1);
    expect(webpay.pendienteAlAbrir, 'SED-10482');
    expect(webpay.guardadoAlAbrir, contains('SED-10482'), reason: 'Memoria.guardarYa() terminó antes de salir a Webpay');
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('8. con un pendiente guardado, pagar no inicia otro: lo retoma consultando a la pasarela', (t) async {
    telefono(t);
    estado.guardarPagoPendiente(PagoPendiente(numero: 'SED-10482', token: 'tok-123', total: 12990, solicitud: _solicitud, creado: DateTime.now()));
    final webpay = FakeWebpay();
    final pasarela = FakePasarela();
    await t.pumpWidget(_app(FlujoPago(pasarela: pasarela, abrirWebpay: webpay.call)));

    await pagarYEsperar(t);

    expect(pasarela.iniciadas, isEmpty);
    expect(webpay.llamadas, 0);
    expect(pasarela.consultas, 1);
    expect(pasarela.retornos.single, RetornoPago.desconocido);
    expect(estado.pedidos.first.numero, 'SED-10482');
    expect(estado.pagoPendiente, isNull);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('9. pasarela simulada (sin redirección): no se abre Webpay y el pedido se registra', (t) async {
    telefono(t);
    final webpay = FakeWebpay();
    final numero = estado.siguienteNumeroPedido;
    await t.pumpWidget(_app(FlujoPago(pasarela: PasarelaSimulada(espera: Duration.zero), abrirWebpay: webpay.call)));

    await pagarYEsperar(t);

    expect(webpay.llamadas, 0);
    expect(estado.pedidos.first.numero, numero);
    expect(estado.pedidos.first.lineas, {1: 2});
    expect(estado.carrito, {2: 1});
    expect(estado.pagoPendiente, isNull);
    expect(find.text('Seguir mi pedido'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('10. doble toque: dos pagar casi simultáneos inician un solo pago', (t) async {
    telefono(t);
    final puerta = Completer<void>();
    final pasarela = FakePasarela(puerta: puerta);
    final webpay = FakeWebpay();
    await t.pumpWidget(_app(FlujoPago(pasarela: pasarela, abrirWebpay: webpay.call)));

    await t.tap(find.text('Pagar'));
    await t.tap(find.text('Pagar'));
    await t.pump();
    puerta.complete();
    await esperar(t, 4500);

    expect(pasarela.iniciadas, hasLength(1));
    expect(webpay.llamadas, 1);
    expect(estado.pedidos.where((p) => p.numero == 'SED-10482'), hasLength(1));
    await t.pumpWidget(const SizedBox());
  });

  // ── Reanudar un pago pendiente al abrir la app (lo que llama el Shell) ──

  testWidgets('11. reanudar: pendiente guardado y la pasarela responde aprobado → pedido con las líneas guardadas', (t) async {
    telefono(t);
    estado.guardarPagoPendiente(_pendiente());
    final pasarela = FakePasarela();
    final webpay = FakeWebpay();
    await t.pumpWidget(_app(FlujoPago(pasarela: pasarela, abrirWebpay: webpay.call)));

    await reanudarYEsperar(t);

    expect(pasarela.iniciadas, isEmpty);
    expect(webpay.llamadas, 0);
    expect(pasarela.retornos, [RetornoPago.desconocido]);
    expect(estado.pedidos.first.numero, 'SED-10482');
    expect(estado.pedidos.first.lineas, {1: 2});
    expect(estado.pedidos.first.correo, 'ana@correo.cl');
    expect(estado.pedidos.where((p) => p.numero == 'SED-10482'), hasLength(1));
    expect(estado.carrito, {2: 1});
    expect(estado.pagoPendiente, isNull);
    expect(find.text('Seguir mi pedido'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('12. reanudar: el pedido ya estaba registrado (la app murió antes de limpiar) → no se duplica', (t) async {
    telefono(t);
    // El pago se aprobó y el pedido quedó registrado (y el carrito descontado), pero el pendiente no alcanzó a borrarse.
    estado.registrarPedido(numero: 'SED-10482', lineas: {1: 2}, correo: 'ana@correo.cl', direccion: 'Los Aromos 1234, Concepción');
    estado.guardarPagoPendiente(_pendiente());
    final antes = estado.pedidos.length;
    final pasarela = FakePasarela();
    await t.pumpWidget(_app(FlujoPago(pasarela: pasarela, abrirWebpay: FakeWebpay().call)));

    await reanudarYEsperar(t);

    expect(pasarela.consultas, 1);
    expect(estado.pedidos, hasLength(antes));
    expect(estado.pedidos.where((p) => p.numero == 'SED-10482'), hasLength(1));
    expect(estado.carrito, {2: 1}, reason: 'el carrito no se descuenta dos veces');
    expect(estado.pagoPendiente, isNull);
    expect(find.text('Seguir mi pedido'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('13. reanudar: pendiente de hace 25 h → se limpia sin consultar ni navegar', (t) async {
    telefono(t);
    estado.guardarPagoPendiente(_pendiente(creado: DateTime.now().subtract(const Duration(hours: 25))));
    final antes = estado.pedidos.length;
    final pasarela = FakePasarela();
    final observador = _Observador();
    await t.pumpWidget(_app(FlujoPago(pasarela: pasarela, abrirWebpay: FakeWebpay().call), observador: observador));
    final empujesIniciales = observador.empujes;

    await reanudarYEsperar(t);

    expect(pasarela.consultas, 0);
    expect(estado.pagoPendiente, isNull);
    expect(observador.empujes, empujesIniciales, reason: 'no se empujó ninguna ruta');
    expect(find.byType(ResultadoPagoPantalla, skipOffstage: false), findsNothing);
    expect(estado.pedidos, hasLength(antes));
    expect(estado.carrito, {1: 2, 2: 1});
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('14. reanudar: sin pendiente no se consulta ni se empuja ninguna ruta', (t) async {
    telefono(t);
    final pasarela = FakePasarela();
    final observador = _Observador();
    await t.pumpWidget(_app(FlujoPago(pasarela: pasarela, abrirWebpay: FakeWebpay().call), observador: observador));
    final empujesIniciales = observador.empujes;

    await reanudarYEsperar(t);

    expect(pasarela.consultas, 0);
    expect(observador.empujes, empujesIniciales);
    expect(find.byType(ResultadoPagoPantalla, skipOffstage: false), findsNothing);
    expect(estado.pagoPendiente, isNull);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('15a. reanudar: sin confirmar y «Revisar de nuevo» → se consulta otra vez y, si ya está aprobado, se ve el pedido', (t) async {
    telefono(t);
    estado.guardarPagoPendiente(_pendiente());
    final pasarela = FakePasarela(respuesta: const ResultadoPago.sinConfirmar());
    await t.pumpWidget(_app(FlujoPago(pasarela: pasarela, abrirWebpay: FakeWebpay().call)));

    await reanudarYEsperar(t);

    expect(find.text('Estamos confirmando tu pago'), findsOneWidget);
    expect(estado.pagoPendiente, isNotNull, reason: 'sin confirmar conserva el pendiente');
    expect(pasarela.consultas, 1);

    pasarela.respuesta = _aprobado;
    await t.tap(find.widgetWithText(Boton, 'Revisar de nuevo'));
    await esperar(t, 4500);

    expect(pasarela.retornos, [RetornoPago.desconocido, RetornoPago.desconocido]);
    expect(find.text('Seguir mi pedido'), findsOneWidget);
    expect(find.byType(ResultadoPagoPantalla, skipOffstage: false), findsOneWidget, reason: 'la pantalla anterior se cerró');
    expect(estado.pedidos.where((p) => p.numero == 'SED-10482'), hasLength(1));
    expect(estado.pagoPendiente, isNull);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('15b. pagar: sin confirmar y «Revisar de nuevo» → se consulta otra vez y, si ya está aprobado, se ve el pedido', (t) async {
    telefono(t);
    final pasarela = FakePasarela(respuesta: const ResultadoPago.sinConfirmar());
    final webpay = FakeWebpay();
    await t.pumpWidget(_app(FlujoPago(pasarela: pasarela, abrirWebpay: webpay.call)));

    await pagarYEsperar(t);

    expect(find.text('Estamos confirmando tu pago'), findsOneWidget);
    expect(estado.pagoPendiente, isNotNull);

    pasarela.respuesta = _aprobado;
    await t.tap(find.widgetWithText(Boton, 'Revisar de nuevo'));
    await esperar(t, 4500);

    expect(pasarela.iniciadas, hasLength(1));
    expect(webpay.llamadas, 1);
    expect(pasarela.retornos, [RetornoPago.completado, RetornoPago.desconocido]);
    expect(find.text('Seguir mi pedido'), findsOneWidget);
    expect(find.byType(ResultadoPagoPantalla, skipOffstage: false), findsOneWidget, reason: 'la pantalla anterior se cerró');
    expect(estado.pedidos.where((p) => p.numero == 'SED-10482'), hasLength(1));
    expect(estado.carrito, {2: 1});
    expect(estado.pagoPendiente, isNull);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('16. reanudar dos veces casi a la vez: una sola consulta y una sola pantalla', (t) async {
    telefono(t);
    estado.guardarPagoPendiente(_pendiente());
    final pasarela = FakePasarela();
    final observador = _Observador();
    final flujo = FlujoPago(pasarela: pasarela, abrirWebpay: FakeWebpay().call);
    await t.pumpWidget(_app(flujo, observador: observador));
    final empujesIniciales = observador.empujes;

    // Directo y no con dos toques: tras el primer push el Navigator absorbe los toques durante la transición.
    final ctx = t.element(find.text('Reanudar'));
    unawaited(flujo.reanudarSiHay(ctx));
    unawaited(flujo.reanudarSiHay(ctx));
    await esperar(t, 4500);

    expect(pasarela.consultas, 1);
    expect(observador.empujes, empujesIniciales + 1);
    expect(estado.pedidos.where((p) => p.numero == 'SED-10482'), hasLength(1));
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('17. reanudar mientras un pago está en Webpay: se ignora y el pago termina normal', (t) async {
    telefono(t);
    final enWebpay = Completer<RetornoPago>();
    final pasarela = FakePasarela();
    final observador = _Observador();
    await t.pumpWidget(_app(FlujoPago(pasarela: pasarela, abrirWebpay: (_, _) => enWebpay.future), observador: observador));
    final empujesIniciales = observador.empujes;

    await t.tap(find.text('Pagar'));
    await esperar(t, 500);
    expect(estado.pagoPendiente, isNotNull, reason: 'el pendiente ya está guardado mientras el cliente está en Webpay');

    await t.tap(find.text('Reanudar'));
    await esperar(t, 500);
    expect(pasarela.consultas, 0, reason: 'el Shell no debe retomar un pago que sigue en curso');
    expect(observador.empujes, empujesIniciales);

    enWebpay.complete(RetornoPago.completado);
    await esperar(t, 4500);

    expect(pasarela.retornos, [RetornoPago.completado]);
    expect(observador.empujes, empujesIniciales + 1);
    expect(find.text('Seguir mi pedido'), findsOneWidget);
    expect(estado.pedidos.where((p) => p.numero == 'SED-10482'), hasLength(1));
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('18. un error inesperado al iniciar: hoja de error sin lanzar, nada guardado, y el siguiente pagar funciona', (t) async {
    telefono(t);
    final webpay = FakeWebpay();
    final pasarela = FakePasarela(falla: StateError('se cayó algo'));
    final flujo = FlujoPago(pasarela: pasarela, abrirWebpay: webpay.call);
    await t.pumpWidget(_app(flujo));

    Object? error;
    var termino = false;
    unawaited(flujo.pagar(t.element(find.text('Pagar')), _solicitud).then((_) => termino = true, onError: (Object e) {
      error = e;
    }));
    await esperar(t, 1000);

    expect(error, isNull, reason: 'el error no se escapa del flujo');
    expect(find.text('No pudimos iniciar el pago'), findsOneWidget);
    expect(find.text('No pudimos iniciar el pago. No se cobró nada. Inténtalo de nuevo en un momento.'), findsOneWidget);
    expect(estado.pagoPendiente, isNull);
    expect(webpay.llamadas, 0);

    await t.tap(find.widgetWithText(Boton, 'Entendido'));
    await esperar(t, 1000);
    expect(termino, isTrue);
    expect(error, isNull);

    await pagarYEsperar(t);

    expect(pasarela.iniciadas, hasLength(2));
    expect(pasarela.consultas, 1);
    expect(webpay.llamadas, 1);
    expect(find.text('Seguir mi pedido'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('18b. un error inesperado en el reintento con el total nuevo: hoja de error sin lanzar ni guardar nada', (t) async {
    telefono(t);
    final webpay = FakeWebpay();
    final pasarela = FakePasarela(
      errores: const [ErrorPago('precios_cambiaron', 'Los precios cambiaron.', totalNuevo: 12500)],
      falla: StateError('se cayó algo'),
      fallaEn: 2,
    );
    final flujo = FlujoPago(pasarela: pasarela, abrirWebpay: webpay.call);
    await t.pumpWidget(_app(flujo));

    Object? error;
    unawaited(flujo.pagar(t.element(find.text('Pagar')), _solicitud).catchError((Object e) {
      error = e;
    }));
    await esperar(t, 1000);
    await t.tap(find.widgetWithText(Boton, 'Continuar'));
    await esperar(t, 1000);

    expect(pasarela.iniciadas, hasLength(2));
    expect(error, isNull);
    expect(find.text('No pudimos iniciar el pago'), findsOneWidget);
    expect(find.text('No pudimos iniciar el pago. No se cobró nada. Inténtalo de nuevo en un momento.'), findsOneWidget);
    expect(estado.pagoPendiente, isNull);
    expect(webpay.llamadas, 0);

    await t.tap(find.widgetWithText(Boton, 'Entendido'));
    await esperar(t, 1000);
    expect(error, isNull);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('19. pendiente vencido (25 h) y «Pagar»: se olvida y en el mismo toque se inicia un pago nuevo', (t) async {
    telefono(t);
    estado.guardarPagoPendiente(_pendiente(creado: DateTime.now().subtract(const Duration(hours: 25))));
    final pasarela = FakePasarela();
    final webpay = FakeWebpay();
    await t.pumpWidget(_app(FlujoPago(pasarela: pasarela, abrirWebpay: webpay.call)));

    await pagarYEsperar(t);

    expect(pasarela.iniciadas, hasLength(1));
    expect(webpay.llamadas, 1);
    expect(webpay.pendienteAlAbrir, 'SED-10482');
    expect(pasarela.retornos, [RetornoPago.completado], reason: 'solo la consulta del pago nuevo');
    expect(find.text('Seguir mi pedido'), findsOneWidget);
    expect(estado.pagoPendiente, isNull);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('20. reanudar → sin confirmar → atrás → «Pagar» vuelve a consultar (reanudarSiHay soltó la guarda)', (t) async {
    telefono(t);
    estado.guardarPagoPendiente(_pendiente());
    final pasarela = FakePasarela(respuesta: const ResultadoPago.sinConfirmar());
    final webpay = FakeWebpay();
    await t.pumpWidget(_app(FlujoPago(pasarela: pasarela, abrirWebpay: webpay.call)));

    await reanudarYEsperar(t);
    expect(find.text('Estamos confirmando tu pago'), findsOneWidget);
    expect(pasarela.consultas, 1);

    await t.binding.handlePopRoute(); // «atrás» del sistema
    await esperar(t, 1000);
    expect(find.byType(ResultadoPagoPantalla, skipOffstage: false), findsNothing);
    expect(estado.pagoPendiente, isNotNull, reason: 'sin confirmar conserva el pendiente');

    await pagarYEsperar(t);

    expect(pasarela.consultas, 2, reason: 'el segundo toque no quedó bloqueado por la guarda');
    expect(pasarela.retornos, [RetornoPago.desconocido, RetornoPago.desconocido]);
    expect(pasarela.iniciadas, isEmpty, reason: 'con un pendiente vigente se retoma, no se inicia otro');
    expect(webpay.llamadas, 0);
    expect(find.text('Estamos confirmando tu pago'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  test('crearPasarela: simulado, Webpay con API y Webpay sin API', () {
    expect(crearPasarela(const ConfiguracionPago(modo: ModoPago.simulado, apiUrl: '')), isA<PasarelaSimulada>());
    expect(crearPasarela(const ConfiguracionPago(modo: ModoPago.webpay, apiUrl: 'https://api.sedyjo.cl/api/v1')), isA<PasarelaWebpay>());
    expect(crearPasarela(const ConfiguracionPago(modo: ModoPago.webpay, apiUrl: '')), isA<PasarelaNoDisponible>());
  });
}
