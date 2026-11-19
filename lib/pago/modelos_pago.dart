// Modelos del pago: lo que se envía al backend, lo que queda pendiente en el
// dispositivo y cómo termina. No depende de `app/datos.dart` (evita un ciclo).

/// Cómo volvió el cliente de la página de Webpay.
enum RetornoPago { completado, cancelado, cerrado, desconocido }

/// Por qué un pago no quedó aprobado.
enum MotivoNoPago { rechazado, cancelado, sinConfirmar }

/// Lo que el cliente quiere comprar y sus datos de entrega.
/// Todo el dinero va en pesos chilenos (enteros).
class SolicitudPago {
  const SolicitudPago({
    required this.lineas,
    required this.totalVisto,
    required this.nombre,
    required this.correo,
    required this.telefono,
    required this.retiro,
    required this.direccion,
    this.franja,
    this.notas,
  });

  /// Producto (id) → cantidad.
  final Map<int, int> lineas;

  /// Total que el cliente vio en pantalla; el backend lo contrasta con el real.
  final int totalVisto;
  final String nombre;
  final String correo;
  final String telefono;
  final bool retiro;
  final String direccion;
  final String? franja;
  final String? notas;

  /// Cuerpo de `POST /pagos/webpay`.
  Map<String, dynamic> aJsonApi() {
    final nota = notas?.trim();
    return {
      'totalVisto': totalVisto,
      'cliente': {'nombre': nombre, 'correo': correo, 'telefono': telefono},
      'entrega': {
        'tipo': retiro ? 'retiro' : 'domicilio',
        'direccion': direccion,
        'franja': franja,
        'notas': (nota == null || nota.isEmpty) ? null : notas,
      },
      'items': [
        for (final e in lineas.entries) {'productoId': e.key, 'cantidad': e.value},
      ],
    };
  }

  /// Para guardar en el dispositivo (las claves del mapa pasan a texto, como exige JSON).
  Map<String, dynamic> toJson() => {
        'lineas': {for (final e in lineas.entries) '${e.key}': e.value},
        'totalVisto': totalVisto,
        'nombre': nombre,
        'correo': correo,
        'telefono': telefono,
        'retiro': retiro,
        'direccion': direccion,
        'franja': franja,
        'notas': notas,
      };

  factory SolicitudPago.desdeJson(Map<String, dynamic> j) => SolicitudPago(
        lineas: {
          for (final e in (j['lineas'] as Map).entries) int.parse('${e.key}'): (e.value as num).toInt(),
        },
        totalVisto: (j['totalVisto'] as num).toInt(),
        nombre: j['nombre'] as String,
        correo: j['correo'] as String,
        telefono: j['telefono'] as String,
        retiro: j['retiro'] as bool,
        direccion: j['direccion'] as String,
        franja: j['franja'] as String?,
        notas: j['notas'] as String?,
      );

  /// La misma solicitud con otro total (cuando el cliente acepta el total nuevo).
  SolicitudPago conTotal(int totalVisto) => SolicitudPago(
        lineas: lineas,
        totalVisto: totalVisto,
        nombre: nombre,
        correo: correo,
        telefono: telefono,
        retiro: retiro,
        direccion: direccion,
        franja: franja,
        notas: notas,
      );
}

/// A dónde hay que llevar al cliente para pagar en Webpay.
class Redireccion {
  const Redireccion({required this.url, required this.token, required this.urlFin});

  /// Página de pago de Webpay.
  final Uri url;
  final String token;

  /// Dirección a la que Webpay devuelve al cliente al terminar.
  final Uri urlFin;
}

/// Un pago iniciado que aún no se confirma; se guarda para poder retomarlo.
class PagoPendiente {
  PagoPendiente({
    required this.numero,
    required this.token,
    required this.total,
    required this.solicitud,
    required this.creado,
  });

  final String numero;
  final String token;
  final int total;
  final SolicitudPago solicitud;
  final DateTime creado;

  /// Pasadas más de 24 horas ya no vale la pena retomarlo.
  bool vencido(DateTime ahora) => ahora.difference(creado) > const Duration(hours: 24);

  Map<String, dynamic> toJson() => {
        'numero': numero,
        'token': token,
        'total': total,
        'solicitud': solicitud.toJson(),
        'creado': creado.toIso8601String(),
      };

  factory PagoPendiente.desdeJson(Map<String, dynamic> j) => PagoPendiente(
        numero: j['numero'] as String,
        token: j['token'] as String,
        total: (j['total'] as num).toInt(),
        solicitud: SolicitudPago.desdeJson(Map<String, dynamic>.from(j['solicitud'] as Map)),
        creado: DateTime.parse(j['creado'] as String),
      );
}

/// Resultado de iniciar el pago: el pendiente y, si hay que pagar fuera, a dónde ir.
class InicioPago {
  const InicioPago(this.pendiente, {this.redireccion});
  final PagoPendiente pendiente;
  final Redireccion? redireccion;
}

/// Datos de la transacción aprobada.
class ComprobantePago {
  const ComprobantePago({
    required this.codigoAutorizacion,
    required this.tarjetaUltimos4,
    required this.tipoPago,
    required this.cuotas,
    this.fecha,
  });
  final String codigoAutorizacion;
  final String tarjetaUltimos4;
  final String tipoPago;
  final int cuotas;
  final DateTime? fecha;
}

/// Cómo terminó el pago.
class ResultadoPago {
  const ResultadoPago.aprobado({
    required String this.numero,
    required this.total,
    required this.correo,
    this.retiro = false,
    this.comprobante,
  })  : aprobado = true,
        motivo = null;
  const ResultadoPago.rechazado() : this._sinPago(MotivoNoPago.rechazado);
  const ResultadoPago.cancelado() : this._sinPago(MotivoNoPago.cancelado);
  const ResultadoPago.sinConfirmar() : this._sinPago(MotivoNoPago.sinConfirmar);

  const ResultadoPago._sinPago(this.motivo)
      : aprobado = false,
        numero = null,
        total = 0,
        correo = '',
        retiro = false,
        comprobante = null;

  final bool aprobado;
  final MotivoNoPago? motivo;
  final String? numero;
  final int total;
  final String correo;
  final bool retiro;
  final ComprobantePago? comprobante;
}

/// Error del backend de pagos, con el código que éste informa.
class ErrorPago implements Exception {
  const ErrorPago(this.codigo, this.mensaje, {this.totalNuevo});
  final String codigo;
  final String mensaje;

  /// Total actualizado cuando el error es un cambio de precio.
  final int? totalNuevo;

  @override
  String toString() => 'ErrorPago($codigo): $mensaje';
}
