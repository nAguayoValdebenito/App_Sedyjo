# Pago con Webpay en la app móvil: plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Dejar la app Flutter integrada con Webpay Plus a través del backend (contrato en `docs/backend-webpay.md`), funcionando hoy en modo simulado y lista para activarse solo con parámetros de compilación.

**Architecture:** Una capa `PasarelaPago` (simulada / Webpay por HTTP / no disponible) y un orquestador `FlujoPago` que inicia el pago, guarda un `PagoPendiente`, abre Webpay en un WebView, consulta el estado al backend y recién entonces crea el pedido local. `ResultadoPagoPantalla` sigue siendo la pantalla de resultado, ampliada con comprobante y dos casos nuevos (cancelado, sin confirmar).

**Tech Stack:** Flutter 3.50 / Dart, `webview_flutter`, `http` (con `MockClient` en pruebas), `shared_preferences` (ya existe). Servidor de prueba en Python (solo biblioteca estándar).

**Spec:** `docs/superpowers/specs/2026-11-16-pago-webpay-app-design.md` (decisiones) y `docs/backend-webpay.md` (contrato exacto con el backend).

## Global Constraints

- Parámetros de compilación: `--dart-define=PAGO_MODO=simulado|webpay` (por defecto `simulado`) y `--dart-define=API_URL=https://…/api/v1`.
- Web (maqueta) → siempre simulado. Móvil en release → siempre Webpay, aunque pidan `simulado`. Móvil en debug/profile → lo pedido.
- Cero secretos, códigos de comercio ni URLs de Transbank dentro de la app: la URL de Webpay llega en la respuesta del backend.
- Cabeceras: `Idempotency-Key` (32 caracteres hex, una por intento de pago) al iniciar; `X-Token-Pago` (el `token` de Webpay) al consultar. Respuestas `{ "data": … }`, errores `{ "error", "code", "total"? }`.
- La app nunca decide por sí sola que un pago fue aprobado: solo `estado == "aprobado"` del backend.
- Montos en CLP enteros. Textos al cliente en español, tuteo, «Webpay» (no «pasarela»); mensajes de fallo siempre dicen si se cobró o no.
- Estado guardado: `versionDatos` pasa de 2 a 3 con su paso en `PersistenciaEstado.migrar`.
- WebView: solo `https` en release (`http` únicamente en debug), se bloquean `intent://` y otros esquemas.
- Pruebas: `flutter test --concurrency=1 test/<archivo>` de a un archivo (el ejecutor de Windows a veces cae; repetir). `flutter analyze` debe quedar sin avisos nuevos.
- Código y pruebas en español, siguiendo el estilo existente (`lib/app`, `lib/pantallas`, `lib/ui`).

## Review Focus

Entradas y fallos que el diseño implica pero ninguna pantalla prueba por sí sola, del más probable al menos (cada uno tiene su prueba en la tarea indicada):

1. El cliente paga y la app se cierra o pierde la red antes de ver el resultado → al reabrir se reanuda y no se pierde ni duplica el pedido (Tareas 3, 8, 9).
2. Doble toque en «Pagar» o reintento tras un corte → una sola transacción y un solo pedido (Tareas 5 y 8).
3. El precio cambió entre el carrito y el pago, o se acabó el stock → se avisa antes de abrir Webpay y no se cobra (Tarea 8).
4. El cliente sale del WebView con «atrás» (o cancela) después de haber pagado en su banco → igual se consulta al backend y se respeta lo que diga (Tareas 5 y 8).
5. El backend responde 404, un estado desconocido o está caído → nunca se muestra «aprobado» sin confirmación ni «rechazado» si es solo falta de respuesta (Tarea 5).

---

## Mapa de archivos

| Archivo | Responsabilidad |
|---|---|
| `lib/pago/configuracion_pago.dart` (nuevo) | Leer `PAGO_MODO` y `API_URL` y aplicar las reglas por plataforma |
| `lib/pago/modelos_pago.dart` (nuevo) | `SolicitudPago`, `PagoPendiente`, `InicioPago`, `Redireccion`, `RetornoPago`, `ResultadoPago`, `MotivoNoPago`, `ComprobantePago`, `ErrorPago` |
| `lib/pago/pasarela_pago.dart` (nuevo) | Interfaz `PasarelaPago`, `PasarelaSimulada`, `PasarelaNoDisponible` |
| `lib/pago/pasarela_webpay.dart` (nuevo) | Cliente HTTP del contrato con el backend |
| `lib/pago/navegacion_webpay.dart` (nuevo) | Reglas puras de navegación del WebView y cuerpo del POST |
| `lib/pago/flujo_pago.dart` (nuevo) | Orquestación: iniciar, abrir Webpay, resultado, pedido local, reanudar |
| `lib/pago/pago.dart` (nuevo) | `crearPasarela` y la instancia global `flujoPago` |
| `lib/pantallas/webpay.dart` (nuevo) | Pantalla con el WebView |
| `lib/pantallas/pago_resultado.dart` | Cancelado, sin confirmar y comprobante; reexporta los modelos movidos |
| `lib/pantallas/checkout.dart` | Usa `flujoPago`; se quita el botón temporal |
| `lib/pantallas/shell.dart` | Reanuda un pago pendiente al abrir |
| `lib/app/estado/busqueda_pedidos_cuenta.dart`, `persistencia.dart`, `datos.dart` | `pagoPendiente`, `registrarPedido(numero, lineas)`, versión 3 |
| `tools/webpay_falso.py` (nuevo) | Servidor de prueba local que imita el contrato |
| `test/pago_*.dart` (nuevos) | Pruebas por unidad, ver cada tarea |

