import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sedyjo_app/pago/modelos_pago.dart';
import 'package:sedyjo_app/pago/pasarela_webpay.dart';

const _api = 'https://api.test/v1';

const _solicitud = SolicitudPago(
  lineas: {12: 2},
  totalVisto: 12140,
  nombre: 'María González',
  correo: 'maria@correo.cl',
  telefono: '+56912345678',
  retiro: false,
  direccion: 'Los Aromos 1234, Concepción',
  franja: 'Cualquier horario',
);

final _token = 'T' * 64;

http.Response _json(int codigo, Object cuerpo) =>
    http.Response(jsonEncode(cuerpo), codigo, headers: {'content-type': 'application/json; charset=utf-8'});

http.Response _inicioOk() => _json(201, {
      'data': {
        'numero': 'SED-10482',
        'token': _token,
        'url': 'https://webpay3gint.transbank.cl/webpayserver/initTransaction',
        'urlFin': 'https://api.test/v1/pagos/webpay/fin',
        'total': 12140,
      },
    });

http.Response _estado(String estado, {Map<String, dynamic>? comprobante}) => _json(200, {
      'data': {
        'numero': 'SED-10482',
        'estado': estado,
        'total': 12140,
        'correo': 'maria@correo.cl',
        'retiro': false,
        'comprobante': ?comprobante,
      },
    });

PasarelaWebpay _pasarela(MockClient cliente, {List<Duration>? esperas}) => PasarelaWebpay(
      apiUrl: _api,
      cliente: cliente,
      esperar: (_) async {},
      esperas: esperas ?? const [Duration.zero, Duration(seconds: 1), Duration(seconds: 1), Duration(seconds: 2)],
    );

PagoPendiente _pendiente() => PagoPendiente(
      numero: 'SED-10482',
      token: _token,
      total: 12140,
      solicitud: _solicitud,
      creado: DateTime.now(),
    );

/// Un cliente que responde en orden con cada elemento (respuesta o excepción);
/// el último se repite. Guarda las peticiones recibidas.
MockClient _secuencia(List<Object> pasos, List<http.Request> peticiones) {
  var i = 0;
  return MockClient((request) async {
    peticiones.add(request);
    final paso = pasos[i < pasos.length ? i : pasos.length - 1];
    i++;
    if (paso is http.Response) return paso;
    throw paso;
  });
}

