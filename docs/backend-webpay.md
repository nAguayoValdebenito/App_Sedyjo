# Webpay Plus: qué debe hacer el backend

Para el encargado del backend de Sedyjo (Node/Fastify). Es la **primera vez** que Sedyjo cobra con Transbank, así que esta guía parte de cero. La app móvil ya queda lista para usar este contrato; mientras el backend no exista funciona en modo simulado.

## 1. Por qué el cobro vive en el servidor

Webpay Plus se maneja con una **llave secreta** que nunca puede ir dentro de la app (cualquiera podría extraerla). Por eso:

- El backend crea la transacción en Transbank y la **confirma (commit)** al volver el cliente.
- La app solo abre la página de pago de Webpay en una pantalla propia y, al terminar, **le pregunta al backend** cómo quedó. La app nunca decide si un pago fue aprobado.
- El backend es quien calcula el total con los precios reales. La app envía el total que el cliente vio (`totalVisto`) solo para detectar diferencias.

## 2. Credenciales y entornos

Todo por variables de entorno. **Pasar a producción es cambiar estas tres variables; la app no se toca ni se recompila.**

| Variable | Integración (pruebas) | Producción |
|---|---|---|
| `TBK_ENTORNO` | `integracion` | `produccion` |
| `TBK_CODIGO_COMERCIO` | `597055555532` | el código que entrega Transbank al validar el comercio |
| `TBK_LLAVE_SECRETA` | `579B532A7440BB0C9079DED94D31EA1615BACEB56610332264630D42D0A36B1C` | la llave secreta que entrega Transbank |

- Valores de integración: documentación oficial de Transbank (transbankdevelopers.cl, «Cómo empezar»). Son públicos y solo sirven en integración.
- URLs base: integración `https://webpay3gint.transbank.cl`, producción `https://webpay3g.transbank.cl`.
- Usar el SDK oficial `transbank-sdk` (Node) o la API REST `…/rswebpaytransaction/api/webpay/v1.2/transactions` con las cabeceras `Tbk-Api-Key-Id` y `Tbk-Api-Key-Secret`.
- La llave secreta **solo** en variables de entorno del servidor: nunca en el repositorio, en logs ni en respuestas.
- Tarjetas de prueba (integración, fecha futura cualquiera): VISA `4051 8856 0044 6623` CVV `123` aprueba; MASTERCARD `5186 0595 5959 0568` CVV `123` rechaza. Si pide RUT y clave: `11.111.111-1` y `123`.

## 3. Formato

Igual que el resto de las APIs de Sedyjo: JSON, CLP en enteros, fechas ISO 8601 UTC, respuestas `{ "data": … }` en camelCase y errores `{ "error": "texto para mostrar", "code": "…", "fields"?: … }` (cualquier campo extra va al **mismo nivel** que `error`, no dentro de `data`). Prefijo `/api/v1`.

## 4. Endpoints que la app usa

### 4.1 `POST /pagos/webpay` — iniciar el pago

Cabeceras: `Content-Type: application/json` e `Idempotency-Key: <32 caracteres hex>` (la app genera una por intento; reintentar con la misma clave **debe devolver el mismo resultado sin crear otro pedido ni otra transacción**).

```json
{
  "totalVisto": 12140,
  "cliente": { "nombre": "María González", "correo": "maria@correo.cl", "telefono": "+56912345678" },
  "entrega": { "tipo": "domicilio", "direccion": "Los Aromos 1234, Concepción", "franja": "Cualquier horario", "notas": null },
  "items": [ { "productoId": 12, "cantidad": 2 } ]
}
```

`entrega.tipo` es `domicilio` o `retiro` (con `retiro`, `direccion` trae la dirección del local). `franja` y `notas` pueden venir `null`.