---

### Task 1: Dependencias, permiso de internet y configuración

**Files:**
- Modify: `pubspec.yaml`, `android/app/src/main/AndroidManifest.xml` (agregar `<uses-permission android:name="android.permission.INTERNET"/>` antes de `<application>`: hoy solo existe en debug/profile y una versión release no podría conectarse)
- Create: `lib/pago/configuracion_pago.dart`
- Test: `test/pago_configuracion_test.dart`

**Interfaces:**
- Produces:
  ```dart
  enum ModoPago { simulado, webpay }
  class ConfiguracionPago {
    const ConfiguracionPago({required this.modo, required this.apiUrl});
    factory ConfiguracionPago.resolver({
      String modo = const String.fromEnvironment('PAGO_MODO', defaultValue: 'simulado'),
      String apiUrl = const String.fromEnvironment('API_URL'),
      bool esWeb = kIsWeb, bool esRelease = kReleaseMode});
    final ModoPago modo; final String apiUrl; // apiUrl sin «/» final
    bool get disponible; // simulado, o webpay con apiUrl no vacía
  }
  ```

- [ ] **Step 1: Escribir las pruebas** en `test/pago_configuracion_test.dart`, una por regla:
  - web con `modo: 'webpay'` → `ModoPago.simulado`.
  - móvil release con `modo: 'simulado'` → `ModoPago.webpay`.
  - móvil debug: `'webpay'` → webpay, `'simulado'` → simulado, `'cualquier cosa'` → simulado.
  - `apiUrl: 'https://x.cl/api/v1/'` → `'https://x.cl/api/v1'`.
  - `disponible`: webpay con `apiUrl: ''` → `false`; webpay con URL → `true`; simulado → `true`.
- [ ] **Step 2: Correr y verificar que falla**: `flutter test --concurrency=1 test/pago_configuracion_test.dart` → falla por archivo/clase inexistente.
- [ ] **Step 3: Agregar dependencias**: `flutter pub add webview_flutter http` (toma la última compatible con Flutter 3.50) y el permiso `INTERNET` en el manifest principal.
- [ ] **Step 4: Implementar `ConfiguracionPago`** en `lib/pago/configuracion_pago.dart` con las reglas de la sección Global Constraints (precedencia: web → release → pedido).
- [ ] **Step 5: Correr la prueba**: debe pasar. Correr `flutter analyze` sin avisos nuevos.
- [ ] **Step 6: Commit**: `git add pubspec.yaml pubspec.lock android lib/pago test/pago_configuracion_test.dart && git commit -m "feat(pago): configuración de modo de pago y dependencias de Webpay"`

---

### Task 2: Modelos del pago

**Files:**
- Create: `lib/pago/modelos_pago.dart`
- Modify: `lib/pantallas/pago_resultado.dart` (quitar la clase `ResultadoPago` de ahí, importar `../pago/modelos_pago.dart` y reexportar con `export '../pago/modelos_pago.dart' show ResultadoPago, MotivoNoPago, ComprobantePago;` para que `test/pago_test.dart` y demás sigan compilando)
- Test: `test/pago_modelos_test.dart`

**Interfaces:**
- Produces (todo en `modelos_pago.dart`):
  ```dart
  enum RetornoPago { completado, cancelado, cerrado, desconocido }
  enum MotivoNoPago { rechazado, cancelado, sinConfirmar }

  class SolicitudPago {
    const SolicitudPago({required Map<int,int> lineas, required int totalVisto,
      required String nombre, required String correo, required String telefono,
      required bool retiro, required String direccion, String? franja, String? notas});
    Map<String,dynamic> aJsonApi();                  // cuerpo de POST /pagos/webpay
    Map<String,dynamic> toJson();                    // para guardar
    factory SolicitudPago.desdeJson(Map<String,dynamic> j);
    SolicitudPago conTotal(int totalVisto);
  }
  class Redireccion { const Redireccion({required Uri url, required String token, required Uri urlFin}); }
  class PagoPendiente {
    PagoPendiente({required String numero, required String token, required int total,
      required SolicitudPago solicitud, required DateTime creado});
    bool vencido(DateTime ahora); // más de 24 horas
    Map<String,dynamic> toJson(); factory PagoPendiente.desdeJson(Map<String,dynamic> j);
  }
  class InicioPago { const InicioPago(PagoPendiente pendiente, {Redireccion? redireccion}); }
  class ComprobantePago { const ComprobantePago({required String codigoAutorizacion,
    required String tarjetaUltimos4, required String tipoPago, required int cuotas, DateTime? fecha}); }
  class ResultadoPago { // mantiene la API actual y suma motivo/comprobante
    const ResultadoPago.aprobado({required String numero, required int total, required String correo, bool retiro = false, ComprobantePago? comprobante});
    const ResultadoPago.rechazado(); const ResultadoPago.cancelado(); const ResultadoPago.sinConfirmar();
    final bool aprobado; final MotivoNoPago? motivo; final String? numero; final int total;
    final String correo; final bool retiro; final ComprobantePago? comprobante;
  }
  class ErrorPago implements Exception { const ErrorPago(String codigo, String mensaje, {int? totalNuevo}); }
  ```

