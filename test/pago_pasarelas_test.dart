import 'package:flutter_test/flutter_test.dart';
import 'package:sedyjo_app/app/datos.dart';
import 'package:sedyjo_app/pago/modelos_pago.dart';
import 'package:sedyjo_app/pago/pasarela_pago.dart';

const _solicitud = SolicitudPago(
  lineas: {1: 2},
  totalVisto: 12990,
  nombre: 'Ana Pérez',
  correo: 'ana@correo.cl',
  telefono: '+56911112222',
  retiro: true,
  direccion: 'Los Aromos 1234',
);

void main() {
  group('PasarelaSimulada', () {
    test('inicia sin redirección, con el número siguiente y el total visto', () async {
      final pasarela = PasarelaSimulada(espera: Duration.zero);

      final inicio = await pasarela.iniciar(_solicitud);

      expect(inicio.redireccion, isNull);
      expect(inicio.pendiente.numero, estado.siguienteNumeroPedido);
      expect(inicio.pendiente.numero, startsWith('SED-'));
      expect(inicio.pendiente.token, 'simulado');
      expect(inicio.pendiente.total, 12990);
    });

    test('aprueba por defecto', () async {
      final pasarela = PasarelaSimulada(espera: Duration.zero);
      final inicio = await pasarela.iniciar(_solicitud);

      final r = await pasarela.resultado(inicio.pendiente, RetornoPago.completado);

      expect(r.aprobado, isTrue);
      expect(r.numero, startsWith('SED-'));
      expect(r.numero, inicio.pendiente.numero);
      expect(r.total, 12990);
      expect(r.correo, 'ana@correo.cl');
      expect(r.retiro, isTrue);
    });

    test('rechaza cuando la simulación está en rechazado', () async {
      final anterior = estado.simulacionPago;
      addTearDown(() => estado.cambiarSimulacionPago(anterior));
      estado.cambiarSimulacionPago(SimulacionPago.rechazado);
      final pasarela = PasarelaSimulada(espera: Duration.zero);
      final inicio = await pasarela.iniciar(_solicitud);

      final r = await pasarela.resultado(inicio.pendiente, RetornoPago.completado);

      expect(r.aprobado, isFalse);
      expect(r.motivo, MotivoNoPago.rechazado);
    });
  });

  group('PasarelaNoDisponible', () {
    test('iniciar lanza ErrorPago no_disponible y avisa que no se cobró', () async {
      const pasarela = PasarelaNoDisponible();

      await expectLater(
        pasarela.iniciar(_solicitud),
        throwsA(isA<ErrorPago>()
            .having((e) => e.codigo, 'codigo', 'no_disponible')
            .having((e) => e.mensaje, 'mensaje', contains('no se cobró nada'))),
      );
    });

    test('resultado devuelve sinConfirmar', () async {
      const pasarela = PasarelaNoDisponible();
      final pendiente = PagoPendiente(
        numero: 'SED-1044',
        token: 'tok',
        total: 12990,
        solicitud: _solicitud,
        creado: DateTime(2026, 11, 16),
      );

      final r = await pasarela.resultado(pendiente, RetornoPago.desconocido);

      expect(r.aprobado, isFalse);
      expect(r.motivo, MotivoNoPago.sinConfirmar);
    });
  });
}
