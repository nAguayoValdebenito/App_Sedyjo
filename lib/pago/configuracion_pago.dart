import 'package:flutter/foundation.dart';

/// Cómo se procesa el pago: simulado (maqueta) o con Webpay Plus real.
enum ModoPago { simulado, webpay }

/// Configuración del pago, resuelta desde las banderas de compilación
/// `--dart-define=PAGO_MODO=simulado|webpay` y `--dart-define=API_URL=…`.
///
/// Precedencia: web (siempre simulado) → release móvil (siempre webpay)
/// → lo pedido (debug/profile; cualquier valor desconocido es simulado).
class ConfiguracionPago {
  const ConfiguracionPago({required this.modo, required this.apiUrl});

  factory ConfiguracionPago.resolver({
    String modo = const String.fromEnvironment(
      'PAGO_MODO',
      defaultValue: 'simulado',
    ),
    String apiUrl = const String.fromEnvironment('API_URL'),
    bool esWeb = kIsWeb,
    bool esRelease = kReleaseMode,
  }) {
    final ModoPago resuelto;
    if (esWeb) {
      resuelto = ModoPago.simulado;
    } else if (esRelease) {
      resuelto = ModoPago.webpay;
    } else {
      resuelto = modo == 'webpay' ? ModoPago.webpay : ModoPago.simulado;
    }
    return ConfiguracionPago(
      modo: resuelto,
      apiUrl: apiUrl.endsWith('/')
          ? apiUrl.substring(0, apiUrl.length - 1)
          : apiUrl,
    );
  }

  final ModoPago modo;

  /// URL base de la API, sin «/» final.
  final String apiUrl;

  /// Simulado, o webpay con una API configurada.
  bool get disponible => modo == ModoPago.simulado || apiUrl.isNotEmpty;
}
