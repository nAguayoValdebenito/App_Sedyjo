// Cómo se cobra: una interfaz y sus variantes (simulada, no disponible y,
// más adelante, Webpay). Quien paga solo conoce `PasarelaPago`.

import '../app/datos.dart';
import 'modelos_pago.dart';

abstract class PasarelaPago {
  /// Inicia el pago. Puede lanzar [ErrorPago].
  Future<InicioPago> iniciar(SolicitudPago solicitud);

  /// Cómo terminó el pago iniciado, una vez que el cliente volvió.
  Future<ResultadoPago> resultado(PagoPendiente pendiente, RetornoPago retorno);
}

/// El comportamiento de siempre: sin cobro real, aprueba o rechaza según el
/// interruptor de simulación de la app.
class PasarelaSimulada implements PasarelaPago {
  PasarelaSimulada({this.espera = const Duration(milliseconds: 600)});

  /// Cuánto tarda en "confirmar" (en pruebas, `Duration.zero`).
  final Duration espera;

  @override
  Future<InicioPago> iniciar(SolicitudPago solicitud) async {
    return InicioPago(PagoPendiente(
      numero: estado.siguienteNumeroPedido,
      token: 'simulado',
      total: solicitud.totalVisto,
      solicitud: solicitud,
      creado: DateTime.now(),
    ));
  }

  @override
  Future<ResultadoPago> resultado(PagoPendiente pendiente, RetornoPago retorno) async {
    await Future<void>.delayed(espera);
    if (estado.simulacionPago == SimulacionPago.rechazado) return const ResultadoPago.rechazado();
    return ResultadoPago.aprobado(
      numero: pendiente.numero,
      total: pendiente.total,
      correo: pendiente.solicitud.correo,
      retiro: pendiente.solicitud.retiro,
    );
  }
}

/// Cuando el pago en línea no se puede ofrecer: no inicia nada y no cobra.
class PasarelaNoDisponible implements PasarelaPago {
  const PasarelaNoDisponible();

  @override
  Future<InicioPago> iniciar(SolicitudPago solicitud) async {
    throw const ErrorPago(
      'no_disponible',
      'El pago en línea no está disponible por ahora. Llámanos y tomamos tu pedido; no se cobró nada.',
    );
  }

  @override
  Future<ResultadoPago> resultado(PagoPendiente pendiente, RetornoPago retorno) async => const ResultadoPago.sinConfirmar();
}
