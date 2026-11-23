import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sedyjo_app/pago/modelos_pago.dart';

SolicitudPago solicitud({bool retiro = false, String? notas = '  '}) => SolicitudPago(
      lineas: const {12: 2},
      totalVisto: 12140,
      nombre: 'María González',
      correo: 'maria@correo.cl',
      telefono: '+56912345678',
      retiro: retiro,
      direccion: 'Los Aromos 1234, Concepción',
      franja: 'Cualquier horario',
      notas: notas,
    );

void main() {
  group('SolicitudPago.aJsonApi', () {
    test('arma el cuerpo de POST /pagos/webpay con las notas en blanco como null', () {
      expect(solicitud().aJsonApi(), {
        'totalVisto': 12140,
        'cliente': {'nombre': 'María González', 'correo': 'maria@correo.cl', 'telefono': '+56912345678'},
        'entrega': {
          'tipo': 'domicilio',
          'direccion': 'Los Aromos 1234, Concepción',
          'franja': 'Cualquier horario',
          'notas': null,
        },
        'items': [
          {'productoId': 12, 'cantidad': 2},
        ],
      });
    });

    test('con retiro el tipo de entrega es retiro', () {
      expect((solicitud(retiro: true).aJsonApi()['entrega'] as Map)['tipo'], 'retiro');
    });

    test('envía las notas con contenido tal cual', () {
      expect((solicitud(notas: 'Tocar el timbre').aJsonApi()['entrega'] as Map)['notas'], 'Tocar el timbre');
    });

    test('conTotal cambia solo el total visto', () {
      final nueva = solicitud().conTotal(9990);
      expect(nueva.totalVisto, 9990);
      expect(nueva.lineas, {12: 2});
      expect(nueva.correo, 'maria@correo.cl');
    });
  });

  group('PagoPendiente', () {
    test('desdeJson(toJson()) conserva número, token, total, líneas y creado', () {
      final creado = DateTime.utc(2026, 11, 16, 15, 30);
      final p = PagoPendiente(numero: 'SED-1043', token: 'tok123', total: 12140, solicitud: solicitud(), creado: creado);
      // Pasa por texto JSON de verdad: ahí las claves del mapa de líneas se vuelven texto.
      final q = PagoPendiente.desdeJson(jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>);
      expect(q.numero, 'SED-1043');
      expect(q.token, 'tok123');
      expect(q.total, 12140);
      expect(q.solicitud.lineas, {12: 2});
      expect(q.solicitud.nombre, 'María González');
      expect(q.creado.isAtSameMomentAs(creado), isTrue);
    });

    test('vencido a partir de 24 horas', () {
      final ahora = DateTime.utc(2026, 11, 16, 12);
      PagoPendiente creadoHace(int horas) => PagoPendiente(
            numero: 'SED-1',
            token: 't',
            total: 1000,
            solicitud: solicitud(),
            creado: ahora.subtract(Duration(hours: horas)),
          );
      expect(creadoHace(25).vencido(ahora), isTrue);
      expect(creadoHace(23).vencido(ahora), isFalse);
    });
  });

  group('ResultadoPago', () {
    test('los resultados sin pago llevan su motivo y no están aprobados', () {
      expect(const ResultadoPago.rechazado().motivo, MotivoNoPago.rechazado);
      expect(const ResultadoPago.cancelado().motivo, MotivoNoPago.cancelado);
      expect(const ResultadoPago.sinConfirmar().motivo, MotivoNoPago.sinConfirmar);
      expect(const ResultadoPago.rechazado().aprobado, isFalse);
      expect(const ResultadoPago.cancelado().aprobado, isFalse);
      expect(const ResultadoPago.sinConfirmar().aprobado, isFalse);
    });

    test('aprobado no tiene motivo y conserva sus datos', () {
      const r = ResultadoPago.aprobado(numero: 'SED-1043', total: 12140, correo: 'a@b.cl');
      expect(r.aprobado, isTrue);
      expect(r.motivo, isNull);
      expect(r.numero, 'SED-1043');
      expect(r.total, 12140);
      expect(r.correo, 'a@b.cl');
      expect(r.retiro, isFalse);
      expect(r.comprobante, isNull);
    });
  });
}