- [ ] **Step 1: Escribir las pruebas** en `test/pago_modelos_test.dart`:
  - `aJsonApi` de una solicitud (nombre `María González`, correo `maria@correo.cl`, teléfono `+56912345678`, domicilio `Los Aromos 1234, Concepción`, franja `Cualquier horario`, `notas: '  '`, `lineas: {12: 2}`, `totalVisto: 12140`) es exactamente `{'totalVisto': 12140, 'cliente': {…}, 'entrega': {'tipo': 'domicilio', 'direccion': 'Los Aromos 1234, Concepción', 'franja': 'Cualquier horario', 'notas': null}, 'items': [{'productoId': 12, 'cantidad': 2}]}`; con `retiro: true`, `tipo == 'retiro'`.
  - `PagoPendiente.desdeJson(p.toJson())` conserva número, token, total, líneas (claves enteras) y `creado`.
  - `vencido`: creado hace 25 h → `true`; hace 23 h → `false`.
  - `ResultadoPago`: `.rechazado().motivo == MotivoNoPago.rechazado`, `.cancelado().motivo == cancelado`, `.sinConfirmar().motivo == sinConfirmar`, los tres con `aprobado == false`; `.aprobado(...)` con `motivo == null` y `aprobado == true`.
- [ ] **Step 2: Correr y verificar que falla.**
- [ ] **Step 3: Implementar los modelos** según las firmas. `notas` vacío o solo espacios se envía como `null`.
- [ ] **Step 4: Mover `ResultadoPago`** desde `pago_resultado.dart` y reexportarlo; correr `flutter test --concurrency=1 test/pago_test.dart test/pago_modelos_test.dart` → pasan (el primero prueba que nada se rompió).
- [ ] **Step 5: Commit**: `git commit -m "feat(pago): modelos del pago y resultado ampliado"`

---

### Task 3: Estado: pago pendiente y pedido con número del servidor

**Files:**
- Modify: `lib/app/estado/busqueda_pedidos_cuenta.dart` (en `PedidosEstado`), `lib/app/estado/persistencia.dart`, `lib/app/datos.dart` (importar `../pago/modelos_pago.dart`)
- Test: `test/pago_estado_test.dart`

**Interfaces:**
- Consumes: `PagoPendiente` (Tarea 2).
- Produces, en `PedidosEstado`:
  ```dart
  PagoPendiente? pagoPendiente;
  void guardarPagoPendiente(PagoPendiente p);   // notifyListeners
  void limpiarPagoPendiente();                  // notifyListeners
  Pedido registrarPedido({required String correo, required String direccion, String? franja,
    String? notas, bool retiro = false, String? numero, Map<int,int>? lineas});
  ```
  Sin `numero` → `siguienteNumeroPedido`. Sin `lineas` → el carrito completo y se vacía (comportamiento actual). Con `lineas` → pedido con esas líneas; del carrito se resta cada cantidad pagada y se quita la entrada si queda en 0 o menos.
- `versionDatos = 3`; `aJson` agrega `'pagoPendiente'` (mapa o `null`); `restaurar` lo lee; `migrar` lleva v1/v2 a 3.

- [ ] **Step 1: Escribir las pruebas** en `test/pago_estado_test.dart` (en `tearDown`: `estado.carrito.clear(); estado.limpiarPagoPendiente();`):
  - `registrarPedido(numero: 'SED-10482', lineas: {1: 2}, …)` con `estado.carrito = {1: 3, 2: 1}` → `pedidos.first.numero == 'SED-10482'`, `pedidos.first.lineas == {1: 2}`, carrito `{1: 1, 2: 1}`.
  - Línea pagada completa (`carrito {1: 2}`, `lineas {1: 2}`) → el carrito queda vacío.
  - Sin `numero` ni `lineas` → número `siguienteNumeroPedido` y carrito vacío (compatibilidad).
  - `aJson()['v'] == 3`; guardar un `PagoPendiente`, `aJson` → `restaurar` en limpio → `estado.pagoPendiente?.numero` igual.
  - `PersistenciaEstado.migrar({'v': 2, …})['v'] == 3` y restaurar sin la clave `pagoPendiente` deja `null`.
- [ ] **Step 2: Correr y verificar que falla.**
- [ ] **Step 3: Implementar** los cambios de la sección Interfaces.
- [ ] **Step 4: Correr** `test/pago_estado_test.dart` y `test/comportamiento_test.dart` (cubre persistencia/pedidos existentes) → pasan.
- [ ] **Step 5: Commit**: `git commit -m "feat(pago): pago pendiente persistido y pedido con número del servidor"`

---

### Task 4: Interfaz `PasarelaPago`, simulada y no disponible

**Files:**
- Create: `lib/pago/pasarela_pago.dart`
- Test: `test/pago_pasarelas_test.dart`

**Interfaces:**
- Consumes: modelos (Tarea 2), `estado.siguienteNumeroPedido` y `estado.simulacionPago` (Tarea 3 / existente).
- Produces:
  ```dart
  abstract class PasarelaPago {
    Future<InicioPago> iniciar(SolicitudPago solicitud);              // puede lanzar ErrorPago
    Future<ResultadoPago> resultado(PagoPendiente pendiente, RetornoPago retorno);
  }
  class PasarelaSimulada implements PasarelaPago { PasarelaSimulada({Duration espera = const Duration(milliseconds: 600)}); }
  class PasarelaNoDisponible implements PasarelaPago { const PasarelaNoDisponible(); }
  ```
  `PasarelaSimulada.iniciar` devuelve `InicioPago` sin `redireccion`, con `numero = estado.siguienteNumeroPedido`, `token = 'simulado'`, `total = solicitud.totalVisto`. `resultado` espera `espera` y devuelve `rechazado()` si `estado.simulacionPago == SimulacionPago.rechazado`, si no `aprobado(numero, total, correo: solicitud.correo, retiro: solicitud.retiro)`. `PasarelaNoDisponible.iniciar` lanza `ErrorPago('no_disponible', 'El pago en línea no está disponible por ahora. Llámanos y tomamos tu pedido; no se cobró nada.')`; `resultado` devuelve `sinConfirmar()`.