**Despacho (decisión pendiente del negocio):** hoy `totalVisto` es **solo productos, sin despacho** (en la app es `estado.subtotal`; el checkout dice «Despacho: se confirma al pagar»), y el `total` de la respuesta debe calcularse igual: solo productos. Si el backend sumara el despacho, todo pedido bajo el mínimo de despacho gratis recibiría `precios_cambiaron`. Si el negocio decide cobrar el despacho en Webpay, hay que cambiar la app y este contrato a la vez.

Una lista `items` vacía responde `400` (con `error`). Una petición con una `Idempotency-Key` que **todavía se está procesando** (la primera no ha respondido) no debe crear una segunda transacción: hay que bloquear por clave (esperar a que termine la primera y devolver su respuesta, o responder un error `409` sin crear nada).

La app espera la respuesta hasta 15 segundos. Si no llega nada (tiempo agotado, sin conexión o un error de TLS), **reintenta una sola vez con la misma `Idempotency-Key`**; por eso la idempotencia no es opcional. Si el segundo intento también falla, le dice al cliente que no se cobró nada.

El backend:
1. Valida productos, stock y cobertura, y **calcula el total** con precios y ofertas vigentes.
2. Si el total no coincide con `totalVisto` → `409` con `code: "precios_cambiaron"` y el campo extra `total` (el total real, **entero y al mismo nivel que `error` y `code`**, p. ej. `{ "error": "…", "code": "precios_cambiaron", "total": 12640 }`). Sin `total` entero la app lo trata como un error común y no ofrece continuar. Con él, le pregunta al cliente si continúa y, si acepta, hace **un solo reintento nuevo**: otra `Idempotency-Key` y `totalVisto` = el `total` recibido (es otra solicitud, no una repetición: no hay que devolver el `409` guardado).
3. Sin stock → `409` `code: "sin_stock"` con `error` listo para mostrar («No queda stock de …»).
4. Crea el pedido en estado `pendiente_pago` (con número `SED-10482`; sirve como `buy_order`, máximo 26 caracteres, sin tildes) y la transacción en Webpay con `return_url = <API>/pagos/webpay/retorno`, `amount = total`, `session_id` = id interno.
5. Responde `201`:

```json
{ "data": {
  "numero": "SED-10482",
  "token": "<token de 64 caracteres de Transbank>",
  "url": "https://webpay3gint.transbank.cl/webpayserver/initTransaction",
  "urlFin": "https://api.sedyjo.com/api/v1/pagos/webpay/fin",
  "total": 12140
} }
```

`url` es la que devuelve Transbank (cambia sola entre integración y producción). La app la abre con un `POST` `application/x-www-form-urlencoded` y cuerpo `token_ws=<token>`.

`urlFin` es la dirección que la app detecta para saber que el cliente volvió (ver 4.2). Se compara **host y ruta** (se ignoran esquema, query y barra final): el `Location` del `302` de 4.2 debe ser esa misma dirección con la query que se quiera (`?numero=…`). No es un prefijo: una ruta más larga no cuenta.

Lo que la app exige a la respuesta `200`/`201` (si falta algo, muestra «No pudimos iniciar el pago. No se cobró nada.»): `data.numero` y `data.token` con texto no vacío, `data.total` entero, y `data.url` y `data.urlFin` direcciones `http(s)` con host. Fuera del desarrollo deben ser `https`: solo una compilación **debug** de la app acepta `http`; **profile y release lo bloquean**.

Errores: cualquier `4xx` con `error` (texto no vacío) se muestra tal cual al cliente (`error` debe ser apto para mostrar). `code` es **recomendado** (la app lo usa para reconocer `precios_cambiaron`), pero la app solo exige `error`. Un `5xx`, o una respuesta que no sea JSON con ese formato, se muestra como el mensaje genérico anterior.

### 4.2 `GET|POST /pagos/webpay/retorno` — vuelta desde Webpay (la llama Transbank a través del navegador del cliente)

Aceptar **GET y POST**. Según lo que llegue:

| Llega | Significa | El backend hace |
|---|---|---|
| solo `token_ws` | El cliente pagó o fue rechazado | **Confirmar de inmediato** (`commit`). `response_code = 0` y `status = AUTHORIZED` → pedido `pagado`; cualquier otro → `rechazado` |
| `TBK_TOKEN` + `TBK_ORDEN_COMPRA` + `TBK_ID_SESION` (sin `token_ws`) | El cliente canceló en Webpay | Pedido `cancelado`. No se confirma nada |
| solo `TBK_ORDEN_COMPRA` + `TBK_ID_SESION` (sin tokens) | Se acabó el tiempo en el formulario | Pedido `expirado` |
| `token_ws` + `TBK_TOKEN` | Error en el formulario de pago | No confirmar; consultar el estado a Transbank y dejar el pedido `rechazado` |

> Esta tabla sale de la documentación de Transbank tal como la conocemos; **confirmar los parámetros exactos en transbankdevelopers.cl («Webpay Plus» → flujo de retorno)** antes de implementarla.

Al pasar a `pagado` (y solo entonces): enviar el correo de confirmación, informar el pedido a la API de algoritmo (`POST /v1/pedidos`, ver `api/INTEGRACION-BACKEND.md`) y descontar stock. Debe ser **idempotente**: si Transbank o el cliente repiten el retorno, no duplicar nada.

Siempre termina con `302` a `<urlFin>?numero=SED-10482`. **El resultado no viaja en la redirección**: la app lo consulta por 4.4.

### 4.3 `GET /pagos/webpay/fin`

Una página mínima («Volviendo a la tienda…»). La app intercepta esta dirección y no la muestra; existe por si alguien la abre en un navegador.

### 4.4 `GET /pagos/webpay/{numero}` — estado del pago (la app lo consulta)

Cabecera `X-Token-Pago: <token>` (el mismo `token` de 4.1; sirve de clave de consulta, así un invitado sin cuenta puede consultar solo su pedido). Pedido desconocido, o token ausente o distinto → `404` con el cuerpo de error del contrato, `{ "error": "Pedido no encontrado.", "code": "no_encontrado" }`. **Ojo:** para la app un `404` con ese cuerpo (un `error` de texto no vacío) significa «ese pedido no existe, no hay cobro» y lo muestra como rechazado de inmediato, sin volver a preguntar; no lo uses para decir «todavía no está» (para eso existe `pendiente`). Un `404` **sin** ese cuerpo (p. ej. la página HTML de un proxy o una ruta mal configurada) se trata como falta de respuesta: la app sigue preguntando.

```json
{ "data": {
  "numero": "SED-10482",
  "estado": "aprobado",
  "total": 12140,
  "correo": "maria@correo.cl",
  "retiro": false,
  "comprobante": {
    "codigoAutorizacion": "1213",
    "tarjetaUltimos4": "6623",
    "tipoPago": "Crédito",
    "cuotas": 0,
    "fecha": "2026-11-16T20:15:00Z"
  }
} }
```

