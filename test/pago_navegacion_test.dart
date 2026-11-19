import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sedyjo_app/pago/navegacion_webpay.dart';

void main() {
  final urlFin = Uri.parse('https://api.sedyjo.com/api/v1/pagos/webpay/fin');
  DecisionNavegacion decide(String url, {bool permitirHttp = false}) =>
      decidirNavegacion(Uri.parse(url), urlFin, permitirHttp: permitirHttp);

  group('decidirNavegacion', () {
    test('la URL de fin (con query) termina el pago', () {
      expect(decide('https://api.sedyjo.com/api/v1/pagos/webpay/fin?numero=SED-10482'), DecisionNavegacion.terminar);
    });

    test('la URL de fin termina el pago aunque venga por http', () {
      expect(decide('http://api.sedyjo.com/api/v1/pagos/webpay/fin?numero=SED-10482'), DecisionNavegacion.terminar);
    });

    test('la URL de fin se evalúa antes que el esquema (también con http no permitido)', () {
      expect(decide('http://api.sedyjo.com/api/v1/pagos/webpay/fin', permitirHttp: false), DecisionNavegacion.terminar);
    });

    test('otra ruta del mismo servidor no termina el pago', () {
      expect(decide('https://api.sedyjo.com/api/v1/pagos/webpay/otra'), DecisionNavegacion.permitir);
    });

    test('las páginas de Webpay y del banco por https se permiten', () {
      expect(decide('https://webpay3gint.transbank.cl/webpayserver/initTransaction'), DecisionNavegacion.permitir);
      expect(decide('https://acs.banco.cl/3ds'), DecisionNavegacion.permitir);
    });

    test('http se bloquea, salvo que se permita expresamente', () {
      expect(decide('http://acs.banco.cl'), DecisionNavegacion.bloquear);
      expect(decide('http://acs.banco.cl', permitirHttp: true), DecisionNavegacion.permitir);
    });

    test('esquemas peligrosos o desconocidos se bloquean', () {
      expect(decide('intent://x#Intent;scheme=https;end'), DecisionNavegacion.bloquear);
      expect(decide('market://details?id=x'), DecisionNavegacion.bloquear);
      expect(decide('file:///etc/passwd'), DecisionNavegacion.bloquear);
      expect(decide('javascript:alert(1)'), DecisionNavegacion.bloquear);
      expect(decide('data:text/html,<b>x</b>'), DecisionNavegacion.bloquear);
      expect(decide('tel:+56912345678'), DecisionNavegacion.bloquear);
    });

    test('about:blank se permite', () {
      expect(decide('about:blank'), DecisionNavegacion.permitir);
    });
  });

  group('cuerpoFormulario', () {
    test('codifica el token como formulario', () {
      expect(utf8.decode(cuerpoFormulario('abc+/==')), 'token_ws=abc%2B%2F%3D%3D');
    });
  });
}