- [ ] **Step 1: Escribir las pruebas**: simulada aprueba (`aprobado`, número `SED-…`, sin `redireccion`); con `estado.cambiarSimulacionPago(rechazado)` (restaurar en `addTearDown`) devuelve `motivo == rechazado`; `PasarelaNoDisponible().iniciar(...)` lanza `ErrorPago` con `codigo == 'no_disponible'`.
- [ ] **Step 2: Correr y verificar que falla.**
- [ ] **Step 3: Implementar.** Usar `espera: Duration.zero` en pruebas.
- [ ] **Step 4: Correr la prueba**: pasa.
- [ ] **Step 5: Commit**: `git commit -m "feat(pago): interfaz de pasarela, simulada y no disponible"`

---

### Task 5: `PasarelaWebpay` (cliente HTTP del contrato)

**Files:**
- Create: `lib/pago/pasarela_webpay.dart`
- Test: `test/pago_webpay_test.dart` (usa `package:http/testing.dart` `MockClient`)

**Interfaces:**
- Consumes: `PasarelaPago`, modelos.
- Produces:
  ```dart
  class PasarelaWebpay implements PasarelaPago {
    PasarelaWebpay({required String apiUrl, http.Client? cliente,
      Future<void> Function(Duration)? esperar,          // por defecto Future.delayed; las pruebas pasan (_) async {}
      Duration tiempoLimite = const Duration(seconds: 15),
      List<Duration> esperas = const [Duration.zero, 1s, 1s, 2s, 2s, 3s, 3s, 4s]});
  }
  ```
  Contrato en `docs/backend-webpay.md` §4.1 y §4.4.
  - `iniciar`: `POST {apiUrl}/pagos/webpay`, cuerpo `solicitud.aJsonApi()`, cabecera `Idempotency-Key` (32 hex con `Random.secure`). Ante `TimeoutException` o `http.ClientException` reintenta **una vez con la misma clave**. Éxito (200/201) → `InicioPago(PagoPendiente(numero, token, total del servidor, solicitud, creado ahora), redireccion: Redireccion(url, token, urlFin))`. 4xx → `ErrorPago(code, error, totalNuevo: total)` (con el texto `error` del servidor). 5xx o cuerpo ilegible → `ErrorPago('servidor', 'No pudimos iniciar el pago. No se cobró nada. Inténtalo de nuevo en un momento.')`. Sin red tras el reintento → `ErrorPago('sin_conexion', 'No pudimos conectar. Revisa tu conexión: no se cobró nada.')`.
  - `resultado`: recorre `esperas`; en cada vuelta espera y hace `GET {apiUrl}/pagos/webpay/{numero}` con `X-Token-Pago`. `aprobado` → `ResultadoPago.aprobado` con `comprobante`; `rechazado` o `expirado` → `rechazado()`; `cancelado` → `cancelado()`; `pendiente` o estado desconocido → sigue; **404 → `rechazado()`** (el servidor no conoce ese pedido: no hay cobro posible); otro código o excepción de red → sigue; al agotar las esperas → `sinConfirmar()`. El parámetro `retorno` no cambia la decisión (siempre se pregunta).

- [ ] **Step 1: Escribir las pruebas** en `test/pago_webpay_test.dart` (`apiUrl: 'https://api.test/v1'`, `esperar: (_) async {}`):
  1. `iniciar` hace `POST https://api.test/v1/pagos/webpay` con `jsonDecode(request.body) == solicitud.aJsonApi()` y cabecera `Idempotency-Key` que cumple `^[0-9a-f]{32}$`; con la respuesta `201 {"data": {"numero": "SED-10482", "token": "T…64", "url": "https://webpay3gint.transbank.cl/webpayserver/initTransaction", "urlFin": "https://api.test/v1/pagos/webpay/fin", "total": 12140}}` devuelve `pendiente.numero == 'SED-10482'`, `pendiente.total == 12140`, `redireccion.url`, `token` y `urlFin` correctos.
  2. `409 {"error": "Los precios cambiaron", "code": "precios_cambiaron", "total": 12500}` → `ErrorPago` con `codigo == 'precios_cambiaron'` y `totalNuevo == 12500`.
  3. `409 sin_stock` → `ErrorPago.mensaje` es el `error` del servidor.
  4. Primer intento lanza `TimeoutException`, segundo responde 201 → éxito, 2 llamadas, **misma** `Idempotency-Key` en ambas.
  5. Dos fallos de red seguidos → `ErrorPago('sin_conexion', …)`; respuesta 500 → `ErrorPago('servidor', …)`.
  6. `resultado`: pendiente, pendiente, aprobado con comprobante `{codigoAutorizacion: '1213', tarjetaUltimos4: '6623', tipoPago: 'Crédito', cuotas: 0, fecha: '2026-11-16T20:15:00Z'}` → `aprobado`, `numero`, `total`, `correo` y comprobante correctos; 3 GET; cada uno con `X-Token-Pago == pendiente.token`.
  7. `rechazado` y `expirado` → `motivo == rechazado`; `cancelado` → `motivo == cancelado`.
  8. Con `retorno: RetornoPago.cerrado` y el servidor diciendo `aprobado` → `aprobado` (el servidor manda).
  9. Siempre `pendiente` → `sinConfirmar` tras exactamente `esperas.length` consultas.
  10. 404 → `rechazado`; 503 y luego `aprobado` → `aprobado`; estado desconocido `"raro"` en todas las vueltas → `sinConfirmar`.
