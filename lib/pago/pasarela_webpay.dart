// Cliente HTTP del backend de pagos (Webpay Plus). El contrato está en
// `docs/backend-webpay.md` §4.1 (iniciar) y §4.4 (consultar estado).
//
// Reglas de seguridad (aquí se maneja dinero):
//  - Solo `estado == "aprobado"` explícito del servidor cuenta como pagado.
//  - Si no hay respuesta clara, jamás se declara "rechazado": se sigue
//    consultando y, al agotar las esperas, queda "sin confirmar".
//  - La clave de idempotencia es la misma en el reintento de `iniciar`.
//  - No se registra nada (ni token, ni datos del cliente).

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'modelos_pago.dart';
import 'pasarela_pago.dart';

class PasarelaWebpay implements PasarelaPago {
  PasarelaWebpay({
    required String apiUrl,
    http.Client? cliente,
    Future<void> Function(Duration)? esperar,
    this.tiempoLimite = const Duration(seconds: 15),
    this.esperas = const [
      Duration.zero,
      Duration(seconds: 1),
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 2),
      Duration(seconds: 3),
      Duration(seconds: 3),
      Duration(seconds: 4),
    ],
  })  : _apiUrl = apiUrl.endsWith('/') ? apiUrl.substring(0, apiUrl.length - 1) : apiUrl,
        _cliente = cliente ?? http.Client(),
        _esperar = esperar ?? Future<void>.delayed;

  final String _apiUrl;
  final http.Client _cliente;
  final Future<void> Function(Duration) _esperar;

  /// Tope de cada petición.
  final Duration tiempoLimite;

  /// Pausa previa a cada consulta de estado; su largo es el número de consultas.
  final List<Duration> esperas;

  static const _mensajeServidor = 'No pudimos iniciar el pago. No se cobró nada. Inténtalo de nuevo en un momento.';
  static const _mensajeSinConexion = 'No pudimos conectar. Revisa tu conexión: no se cobró nada.';

  @override
  Future<InicioPago> iniciar(SolicitudPago solicitud) async {
    final clave = _claveIdempotencia();
    final cuerpo = jsonEncode(solicitud.aJsonApi());

    Future<http.Response> intento() => _cliente
        .post(
          Uri.parse('$_apiUrl/pagos/webpay'),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Accept': 'application/json',
            'Idempotency-Key': clave,
          },
          body: cuerpo,
        )
        .timeout(tiempoLimite);

    http.Response respuesta;
    try {
      respuesta = await intento();
    } on TimeoutException {
      respuesta = await _reintentar(intento);
    } on http.ClientException {
      respuesta = await _reintentar(intento);
    }

    final codigo = respuesta.statusCode;
    if (codigo == 200 || codigo == 201) {
      final inicio = _leerInicio(respuesta, solicitud);
      if (inicio == null) throw const ErrorPago('servidor', _mensajeServidor);
      return inicio;
    }
    if (codigo >= 400 && codigo < 500) {
      throw _errorDelServidor(respuesta);
    }
    throw const ErrorPago('servidor', _mensajeServidor);
  }

  /// Segundo y último intento, con la misma clave. Si también falla: sin conexión.
  Future<http.Response> _reintentar(Future<http.Response> Function() intento) async {
    try {
      return await intento();
    } on TimeoutException {
      throw const ErrorPago('sin_conexion', _mensajeSinConexion);
    } on http.ClientException {
      throw const ErrorPago('sin_conexion', _mensajeSinConexion);
    }
  }

  @override
  Future<ResultadoPago> resultado(PagoPendiente pendiente, RetornoPago retorno) async {
    // `retorno` no cambia la decisión: siempre se le pregunta al servidor.
    final url = Uri.parse('$_apiUrl/pagos/webpay/${Uri.encodeComponent(pendiente.numero)}');
    for (final espera in esperas) {
      await _esperar(espera);
      http.Response respuesta;
      try {
        respuesta = await _cliente.get(url, headers: {
          'Accept': 'application/json',
          'X-Token-Pago': pendiente.token,
        }).timeout(tiempoLimite);
      } on Exception {
        continue; // sin red o lento: no es un rechazo, se vuelve a preguntar
      }

      if (respuesta.statusCode == 404) {
        // El servidor no conoce ese pedido (o el token): no hay cobro posible.
        return const ResultadoPago.rechazado();
      }
      if (respuesta.statusCode != 200) continue;

      final decision = _leerEstado(respuesta, pendiente);
      if (decision != null) return decision;
    }
    return const ResultadoPago.sinConfirmar();
  }

  // ───────────────────────── lectura de respuestas ─────────────────────────

  Map<String, dynamic>? _datos(http.Response r) {
    try {
      final j = jsonDecode(utf8.decode(r.bodyBytes));
      if (j is Map && j['data'] is Map) return Map<String, dynamic>.from(j['data'] as Map);
    } catch (_) {}
    return null;
  }

  InicioPago? _leerInicio(http.Response r, SolicitudPago solicitud) {
    final d = _datos(r);
    if (d == null) return null;
    try {
      final numero = d['numero'];
      final token = d['token'];
      final total = d['total'];
      final url = Uri.parse(d['url'] as String);
      final urlFin = Uri.parse(d['urlFin'] as String);
      if (numero is! String || numero.isEmpty) return null;
      if (token is! String || token.isEmpty) return null;
      if (total is! int || total < 0) return null;
      if (!_esUrlWeb(url) || !_esUrlWeb(urlFin)) return null;
      return InicioPago(
        PagoPendiente(numero: numero, token: token, total: total, solicitud: solicitud, creado: DateTime.now()),
        redireccion: Redireccion(url: url, token: token, urlFin: urlFin),
      );
    } catch (_) {
      return null;
    }
  }

  bool _esUrlWeb(Uri u) => (u.scheme == 'https' || u.scheme == 'http') && u.host.isNotEmpty;

  ErrorPago _errorDelServidor(http.Response r) {
    try {
      final j = jsonDecode(utf8.decode(r.bodyBytes));
      if (j is Map) {
        final texto = j['error'];
        final codigo = j['code'];
        final total = j['total'];
        if (texto is String && texto.isNotEmpty) {
          return ErrorPago(
            codigo is String && codigo.isNotEmpty ? codigo : 'servidor',
            texto,
            totalNuevo: total is int ? total : null,
          );
        }
      }
    } catch (_) {}
    return const ErrorPago('servidor', _mensajeServidor);
  }

  /// Decide a partir de una respuesta 200 de la consulta. `null` = seguir preguntando.
  ResultadoPago? _leerEstado(http.Response r, PagoPendiente pendiente) {
    final d = _datos(r);
    if (d == null) return null;
    final estadoServidor = d['estado'];
    if (estadoServidor is! String) return null;
    final numero = d['numero'];
    if (numero != null && numero != pendiente.numero) return null; // respuesta de otro pedido

    switch (estadoServidor) {
      case 'aprobado':
        final total = d['total'];
        final correo = d['correo'];
        if (total is! int || correo is! String) return null;
        return ResultadoPago.aprobado(
          numero: pendiente.numero,
          total: total,
          correo: correo,
          retiro: d['retiro'] == true,
          comprobante: _leerComprobante(d['comprobante']),
        );
      case 'rechazado':
      case 'expirado':
        return const ResultadoPago.rechazado();
      case 'cancelado':
        return const ResultadoPago.cancelado();
      default: // 'pendiente' o un estado que no conocemos
        return null;
    }
  }

  ComprobantePago? _leerComprobante(Object? c) {
    if (c is! Map) return null;
    final codigo = c['codigoAutorizacion'];
    final ultimos = c['tarjetaUltimos4'];
    final tipo = c['tipoPago'];
    final cuotas = c['cuotas'];
    if (codigo is! String || ultimos is! String || tipo is! String || cuotas is! num) return null;
    final fecha = c['fecha'];
    return ComprobantePago(
      codigoAutorizacion: codigo,
      tarjetaUltimos4: ultimos,
      tipoPago: tipo,
      cuotas: cuotas.toInt(),
      fecha: fecha is String ? DateTime.tryParse(fecha) : null,
    );
  }

  /// 32 caracteres hexadecimales (128 bits) de `Random.secure`.
  static String _claveIdempotencia() {
    final azar = Random.secure();
    final sb = StringBuffer();
    for (var i = 0; i < 16; i++) {
      sb.write(azar.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return sb.toString();
  }
}