void main() {
  group('PasarelaWebpay.iniciar', () {
    test('hace POST con el cuerpo y la clave de idempotencia, y devuelve el inicio', () async {
      final peticiones = <http.Request>[];
      final pasarela = _pasarela(_secuencia([_inicioOk()], peticiones));

      final inicio = await pasarela.iniciar(_solicitud);

      expect(peticiones, hasLength(1));
      final p = peticiones.single;
      expect(p.method, 'POST');
      expect(p.url.toString(), 'https://api.test/v1/pagos/webpay');
      expect(jsonDecode(p.body), _solicitud.aJsonApi());
      expect(p.headers['Idempotency-Key'], matches(RegExp(r'^[0-9a-f]{32}$')));
      expect(p.headers['Content-Type'], startsWith('application/json'));

      expect(inicio.pendiente.numero, 'SED-10482');
      expect(inicio.pendiente.token, _token);
      expect(inicio.pendiente.total, 12140);
      expect(inicio.pendiente.solicitud, same(_solicitud));
      expect(inicio.redireccion!.url, Uri.parse('https://webpay3gint.transbank.cl/webpayserver/initTransaction'));
      expect(inicio.redireccion!.token, _token);
      expect(inicio.redireccion!.urlFin, Uri.parse('https://api.test/v1/pagos/webpay/fin'));
    });

    test('409 precios_cambiaron: error con el total nuevo', () async {
      final pasarela = _pasarela(_secuencia([
        _json(409, {'error': 'Los precios cambiaron', 'code': 'precios_cambiaron', 'total': 12500}),
      ], []));

      await expectLater(
        pasarela.iniciar(_solicitud),
        throwsA(isA<ErrorPago>()
            .having((e) => e.codigo, 'codigo', 'precios_cambiaron')
            .having((e) => e.totalNuevo, 'totalNuevo', 12500)),
      );
    });

    test('409 sin_stock: el mensaje es el del servidor', () async {
      final pasarela = _pasarela(_secuencia([
        _json(409, {'error': 'No queda stock de Lúcuma', 'code': 'sin_stock'}),
      ], []));

      await expectLater(
        pasarela.iniciar(_solicitud),
        throwsA(isA<ErrorPago>()
            .having((e) => e.codigo, 'codigo', 'sin_stock')
            .having((e) => e.mensaje, 'mensaje', 'No queda stock de Lúcuma')
            .having((e) => e.totalNuevo, 'totalNuevo', isNull)),
      );
    });

    test('un fallo de red se reintenta una vez con la misma clave', () async {
      final peticiones = <http.Request>[];
      final pasarela = _pasarela(_secuencia([TimeoutException('lento'), _inicioOk()], peticiones));

      final inicio = await pasarela.iniciar(_solicitud);

      expect(inicio.pendiente.numero, 'SED-10482');
      expect(peticiones, hasLength(2));
      expect(peticiones[0].headers['Idempotency-Key'], matches(RegExp(r'^[0-9a-f]{32}$')));
      expect(peticiones[1].headers['Idempotency-Key'], peticiones[0].headers['Idempotency-Key']);
    });

    test('dos fallos de red seguidos: sin_conexion; 500: servidor', () async {
      final peticiones = <http.Request>[];
      final sinRed = _pasarela(_secuencia([http.ClientException('sin red')], peticiones));

      await expectLater(
        sinRed.iniciar(_solicitud),
        throwsA(isA<ErrorPago>()
            .having((e) => e.codigo, 'codigo', 'sin_conexion')
            .having((e) => e.mensaje, 'mensaje', 'No pudimos conectar. Revisa tu conexión: no se cobró nada.')),
      );
      expect(peticiones, hasLength(2));

      final peticiones500 = <http.Request>[];
      final caido = _pasarela(_secuencia([http.Response('boom', 500)], peticiones500));
      await expectLater(
        caido.iniciar(_solicitud),
        throwsA(isA<ErrorPago>()
            .having((e) => e.codigo, 'codigo', 'servidor')
            .having((e) => e.mensaje, 'mensaje',
                'No pudimos iniciar el pago. No se cobró nada. Inténtalo de nuevo en un momento.')),
      );
      expect(peticiones500, hasLength(1), reason: 'una respuesta 5xx no se reintenta');
    });

    test('un 2xx ilegible o sin campos es error de servidor', () async {
      for (final respuesta in [
        http.Response('<html>no es json</html>', 200),
        _json(201, {'data': {'numero': 'SED-1'}}),
        _json(201, {'data': {'numero': 'SED-1', 'token': 'x', 'url': 'u', 'urlFin': 'f', 'total': 'mucho'}}),
      ]) {
        final pasarela = _pasarela(_secuencia([respuesta], []));
        await expectLater(
          pasarela.iniciar(_solicitud),
          throwsA(isA<ErrorPago>().having((e) => e.codigo, 'codigo', 'servidor')),
        );
      }
    });
  });

  group('PasarelaWebpay.resultado', () {
    test('sigue consultando mientras está pendiente y aprueba con comprobante', () async {
      final peticiones = <http.Request>[];
      final pasarela = _pasarela(_secuencia([
        _estado('pendiente'),
        _estado('pendiente'),
        _estado('aprobado', comprobante: {
          'codigoAutorizacion': '1213',
          'tarjetaUltimos4': '6623',
          'tipoPago': 'Crédito',
          'cuotas': 0,
          'fecha': '2026-11-16T20:15:00Z',
        }),
      ], peticiones));

      final r = await pasarela.resultado(_pendiente(), RetornoPago.completado);

      expect(r.aprobado, isTrue);
      expect(r.numero, 'SED-10482');
      expect(r.total, 12140);
      expect(r.correo, 'maria@correo.cl');
      expect(r.retiro, isFalse);
      expect(r.comprobante!.codigoAutorizacion, '1213');
      expect(r.comprobante!.tarjetaUltimos4, '6623');
      expect(r.comprobante!.tipoPago, 'Crédito');
      expect(r.comprobante!.cuotas, 0);
      expect(r.comprobante!.fecha, DateTime.utc(2026, 11, 16, 20, 15));
      expect(peticiones, hasLength(3));
      for (final p in peticiones) {
        expect(p.method, 'GET');
        expect(p.url.toString(), 'https://api.test/v1/pagos/webpay/SED-10482');
        expect(p.headers['X-Token-Pago'], _token);
      }
    });

    test('rechazado y expirado son rechazado; cancelado es cancelado', () async {
      for (final e in ['rechazado', 'expirado']) {
        final r = await _pasarela(_secuencia([_estado(e)], [])).resultado(_pendiente(), RetornoPago.completado);
        expect(r.aprobado, isFalse, reason: e);
        expect(r.motivo, MotivoNoPago.rechazado, reason: e);
      }
      final c = await _pasarela(_secuencia([_estado('cancelado')], [])).resultado(_pendiente(), RetornoPago.cancelado);
      expect(c.aprobado, isFalse);
      expect(c.motivo, MotivoNoPago.cancelado);
    });

    test('manda el servidor: aprobado aunque el cliente cerrara la ventana', () async {
      final r = await _pasarela(_secuencia([_estado('aprobado')], []))
          .resultado(_pendiente(), RetornoPago.cerrado);

      expect(r.aprobado, isTrue);
      expect(r.comprobante, isNull);
    });

    test('siempre pendiente: sinConfirmar tras exactamente esperas.length consultas', () async {
      final peticiones = <http.Request>[];
      final esperas = const [Duration.zero, Duration(seconds: 1), Duration(seconds: 2), Duration(seconds: 3), Duration(seconds: 4)];
      final r = await _pasarela(_secuencia([_estado('pendiente')], peticiones), esperas: esperas)
          .resultado(_pendiente(), RetornoPago.completado);

      expect(r.aprobado, isFalse);
      expect(r.motivo, MotivoNoPago.sinConfirmar);
      expect(peticiones, hasLength(esperas.length));
    });

    test('404 es rechazado; 503 y luego aprobado es aprobado; estado desconocido es sinConfirmar', () async {
      final noConocido = await _pasarela(_secuencia([http.Response('no', 404)], []))
          .resultado(_pendiente(), RetornoPago.completado);
      expect(noConocido.motivo, MotivoNoPago.rechazado);

      final peticiones = <http.Request>[];
      final recupera = await _pasarela(_secuencia([http.Response('caido', 503), _estado('aprobado')], peticiones))
          .resultado(_pendiente(), RetornoPago.completado);
      expect(recupera.aprobado, isTrue);
      expect(peticiones, hasLength(2));

      final raro = await _pasarela(_secuencia([_estado('raro')], []))
          .resultado(_pendiente(), RetornoPago.completado);
      expect(raro.aprobado, isFalse);
      expect(raro.motivo, MotivoNoPago.sinConfirmar);
    });

    test('un error de red o una respuesta ilegible no es rechazo: sigue y termina sinConfirmar', () async {
      final r = await _pasarela(_secuencia([
        http.ClientException('sin red'),
        http.Response('<html>', 200),
        _json(200, {'data': 'raro'}),
        _json(200, {'data': {'estado': 'aprobado', 'total': 'x'}}),
      ], [])).resultado(_pendiente(), RetornoPago.completado);

      expect(r.aprobado, isFalse);
      expect(r.motivo, MotivoNoPago.sinConfirmar);
    });
  });
}