- [ ] **Step 2: Correr y verificar que falla.**
- [ ] **Step 3: Implementar `PasarelaWebpay`** según Interfaces. Nunca registrar (`print`/`debugPrint`) el token ni los datos del cliente.
- [ ] **Step 4: Correr la prueba**: pasa.
- [ ] **Step 5: Commit**: `git commit -m "feat(pago): cliente HTTP de Webpay con reintentos idempotentes y consulta de estado"`

---

### Task 6: Pantalla del WebView y reglas de navegación

**Files:**
- Create: `lib/pago/navegacion_webpay.dart`, `lib/pantallas/webpay.dart`
- Test: `test/pago_navegacion_test.dart`

**Interfaces:**
- Consumes: `Redireccion`, `RetornoPago`.
- Produces:
  ```dart
  enum DecisionNavegacion { permitir, terminar, bloquear }
  DecisionNavegacion decidirNavegacion(Uri destino, Uri urlFin, {bool permitirHttp = false});
  Uint8List cuerpoFormulario(String token);        // utf8 de 'token_ws=<token codificado>'
  class WebpayPantalla extends StatefulWidget { const WebpayPantalla({super.key, required Redireccion redireccion}); }
  // WebpayPantalla se cierra con Navigator.pop<RetornoPago>(…)
  ```
  Reglas de `decidirNavegacion`: mismo `host` y `path` que `urlFin` (se ignora esquema y query) → `terminar` (se evalúa primero); `https` → `permitir`; `http` → `permitir` solo con `permitirHttp`, si no `bloquear`; `about:blank` → `permitir`; cualquier otro esquema (`intent`, `market`, `file`, `javascript`, `data`…) → `bloquear`.
  `WebpayPantalla`: barra propia con título «Pago con Webpay», ícono de candado y botón «✕» (`LucideIcons.x`); `WebViewController` con JavaScript sin restricción; `loadRequest(redireccion.url, method: LoadRequestMethod.post, headers: {'Content-Type': 'application/x-www-form-urlencoded'}, body: cuerpoFormulario(redireccion.token))`; `NavigationDelegate.onNavigationRequest` usa `decidirNavegacion(…, permitirHttp: kDebugMode)`: `terminar` → impide la navegación y hace `pop(RetornoPago.completado)`; barra de progreso mientras carga; si falla la carga de la página principal, panel «No pudimos cargar Webpay» con «Reintentar» y «Cerrar». «Atrás» del sistema y «✕» abren un diálogo «¿Salir del pago?» («Si sales ahora no se te cobrará, salvo que ya hayas confirmado en tu banco. Revisaremos cómo quedó.») con «Seguir pagando» / «Salir»; «Salir» hace `pop(RetornoPago.cerrado)`.

- [ ] **Step 1: Escribir las pruebas** en `test/pago_navegacion_test.dart` (`urlFin = https://api.sedyjo.com/api/v1/pagos/webpay/fin`):
  - `…/pagos/webpay/fin?numero=SED-10482` → `terminar`; la misma ruta con `http://` → `terminar`.
  - `https://webpay3gint.transbank.cl/webpayserver/initTransaction` y `https://acs.banco.cl/3ds` → `permitir`.
  - `http://acs.banco.cl` → `bloquear`; con `permitirHttp: true` → `permitir`.
  - `intent://x#Intent;scheme=https;end`, `market://details?id=x`, `file:///etc/passwd`, `javascript:alert(1)` → `bloquear`; `about:blank` → `permitir`.
  - `utf8.decode(cuerpoFormulario('abc+/=='))` es `token_ws=abc%2B%2F%3D%3D`.
- [ ] **Step 2: Correr y verificar que falla.**
- [ ] **Step 3: Implementar** `navegacion_webpay.dart` y luego `webpay.dart` (usa los componentes y tokens de `lib/ui` y `tema.dart` como el resto de las pantallas).
- [ ] **Step 4: Correr la prueba** (pasa) y `flutter analyze` (sin avisos). El WebView mismo no tiene prueba automática (es una vista nativa); se verifica a mano en la Tarea 10.
- [ ] **Step 5: Commit**: `git commit -m "feat(pago): pantalla de Webpay con WebView y reglas de navegación seguras"`

---

### Task 7: Pantalla de resultado: cancelado, sin confirmar y comprobante

**Files:**
- Modify: `lib/pantallas/pago_resultado.dart`
- Test: `test/pago_test.dart` (agregar casos a los existentes)