- `estado`: `pendiente` (aún no se confirma), `aprobado`, `rechazado`, `cancelado` o `expirado`. La app muestra `expirado` igual que `rechazado`; un estado desconocido lo trata como `pendiente`.
- Con `aprobado` **decide el `estado`**: `total`, `correo` y `retiro` son solo para mostrar. Deben venir (`total` entero, `correo` texto, `retiro` booleano), pero si alguno falta o viene mal formado la app no deja de dar el pago por aprobado: usa los de su propio pedido como respaldo (el total con que se inició el pago, y el correo y la entrega que envió). Lo único que hace a la app seguir preguntando es un `numero` distinto del consultado (si viene).
- `comprobante` solo con `aprobado`; la app lo muestra únicamente si trae `codigoAutorizacion`, `tarjetaUltimos4` y `tipoPago` como texto y `cuotas` como número finito (`fecha` es opcional, ISO 8601); si falta alguno o no se puede leer, el pago se acepta igual pero sin comprobante. Convertir `payment_type_code` de Transbank a texto: `VD` → «Débito», `VN`/`VC`/`SI`/`S2`/`NC` → «Crédito», `VP` → «Prepago»; `cuotas` = `installments_number`.
- **Fuente de verdad:** la app llama a este endpoint hasta que `estado` deje de ser `pendiente` y se guía solo por él. Hace 8 consultas, con pausas previas de 0, 1, 1, 2, 2, 3, 3 y 4 segundos (los ~16 s son **solo las pausas**) y **5 s de tope por consulta** (peor caso, unos 56 s). Un `5xx`, un `404` sin el cuerpo de error, un error de red o una respuesta ilegible no cuentan como rechazo: sigue preguntando. Si se agotan las consultas sin respuesta clara, la app muestra «Estamos confirmando tu pago», conserva el pago pendiente en el teléfono y lo retoma al volver a abrirla (hasta 24 h). Mientras ese pendiente exista, «Pagar» retoma ese pago en vez de iniciar otro.
- **Pagos abandonados:** si un pedido sigue `pendiente_pago` y su formulario de Webpay ya no puede completarse, este endpoint **no debe seguir respondiendo `pendiente`**: el backend consulta a Transbank el estado de la transacción (`GET …/transactions/{token}`) y responde `aprobado` (si quedó autorizada; con los mismos pasos de «pasar a `pagado`» de 4.2, sin duplicar nada) o `expirado`. El límite es el **tiempo del formulario de Transbank**, no una espera fija de ~30 min: según transbankdevelopers.cl (Webpay Plus), el cliente tiene **4 minutos en producción y 10 en integración** para completar el formulario, el token debe usarse dentro de 5 minutos desde su creación y el estado se puede consultar hasta 7 días después (**confirmar en la documentación vigente**). Así, quien salió de Webpay sin pagar puede reintentar en minutos y no queda bloqueado. Si la transacción quedó autorizada sin `commit` (el retorno nunca llegó), revisar en esa misma documentación cómo y hasta cuándo confirmarla.

## 5. Lo que Transbank exige y conviene tener resuelto

- **Reconciliación:** un proceso que revise los pedidos `pendiente_pago` y consulte a Transbank el estado de la transacción (endpoint `GET …/transactions/{token}`), por si el cliente cerró la app justo al pagar y el retorno nunca llegó.
- **Anulaciones y reembolsos:** `POST …/transactions/{token}/refunds` con el monto; al reembolsar, anular el pedido y avisar a la API de algoritmo (`DELETE /v1/pedidos/{numero}`). La app móvil no participa.
- **Validación de producción:** tras probar en integración, Transbank revisa el comercio antes de entregar el código y la llave de producción. Revisar en transbankdevelopers.cl la guía vigente de validación: en general pide poder ver el comprobante con número de orden, monto, código de autorización, fecha, tipo de pago, cuotas y últimos 4 dígitos (la app ya los muestra si el backend los entrega en `comprobante`), además de políticas de cambios y devoluciones, datos de contacto y logo de Webpay visibles.
- **Registros (logs):** nunca registrar la llave secreta ni datos de tarjeta; el `token` tampoco debería quedar en logs de acceso.

## 6. Cómo probar de punta a punta con la app

1. Backend con `TBK_ENTORNO=integracion` y las credenciales de prueba, accesible por HTTPS (solo una compilación debug de la app acepta `http`; profile y release lo bloquean).
2. Compilar la app apuntando a él: `flutter run --dart-define=PAGO_MODO=webpay --dart-define=API_URL=https://<host>/api/v1` (en una compilación release móvil el modo es siempre Webpay, así que basta `--dart-define=API_URL=…`; en la web el pago siempre es simulado).
3. Casos: pago aprobado (VISA de prueba), rechazado (MASTERCARD), cancelar en Webpay, cerrar la app a mitad del pago y reabrirla, doble toque en «Pagar», cambiar un precio entre el carrito y el pago (`precios_cambiaron`), producto sin stock, apagar el backend (la app debe decir que no se cobró nada).
4. Paso a producción: cambiar las tres variables de la sección 2 y repetir un pago real de monto bajo.
