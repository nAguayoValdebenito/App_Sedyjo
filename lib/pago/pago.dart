// Punto de entrada del pago: qué pasarela usar según la configuración y el flujo que usa la app.

import 'package:http/http.dart' as http;

import 'configuracion_pago.dart';
import 'flujo_pago.dart';
import 'pasarela_pago.dart';
import 'pasarela_webpay.dart';

/// Webpay con API → [PasarelaWebpay]; Webpay sin API → [PasarelaNoDisponible]; simulado → [PasarelaSimulada].
PasarelaPago crearPasarela(ConfiguracionPago c, {http.Client? cliente}) => switch (c.modo) {
      ModoPago.simulado => PasarelaSimulada(),
      ModoPago.webpay => c.apiUrl.isEmpty ? const PasarelaNoDisponible() : PasarelaWebpay(apiUrl: c.apiUrl, cliente: cliente),
    };

/// El flujo de pago de la app. Es variable (no `final`) para poder sustituirlo en pruebas.
FlujoPago flujoPago = FlujoPago(pasarela: crearPasarela(ConfiguracionPago.resolver()));