**Interfaces:**
- Consumes: `ResultadoPago.motivo`, `ComprobantePago` (Tarea 2).
- Produces: `ResultadoPagoPantalla({super.key, Future<ResultadoPago> Function()? procesar, ResultadoPago? resultado, VoidCallback? alRevisarDeNuevo})`; `Sello` suma `sinConfirmar` (disco `C.grisMedio` con una marca «!»; extender `_PintorSello` para recibir el `Sello` en vez de `aprobado`/`relleno`). La pantalla no permite salir mientras `procesar` corre (como hoy).
- Textos:
  - Cancelado: título «Cancelaste el pago», cuerpo «No te cobramos nada y tus productos siguen en el carrito. Puedes intentarlo de nuevo.»; mismos botones que el rechazado.
  - Sin confirmar: título «Estamos confirmando tu pago», cuerpo «No pudimos saber cómo terminó. Si tu banco te cobró, tu pedido aparecerá en Mis pedidos. No pagues de nuevo todavía.»; botones «Revisar de nuevo» (llama `alRevisarDeNuevo`; oculto si es `null`), «Volver al inicio» y «Llamar para recibir ayuda».
  - Aprobado con `comprobante`: panel «Comprobante de pago» con filas «Número de pedido», «Monto», «Código de autorización», «Tarjeta» (`•••• 6623`), «Tipo de pago», «Cuotas» («Sin cuotas» si 0, si no «N cuotas») y «Fecha» (hora de Chile `dd/mm/aaaa HH:mm`); sin `comprobante` no se muestra el panel.

- [ ] **Step 1: Escribir las pruebas** (mismo estilo de `test/pago_test.dart`, helpers `app`, `telefono`, `esperar`):
  - cancelado: tras ~4 s aparecen «Cancelaste el pago», «No te cobramos nada» e «Intentar de nuevo»; `sello(t) == Sello.rechazado` durante el sello.
  - sin confirmar: `sello(t) == Sello.sinConfirmar`; aparecen «Estamos confirmando tu pago» y «No pagues de nuevo»; tocar «Revisar de nuevo» llama `alRevisarDeNuevo` exactamente una vez; sin callback no hay botón.
  - aprobado con comprobante (`'1213'`, `'6623'`, `'Crédito'`, `cuotas: 0`): se ven «Código de autorización», `1213`, `•••• 6623`, «Crédito» y «Sin cuotas»; con `cuotas: 3` se ve «3 cuotas».
  - aprobado sin comprobante: `find.text('Código de autorización')` no encuentra nada.
- [ ] **Step 2: Correr y verificar que fallan** solo los casos nuevos: `flutter test --concurrency=1 test/pago_test.dart`.
- [ ] **Step 3: Implementar** los cambios de Interfaces.
- [ ] **Step 4: Correr** `test/pago_test.dart` completo y `test/goldens_test.dart` (si los goldens cambian por esta pantalla, revisar la diferencia y regenerarlos solo si el cambio es el esperado).
- [ ] **Step 5: Commit**: `git commit -m "feat(pago): resultado cancelado, sin confirmar y comprobante de pago"`

---

### Task 8: `FlujoPago` y conexión con el checkout

**Files:**
- Create: `lib/pago/flujo_pago.dart`, `lib/pago/pago.dart`
- Modify: `lib/pantallas/checkout.dart` (`_pagar` y quitar el panel «Solo para pruebas» con el botón «Probar pago rechazado»)
- Test: `test/pago_flujo_test.dart`

**Interfaces:**
- Consumes: `PasarelaPago`, `SolicitudPago`, `WebpayPantalla`, `ResultadoPagoPantalla`, `estado`, `Memoria.guardarYa()`.
- Produces:
  ```dart
  class FlujoPago {
    FlujoPago({required PasarelaPago pasarela,
      Future<RetornoPago> Function(BuildContext, Redireccion)? abrirWebpay}); // por defecto empuja WebpayPantalla; null del pop → RetornoPago.cerrado
    Future<void> pagar(BuildContext context, SolicitudPago solicitud);
    Future<void> reanudarSiHay(BuildContext context);       // Tarea 9
  }
  // pago.dart:
  PasarelaPago crearPasarela(ConfiguracionPago c, {http.Client? cliente});   // webpay+apiUrl → PasarelaWebpay; webpay sin URL → PasarelaNoDisponible; simulado → PasarelaSimulada
  FlujoPago flujoPago = FlujoPago(pasarela: crearPasarela(ConfiguracionPago.resolver()));   // variable (no final) para poder sustituirla en pruebas
  ```
  Algoritmo de `pagar`:
  1. Si ya hay un pago en curso en este `FlujoPago`, ignorar (doble toque). Si `estado.pagoPendiente != null` → `reanudarSiHay` y terminar.
  2. `pasarela.iniciar(solicitud)`. `ErrorPago` con `codigo == 'precios_cambiaron'` y `totalNuevo` → diálogo «Cambió el total» («Los precios se actualizaron. Tu total ahora es {clp(totalNuevo)}. ¿Quieres continuar?», «Continuar» / «Volver al carrito»); «Continuar» reintenta una vez con `solicitud.conTotal(totalNuevo)`. Cualquier otro `ErrorPago` → diálogo «No pudimos iniciar el pago» con `mensaje` y «Entendido»; no se guarda nada.
  3. `estado.guardarPagoPendiente(inicio.pendiente)` y `await Memoria.guardarYa()` **antes** de abrir Webpay.
  4. `retorno = inicio.redireccion == null ? RetornoPago.completado : await abrirWebpay(context, inicio.redireccion!)`.
  5. Empujar `ResultadoPagoPantalla(procesar: () => _cerrar(inicio.pendiente, retorno))`. `_cerrar`: `r = await pasarela.resultado(p, retorno)`; si `r.aprobado` y no existe ya un pedido con ese número → `estado.registrarPedido(numero: r.numero ?? p.numero, lineas: p.solicitud.lineas, correo/direccion/franja/notas/retiro de la solicitud)`; si `r.aprobado` o `r.motivo != sinConfirmar` → `estado.limpiarPagoPendiente()`; con `sinConfirmar` el pendiente se conserva. Comprobar `context.mounted` tras cada espera.
  `CheckoutPantalla._pagar` arma `SolicitudPago` con `lineas: Map.of(estado.carrito)`, `totalVisto: estado.subtotal`, nombre, correo, teléfono, retiro, dirección (`tienda.direccionCompleta` si retiro, si no `'${_dir!.calle}, ${_dir!.comuna}'`), franja (`tienda.plazo` si retiro) y notas; mantiene `_pagando` y el texto «Conectando con Webpay…».

