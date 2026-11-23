# Pago con Webpay Plus en la app móvil: diseño

## Intención

Sedyjo cobrará con Webpay Plus de Transbank. Es la primera vez que se integra y el backend todavía no tiene nada de pagos. **Alcance de este trabajo: solo la app móvil (Flutter)**, dejada integrada y lista, más una guía para el encargado del backend. Cuando el backend esté listo y Transbank entregue el código de comercio de producción, activar el cobro real no debe requerir cambios de código en la app.

## Objetivos

- La app cobra con Webpay a través del backend, con el mismo diseño de resultado de pago que hoy.
- Funciona hoy sin backend (modo simulado) y cambia a Webpay solo con parámetros de compilación.
- Cero secretos en la app. El código de comercio y la llave secreta viven solo en el servidor.
- Ningún cobro se pierde ni se duplica: cierre de la app a mitad del pago, doble toque y mala conexión quedan cubiertos.
- La app muestra el comprobante con los datos que Transbank pide para validar un comercio.

## No objetivos

- Construir el backend de pagos (solo se documenta: `docs/backend-webpay.md`).
- Apple Pay / Google Pay, guardar tarjetas (OneClick), reembolsos desde la app.
- Compras digitales. Todo lo que vende Sedyjo es físico, por lo que las tiendas de aplicaciones permiten cobrar con pasarela propia.

## Anti-objetivos (fracasos aunque «funcione»)

- La app decide por sí sola que un pago fue aprobado (siempre pregunta al backend).
- Una versión de producción que cobre en modo simulado, o que pida pagar sin backend configurado y cree pedidos falsos.
- El carrito se vacía o el pedido se crea sin pago confirmado.

## Restricciones

- La app también se compila para web (maqueta de demostración): ahí el modo es siempre simulado (WebView no existe en web).
- El backend usa envoltorio `{ data }`, camelCase y errores `{ error, code, fields? }`; la app consume ese formato.
- Textos para el cliente en español, tuteo, sin jerga («Webpay», no «pasarela»).
- Estado guardado versionado (`versionDatos`): cualquier campo nuevo sube la versión y agrega migración.

## Enfoques considerados

| Enfoque | Cómo funciona | Costo |
|---|---|---|
| **A. WebView dentro de la app** (elegido) | La app pide iniciar el pago, abre Webpay en una pantalla propia (POST con `token_ws`), detecta la URL de fin y consulta el estado al backend | Una dependencia nueva (`webview_flutter`); hay que probar el 3D Secure de los bancos dentro del WebView |
| B. Navegador del sistema + enlace profundo | Abre Chrome/Safari y vuelve con `sedyjo://pago` | Enlaces profundos en Android e iOS, página intermedia en el backend, la app pierde el control si el cliente no vuelve |

Se eligió A (recomendación mía; el usuario pidió planificar sin objetar). Es lo habitual en el retail chileno y la más simple de mantener.

## Decisiones de diseño (mías, corregibles)

1. **Capa `PasarelaPago`** con tres implementaciones: `PasarelaSimulada` (comportamiento actual), `PasarelaWebpay` (HTTP al backend) y `PasarelaNoDisponible` (Webpay sin `API_URL`).
2. **Selección por parámetros de compilación:** `--dart-define=PAGO_MODO=simulado|webpay` y `--dart-define=API_URL=https://…/api/v1`. Reglas: web → siempre simulado; móvil en modo release → siempre Webpay (aunque pidan simulado); móvil en debug → lo pedido, por defecto simulado.
3. **Contrato con el backend** definido en `docs/backend-webpay.md` (iniciar, retorno, fin, consultar estado). El servidor calcula el total; la app envía `totalVisto` y maneja `precios_cambiaron` y `sin_stock`.
4. **El servidor manda:** tras volver de Webpay la app consulta `GET /pagos/webpay/{numero}` con reintentos (~16 s). Si no logra saberlo, el resultado es «sin confirmar», no «rechazado».
5. **Pago pendiente persistido:** al iniciar se guarda `PagoPendiente` (estado versión 3). Al abrir la app, si hay uno (menos de 24 h), se reanuda consultando. No se puede iniciar otro pago mientras hay uno sin resolver.
6. **El pedido local lo crea el resultado aprobado,** con el número que entregó el servidor y las líneas del pago (no las del carrito actual). Solo entonces se descuenta del carrito.
7. **Seguridad del WebView:** solo `https` en release (`http` solo en debug para el servidor de prueba local), se bloquean `intent://` y otros esquemas, se intercepta `urlFin` sin cargarla, salir con «atrás» pide confirmación.
8. **Resultado ampliado:** `ResultadoPago` suma `motivo` (`rechazado`, `cancelado`, `sinConfirmar`) y `comprobante`. Se quita el botón temporal «Probar pago rechazado» de la pantalla de pago (el interruptor del panel de la maqueta se mantiene).
9. **Servidor de prueba local** (`tools/webpay_falso.py`, solo biblioteca estándar de Python) que imita el contrato, para probar el flujo completo en un emulador antes de que exista el backend real.

## Queda para quien construya

Textos exactos de los mensajes nuevos (dentro de las reglas anteriores), estilos de las filas del comprobante (seguir `Panel` y `T.*` existentes) y la versión exacta de `webview_flutter`/`http` (la última compatible con Flutter 3.50).

## Pendiente del lado del negocio (no es código)

Políticas de cambios y devoluciones, datos de contacto y el logo de Webpay visibles en la app: Transbank los revisa al validar el comercio. Hay que redactarlos; la app solo necesita dónde mostrarlos (hoy existe `ayuda.dart`).
