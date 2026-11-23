import 'package:flutter_test/flutter_test.dart';
import 'package:sedyjo_app/pago/configuracion_pago.dart';

ConfiguracionPago _resolver({
  String modo = 'simulado',
  String apiUrl = '',
  bool esWeb = false,
  bool esRelease = false,
}) =>
    ConfiguracionPago.resolver(
        modo: modo, apiUrl: apiUrl, esWeb: esWeb, esRelease: esRelease);

void main() {
  group('ConfiguracionPago.resolver', () {
    test('web siempre usa el modo simulado, aunque se pida webpay', () {
      expect(_resolver(modo: 'webpay', esWeb: true).modo, ModoPago.simulado);
    });

    test('móvil release siempre usa webpay, aunque se pida simulado', () {
      expect(_resolver(modo: 'simulado', esRelease: true).modo,
          ModoPago.webpay);
    });

    test('móvil debug respeta lo pedido', () {
      expect(_resolver(modo: 'webpay').modo, ModoPago.webpay);
      expect(_resolver(modo: 'simulado').modo, ModoPago.simulado);
      expect(_resolver(modo: 'cualquier cosa').modo, ModoPago.simulado);
    });

    test('apiUrl se normaliza sin «/» final', () {
      expect(_resolver(apiUrl: 'https://x.cl/api/v1/').apiUrl,
          'https://x.cl/api/v1');
    });
  });

  group('ConfiguracionPago.disponible', () {
    test('webpay sin apiUrl no está disponible', () {
      expect(_resolver(modo: 'webpay', apiUrl: '').disponible, isFalse);
    });

    test('webpay con apiUrl está disponible', () {
      expect(_resolver(modo: 'webpay', apiUrl: 'https://x.cl/api/v1').disponible,
          isTrue);
    });

    test('simulado siempre está disponible', () {
      expect(_resolver(modo: 'simulado').disponible, isTrue);
    });
  });
}