- [ ] **Step 1: Escribir las pruebas** en `test/pago_flujo_test.dart` con un `FakePasarela` (configurable: `iniciar` devuelve `InicioPago` o lanza `ErrorPago`; `resultado` devuelve lo pedido y cuenta llamadas), `abrirWebpay` falso que devuelve `RetornoPago.completado` y registra su llamada, `SharedPreferences.setMockInitialValues({})` en `setUpAll`, y una app mínima con un botón que llama `flujo.pagar(context, solicitud)` (carrito inicial `{1: 2, 2: 1}`, líneas pagadas `{1: 2}`):
  1. Aprobado: pedido registrado con el número del servidor `SED-10482` y líneas `{1: 2}`, carrito `{2: 1}`, `pagoPendiente == null`, se ve «Seguir mi pedido».
  2. Rechazado: sin pedido nuevo, carrito intacto, `pagoPendiente == null`.
  3. Cancelado (el `abrirWebpay` devuelve `RetornoPago.cerrado` y la pasarela responde `cancelado()`): se ve «Cancelaste el pago»; y la pasarela **sí** fue consultada.
  4. Sin confirmar: `pagoPendiente != null`, carrito intacto, se ve «Estamos confirmando tu pago».
  5. `ErrorPago('servidor', 'No pudimos…')` al iniciar: se ve el diálogo con el mensaje, `pagoPendiente == null`, `abrirWebpay` no se llamó.
  6. `precios_cambiaron` con `totalNuevo: 12500`: diálogo con «$12.500» (formato de `clp`); «Continuar» → `iniciar` se llama por segunda vez con `totalVisto == 12500`; «Volver al carrito» → no hay segunda llamada y nada pendiente.
  7. Dentro de `abrirWebpay` ya existe `estado.pagoPendiente?.numero == 'SED-10482'` (se guardó antes de salir).
  8. Con un pendiente ya guardado, `pagar` no llama `iniciar` y consulta `resultado` (reanuda).
  9. Pasarela simulada (sin `redireccion`): `abrirWebpay` no se llama.
  10. Doble toque: dos `pagar` casi simultáneos → `iniciar` se llama una sola vez.
- [ ] **Step 2: Correr y verificar que falla.**
- [ ] **Step 3: Implementar `flujo_pago.dart` y `pago.dart`**, y adaptar `checkout.dart` (quitar `forzarRechazo`, el panel de pruebas y la lógica `Future.delayed`/`registrarPedido` que había en `_pagar`).
- [ ] **Step 4: Correr** `test/pago_flujo_test.dart`, `test/pago_test.dart` y `test/pantallas_claro_test.dart` (el checkout sigue armándose).
- [ ] **Step 5: Commit**: `git commit -m "feat(pago): flujo de pago con Webpay conectado al checkout"`

---

### Task 9: Reanudar un pago pendiente al abrir la app

**Files:**
- Modify: `lib/pago/flujo_pago.dart` (completar `reanudarSiHay`), `lib/pantallas/shell.dart` (`_ShellState.initState`: tras el primer cuadro, `if (mounted) flujoPago.reanudarSiHay(context)`)
- Test: `test/pago_flujo_test.dart` (agregar casos)

**Interfaces:**
- Consumes: todo lo de la Tarea 8.
- Produces: `reanudarSiHay`: sin pendiente → no hace nada; pendiente `vencido(ahora)` (más de 24 h) → se limpia sin consultar ni navegar; si no → empuja `ResultadoPagoPantalla(procesar: () => _cerrar(p, RetornoPago.desconocido), alRevisarDeNuevo: () { cerrar la pantalla y volver a llamar a reanudarSiHay })`. `pagar` pasa el mismo `alRevisarDeNuevo` cuando el resultado es «sin confirmar». Ignora llamadas mientras hay otro flujo en curso.

- [ ] **Step 1: Escribir las pruebas** (se suman a `pago_flujo_test.dart`):
  - Pendiente guardado + la pasarela responde `aprobado` → se registra el pedido con las líneas guardadas y se ve «Seguir mi pedido».
  - Pendiente guardado cuyo pedido ya existe en `estado.pedidos` (el pago se aprobó pero la app murió antes de limpiar) → no se duplica el pedido y el pendiente queda en `null`.
  - Pendiente creado hace 25 h → `resultado` no se llama, `pagoPendiente == null`, no se empujó ninguna ruta.
  - Sin pendiente → no se empuja ninguna ruta.
  - Resultado «sin confirmar» y toque en «Revisar de nuevo» → `resultado` se llama de nuevo y, si ahora es `aprobado`, se ve «Seguir mi pedido».
- [ ] **Step 2: Correr y verificar que falla.**
- [ ] **Step 3: Implementar** `reanudarSiHay` y el gancho en `Shell`.
- [ ] **Step 4: Correr** `test/pago_flujo_test.dart` y `test/pantallas_claro_test.dart` (el `Shell` sigue armándose y no hace nada sin pendiente).
- [ ] **Step 5: Commit**: `git commit -m "feat(pago): reanudar un pago pendiente al abrir la app"`

---

### Task 10: Servidor de prueba local y verificación manual de punta a punta

