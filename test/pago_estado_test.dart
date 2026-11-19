import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sedyjo_app/app/datos.dart';
import 'package:sedyjo_app/pago/modelos_pago.dart';

PagoPendiente _pendiente(String numero) => PagoPendiente(
      numero: numero,
      token: 'tok-123',
      total: 12990,
      solicitud: const SolicitudPago(
        lineas: {1: 2},
        totalVisto: 12990,
        nombre: 'Ana Pérez',
        correo: 'ana@correo.cl',
        telefono: '+56911112222',
        retiro: false,
        direccion: 'Los Aromos 1234',
      ),
      creado: DateTime(2026, 11, 16, 10, 30),
    );

void main() {
  late List<Pedido> pedidosIniciales;

  setUp(() {
    pedidosIniciales = List.of(estado.pedidos);
  });

  tearDown(() {
    estado.carrito.clear();
    estado.limpiarPagoPendiente();
    estado.pedidos
      ..clear()
      ..addAll(pedidosIniciales);
  });

  test('un pedido con número del servidor y líneas pagadas descuenta solo eso del carrito', () {
    estado.carrito
      ..clear()
      ..addAll({1: 3, 2: 1});
    final p = estado.registrarPedido(
      correo: 'ana@correo.cl',
      direccion: 'Los Aromos 1234',
      numero: 'SED-10482',
      lineas: {1: 2},
    );
    expect(p.numero, 'SED-10482');
    expect(p.lineas, {1: 2});
    expect(estado.pedidos.first.numero, 'SED-10482');
    expect(estado.pedidos.first.lineas, {1: 2});
    expect(estado.carrito, {1: 1, 2: 1});
  });

  test('si la línea pagada es toda la del carrito, el carrito queda vacío', () {
    estado.carrito
      ..clear()
      ..addAll({1: 2});
    estado.registrarPedido(correo: 'ana@correo.cl', direccion: 'x', numero: 'SED-10483', lineas: {1: 2});
    expect(estado.carrito, isEmpty);
  });

  test('si se pagó más de lo que queda en el carrito, la entrada se quita', () {
    estado.carrito
      ..clear()
      ..addAll({1: 1, 2: 1});
    estado.registrarPedido(correo: 'ana@correo.cl', direccion: 'x', numero: 'SED-10484', lineas: {1: 2});
    expect(estado.carrito, {2: 1});
  });

  test('sin número ni líneas el pedido toma el siguiente número y el carrito completo (se vacía)', () {
    estado.carrito
      ..clear()
      ..addAll({1: 3, 2: 1});
    final esperado = estado.siguienteNumeroPedido;
    final p = estado.registrarPedido(correo: 'ana@correo.cl', direccion: 'x');
    expect(p.numero, esperado);
    expect(p.lineas, {1: 3, 2: 1});
    expect(estado.carrito, isEmpty);
  });

  test('guardar y limpiar el pago pendiente avisa a quien escucha', () {
    var avisos = 0;
    void escucha() => avisos++;
    estado.addListener(escucha);
    addTearDown(() => estado.removeListener(escucha));

    estado.guardarPagoPendiente(_pendiente('SED-10482'));
    expect(estado.pagoPendiente?.numero, 'SED-10482');
    expect(avisos, 1);
    estado.limpiarPagoPendiente();
    expect(estado.pagoPendiente, isNull);
    expect(avisos, 2);
  });

  test('lo que se guarda lleva la versión 3 y el pago pendiente vuelve igual al restaurar', () {
    expect(versionDatos, 3);
    expect(estado.aJson()['v'], 3);
    expect(estado.aJson()['pagoPendiente'], isNull);

    estado.guardarPagoPendiente(_pendiente('SED-10482'));
    final ida = jsonDecode(jsonEncode(estado.aJson())) as Map<String, dynamic>;
    expect(ida['pagoPendiente'], isA<Map<String, dynamic>>());

    estado.limpiarPagoPendiente();
    expect(estado.pagoPendiente, isNull);
    estado.restaurar(ida);
    expect(estado.pagoPendiente?.numero, 'SED-10482');
    expect(estado.pagoPendiente?.token, 'tok-123');
    expect(estado.pagoPendiente?.solicitud.lineas, {1: 2});
  });

  test('migrar lleva lo guardado en v2 a v3 y restaurar sin la clave deja el pago pendiente en null', () {
    final v2 = <String, dynamic>{
      'v': 2,
      'carrito': {'4': 3},
      'nombre': 'Luis Soto',
    };
    expect(PersistenciaEstado.migrar(v2)['v'], 3);
    expect(PersistenciaEstado.migrar({'nombre': 'x'})['v'], 3);

    estado.guardarPagoPendiente(_pendiente('SED-10482'));
    estado.restaurar(v2);
    expect(estado.pagoPendiente, isNull);
    expect(estado.carrito, {4: 3});
  });

  test('un pago pendiente guardado con datos dañados no impide restaurar lo demás', () {
    estado.restaurar({
      'v': 3,
      'carrito': {'4': 2},
      'nombre': 'Luis Soto',
      'correo': 'luis@correo.cl',
      'pagoPendiente': {'numero': 5},
    });
    expect(estado.pagoPendiente, isNull);
    expect(estado.carrito, {4: 2});
    expect(estado.nombre, 'Luis Soto');
    expect(estado.correo, 'luis@correo.cl');
    estado.cerrarSesion();
  });
}
