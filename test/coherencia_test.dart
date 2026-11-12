import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedyjo_app/app/datos.dart';
import 'package:sedyjo_app/app/tema.dart';
import 'package:sedyjo_app/pantallas/pedidos.dart';
import 'package:sedyjo_app/pantallas/shell.dart';

Widget app(Widget home) => MaterialApp(theme: construirTema(), home: home);

void telefono(WidgetTester t) {
  t.view.physicalSize = const Size(400, 840);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

/// Deja pasar el tiempo en pasos cortos, como en un teléfono (los temporizadores nacen cuando termina cada animación).
Future<void> esperar(WidgetTester t, int milisegundos) async {
  for (var i = 0; i < milisegundos ~/ 100; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Catalogo.cargar();
  });

  setUp(() {
    estado.cerrarSesion();
    estado.relampagoSilenciadoHoy = true;
    estado.cargarCarritoDeEjemplo();
    estado.irAPestana(0);
  });

  tearDown(() {
    // Los pedidos hechos durante la prueba no deben filtrarse a las demás.
    estado.pedidos.removeWhere((p) => p.creado != null);
  });

  testWidgets('el aviso "Quitaste… Deshacer" se va solo a los pocos segundos', (t) async {
    telefono(t);
    estado.irAPestana(3);
    await t.pumpWidget(app(const Shell()));
    await t.pump(const Duration(milliseconds: 600));
    await t.tap(find.text('Quitar').first, warnIfMissed: false);
    await esperar(t, 800);
    expect(find.textContaining('Quitaste'), findsOneWidget);
    expect(find.text('Deshacer'), findsOneWidget);

    await esperar(t, 2500);
    expect(find.textContaining('Quitaste'), findsOneWidget, reason: 'sigue a la vista mientras se puede deshacer');

    await esperar(t, 3500);
    expect(find.textContaining('Quitaste'), findsNothing, reason: 'a los 5 s se quita solo, con acción y todo');
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('el aviso "Agregaste…" también se quita solo', (t) async {
    telefono(t);
    await t.pumpWidget(app(const Shell()));
    await t.pump(const Duration(milliseconds: 600));
    estado.irAPestana(2);
    await t.pump(const Duration(milliseconds: 600));
    await t.tap(find.text('Aprovechar oferta'), warnIfMissed: false);
    await esperar(t, 800);
    expect(find.textContaining('Agregaste'), findsOneWidget);
    await esperar(t, 4500);
    expect(find.textContaining('Agregaste'), findsNothing);
    await t.pumpWidget(const SizedBox());
  });

  test('comprar crea un pedido de verdad: queda primero, con lo comprado, y vacía el carrito', () {
    final lineas = Map.of(estado.carrito);
    final total = estado.subtotal;
    final p = estado.registrarPedido(correo: 'Ana@Correo.cl', direccion: 'Los Aromos 1234, Concepción');
    expect(p.numero, 'SED-1043', reason: 'continúa desde el pedido más alto');
    expect(estado.pedidos.first, same(p));
    expect(p.lineas, lineas);
    expect(p.total, total);
    expect(p.estado, EstadoPedido.recibido);
    expect(estado.carrito, isEmpty);
    expect(estado.siguienteNumeroPedido, 'SED-1044');
  });

  test('seguimiento: exige el correo de la compra y no inventa pedidos', () {
    estado.cargarCarritoDeEjemplo();
    final p = estado.registrarPedido(correo: 'ana@correo.cl', direccion: 'x');
    expect(estado.buscarPedido(p.numero, correo: 'ANA@correo.cl'), same(p));
    expect(estado.buscarPedido(' ${p.numero.toLowerCase()} ', correo: 'ana@correo.cl'), same(p));
    expect(estado.buscarPedido(p.numero, correo: 'otra@correo.cl'), isNull);
    expect(estado.buscarPedido('SED-9999', correo: 'ana@correo.cl'), isNull);
    expect(estado.buscarPedido(p.numero), same(p), reason: 'desde la pantalla de compra no se pide el correo');
  });

  test('un pedido avanza solo con el tiempo', () {
    Pedido a(Duration edad) => Pedido('SED-1', 'hoy', EstadoPedido.recibido, {4: 1}, 'x', creado: DateTime.now().subtract(edad));
    expect(a(const Duration(seconds: 20)).estado, EstadoPedido.recibido);
    expect(a(const Duration(minutes: 5)).estado, EstadoPedido.preparando);
    expect(a(const Duration(hours: 2)).estado, EstadoPedido.enCamino);
    expect(a(const Duration(days: 2)).estado, EstadoPedido.entregado);
  });

  testWidgets('seguimiento sin cuenta: pedido inexistente muestra un error claro', (t) async {
    telefono(t);
    await t.pumpWidget(app(const SeguimientoPantalla()));
    await t.pump(const Duration(milliseconds: 300));
    await t.enterText(find.byType(TextField).at(0), 'SED-9999');
    await t.enterText(find.byType(TextField).at(1), 'ana@correo.cl');
    await t.tap(find.text('Buscar mi pedido'), warnIfMissed: false);
    await t.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('No encontramos ese pedido'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  test('todo lo que la persona hizo se guarda y se restaura (carrito, sesión, direcciones, pedidos, preferencias)', () {
    estado.iniciarSesion('Ana Pérez', 'ana@correo.cl');
    estado.actualizarPerfil(nombre: 'Ana Pérez', correo: 'ana@correo.cl', telefono: '+56 9 1111 2222');
    estado.direcciones.add(Direccion('Trabajo', 'Calle Nueva 5', 'Talcahuano', ''));
    estado.cambiarModoTema(ModoTema.oscuro);
    estado.cambiarEscala(1.3);
    final foto = jsonDecode(jsonEncode(estado.aJson())) as Map<String, dynamic>;

    estado.cerrarSesion();
    estado.vaciarCarrito();
    estado.direcciones.removeWhere((d) => d.alias == 'Trabajo');
    estado.cambiarModoTema(ModoTema.auto);
    estado.cambiarEscala(1.0);

    estado.restaurar(foto);
    expect(estado.nombre, 'Ana Pérez');
    expect(estado.telefono, '+56 9 1111 2222');
    expect(estado.carrito, {4: 2, 32: 1, 12: 1});
    expect(estado.direcciones.any((d) => d.alias == 'Trabajo'), isTrue);
    expect(estado.modoTema, ModoTema.oscuro);
    expect(estado.escalaTexto, 1.3);

    estado.direcciones.removeWhere((d) => d.alias == 'Trabajo');
    estado.cambiarModoTema(ModoTema.auto);
    estado.cambiarEscala(1.0);
  });

  test('un producto que ya no existe se quita del carrito guardado', () {
    estado.carrito[99999] = 2;
    estado.depurarCarrito();
    expect(estado.carrito.containsKey(99999), isFalse);
    expect(estado.carrito.containsKey(4), isTrue);
  });

  test('el nombre sale del correo y una cuenta nueva parte sin pedidos ni direcciones', () {
    expect(Estado.nombreDesdeCorreo('maria.gonzalez@correo.cl'), 'Maria Gonzalez');
    expect(Estado.nombreDesdeCorreo('jperez99@x.cl'), 'Jperez');
    expect(Estado.nombreDesdeCorreo('@x.cl'), 'Cliente');

    final pedidos = List.of(estado.pedidos);
    final direcciones = List.of(estado.direcciones);
    estado.crearCuenta('Nueva Persona', 'nueva@correo.cl');
    expect(estado.pedidos, isEmpty);
    expect(estado.direcciones, isEmpty);
    expect(estado.nombre, 'Nueva Persona');
    estado.pedidos.addAll(pedidos);
    estado.direcciones.addAll(direcciones);
  });

  test('lo guardado por una versión anterior (sin número de versión) se restaura sin perder nada', () {
    final antiguo = <String, dynamic>{
      'carrito': {'4': 3},
      'modoTema': 2,
      'nombre': 'Luis Soto',
      'correo': 'luis@correo.cl',
      'direcciones': [
        {'alias': 'Casa', 'calle': 'Calle 1', 'comuna': 'Concepción', 'referencia': '', 'principal': true}
      ],
    };
    final migrado = PersistenciaEstado.migrar(antiguo);
    expect(migrado['v'], versionDatos);
    expect(migrado['nombre'], 'Luis Soto');
    estado.restaurar(antiguo);
    expect(estado.carrito, {4: 3});
    expect(estado.modoTema, ModoTema.oscuro);
    expect(estado.direcciones.single.calle, 'Calle 1');
    estado.cambiarModoTema(ModoTema.auto);
    estado.cargarCarritoDeEjemplo();
    estado.cerrarSesion();
  });

  test('lo que se guarda lleva la versión actual y vuelve igual al restaurarlo', () {
    expect(estado.aJson()['v'], versionDatos);
    final ida = jsonDecode(jsonEncode(estado.aJson())) as Map<String, dynamic>;
    estado.restaurar(ida);
    expect(jsonDecode(jsonEncode(estado.aJson())), ida);
  });

  test('el pedido guarda la franja de entrega y el recado para el repartidor', () {
    final p = estado.registrarPedido(correo: 'a@b.cl', direccion: 'x', franja: 'Por la tarde, de 14:00 a 19:00', notas: '  Dejar con el conserje  ');
    expect(p.franja, 'Por la tarde, de 14:00 a 19:00');
    expect(p.notas, 'Dejar con el conserje');
    final ida = Pedido.desdeJson(jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>);
    expect(ida.franja, p.franja);
    expect(ida.notas, p.notas);
    final sin = estado.registrarPedido(correo: 'a@b.cl', direccion: 'x', notas: '   ');
    expect(sin.notas, isNull);
  });

  test('un pedido con retiro en tienda guarda el tipo y usa los textos de retiro', () {
    final p = estado.registrarPedido(correo: 'a@b.cl', direccion: tienda.direccionCompleta, franja: tienda.plazo, retiro: true);
    expect(p.retiro, isTrue);
    final ida = Pedido.desdeJson(jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>);
    expect(ida.retiro, isTrue);
    expect(EstadoPedido.enCamino.textoPara(true), 'Listo para retirar');
    expect(EstadoPedido.entregado.textoPara(true), 'Retirado');
    expect(EstadoPedido.enCamino.textoPara(false), 'En camino');
  });

  test('el despacho es gratis desde \$39.990', () {
    expect(despachoGratisDesde, 39990);
    estado.vaciarCarrito();
    estado.agregar(Catalogo.porId(34), 25); // 25 x 1.590 = 39.750: falta poco
    expect(estado.despachoGratis, isFalse);
    estado.agregar(Catalogo.porId(34), 1);
    expect(estado.despachoGratis, isTrue);
    estado.cargarCarritoDeEjemplo();
  });

  testWidgets('los avisos tienen una X para quitarlos de inmediato', (t) async {
    telefono(t);
    estado.irAPestana(3);
    await t.pumpWidget(app(const Shell()));
    await t.pump(const Duration(milliseconds: 600));
    await t.tap(find.text('Quitar').first, warnIfMissed: false);
    await esperar(t, 800);
    expect(find.textContaining('Quitaste'), findsOneWidget);
    await t.tap(find.byIcon(Icons.close), warnIfMissed: false);
    await esperar(t, 600);
    expect(find.textContaining('Quitaste'), findsNothing, reason: 'la X lo quita sin esperar los 5 segundos');
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('los avisos quedan abajo, cerca de la barra de pestañas, también al vaciar el carrito', (t) async {
    telefono(t);
    estado.carrito
      ..clear()
      ..[4] = 1;
    estado.irAPestana(3);
    await t.pumpWidget(app(const Shell()));
    await t.pump(const Duration(milliseconds: 600));
    await t.tap(find.text('Quitar').first, warnIfMissed: false);
    await esperar(t, 800);
    expect(find.textContaining('Quitaste'), findsOneWidget);
    final abajo = t.getBottomLeft(find.byType(SnackBar)).dy;
    final barra = t.getTopLeft(find.byType(NavigationBar)).dy;
    expect(barra - abajo, lessThan(24), reason: 'con el carrito vacío el aviso queda pegado a la barra, como en el inicio');
    await t.pumpWidget(const SizedBox());
  });
}