**Files:**
- Create: `tools/webpay_falso.py` (solo biblioteca estándar; no forma parte de `api/`)
- Modify: `android/app/src/debug/AndroidManifest.xml` (agregar `android:usesCleartextTraffic="true"` en `<application>` **solo debug**, para hablar con el servidor de prueba por `http` desde el emulador)

**Interfaces:**
- Produces: `python tools/webpay_falso.py [--puerto 8080] [--precios-cambian]` que implementa el contrato de `docs/backend-webpay.md` §4 en memoria:
  - `POST /api/v1/pagos/webpay` → pedido `SED-90001`, `SED-90002`…; token de 64 hex; `url` = `http://<host>/falso/webpay`; `urlFin` = `http://<host>/api/v1/pagos/webpay/fin`; `total = totalVisto`; misma respuesta para la misma `Idempotency-Key`. Con `--precios-cambian`, la primera vez responde `409 precios_cambiaron` con `total = totalVisto + 500`.
  - `POST /falso/webpay` (recibe `token_ws`) → página con tres botones: «Aprobar (VISA 6623)», «Rechazar» y «Cancelar», que envían a `/api/v1/pagos/webpay/retorno` (`token_ws` en los dos primeros con `resultado=aprobar|rechazar`; `TBK_TOKEN` + `TBK_ORDEN_COMPRA` al cancelar).
  - `GET|POST /api/v1/pagos/webpay/retorno` → fija el estado (`aprobado` con comprobante de ejemplo, `rechazado` o `cancelado`) y responde `302` a `urlFin?numero=…`.
  - `GET /api/v1/pagos/webpay/fin` → página mínima.
  - `GET /api/v1/pagos/webpay/{numero}` con `X-Token-Pago` válido → `{ "data": … }`; sin token válido → 404. Mientras el cliente no vuelve de Webpay el estado es `pendiente`.

- [ ] **Step 1: Escribir `tools/webpay_falso.py`** según Interfaces y agregar el atributo al manifest de debug.
- [ ] **Step 2: Levantar el servidor**: `python tools/webpay_falso.py --puerto 8080`. Verificar con `curl -s -X POST http://127.0.0.1:8080/api/v1/pagos/webpay -H "Content-Type: application/json" -H "Idempotency-Key: 00000000000000000000000000000001" -d "{\"totalVisto\":1000,\"cliente\":{},\"entrega\":{},\"items\":[]}"` → devuelve `numero`, `token`, `url` y `urlFin`.
- [ ] **Step 3: Probar en un emulador Android**: `flutter run --dart-define=PAGO_MODO=webpay --dart-define=API_URL=http://10.0.2.2:8080/api/v1`. Casos, con resultado esperado:
  1. Comprar y «Aprobar» → círculo verde, pedido con número `SED-9000X`, comprobante visible, carrito vacío.
  2. «Rechazar» → «El pago no se completó», carrito intacto.
  3. «Cancelar» → «Cancelaste el pago», carrito intacto.
  4. Cerrar con «✕» → confirmación «¿Salir del pago?»; «Salir» → resultado coherente con el estado del servidor.
  5. Matar la app mientras está en la página de pago, reabrirla → se reanuda sola: «Estamos confirmando tu pago» o el resultado final, sin duplicar pedidos.
  6. Apagar el servidor antes de tocar «Pagar» → «No pudimos conectar… no se cobró nada» y el botón vuelve a estar disponible.
  7. Con `--precios-cambian` → diálogo «Cambió el total»; «Continuar» abre Webpay.
  8. Doble toque rápido en «Pagar» → un solo pedido en el servidor (revisar la consola del servidor de prueba).
- [ ] **Step 4: Anotar** en `docs/PROGRESO.md` los casos probados y los pendientes. iOS no se puede probar en esta máquina (Windows): queda como pendiente en un Mac, con el backend real por `https` y antes de enviar a la App Store.
- [ ] **Step 5: Commit**: `git commit -m "feat(pago): servidor de prueba local de Webpay y verificación de punta a punta"`

---

### Task 11: Documentación y verificación final

**Files:**
- Modify: `docs/integraciones.md` (tabla de paquetes: `webview_flutter`, `http`; fila «Pago» pasa a «Webpay vía backend (`lib/pago/`), simulado por defecto»; nueva sección «Pago con Webpay» con los parámetros `PAGO_MODO` y `API_URL` y la regla por plataforma; enlazar `docs/backend-webpay.md`), `README.md` (comandos `flutter run` con los parámetros, estructura `lib/pago/`), `docs/PROGRESO.md` (resumen)

- [ ] **Step 1: Actualizar la documentación** según la lista. Revisar que `docs/backend-webpay.md` coincide con lo que implementaron las Tareas 5 y 10 (nombres de campos, cabeceras, códigos de error); corregir donde difiera.
- [ ] **Step 2: Verificación completa**:
  - `flutter analyze` → sin avisos.
  - `flutter test --concurrency=1` → todo pasa (si el ejecutor de Windows cae, repetir de a un archivo).
  - `flutter build apk --debug` → compila con el plugin de WebView (si pide subir `minSdk`, hacerlo en `android/app/build.gradle.kts` y anotarlo).
  - `flutter build web --release --no-web-resources-cdn` → compila (la maqueta web sigue en modo simulado).
  - Buscar en `lib/` el texto «Probar pago rechazado» → no debe aparecer.
- [ ] **Step 3: Commit**: `git commit -m "docs(pago): integración de Webpay en la app y guía para el backend"`
