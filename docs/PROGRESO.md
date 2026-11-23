> Proyecto movido a la carpeta Desktop/App_Sedyjo (9 nov 2026). La copia anterior sigue en Desktop/Sedyjo/app_flutter.

# Progreso de la maqueta (5 nov 2026)

## Hecho
- 26 vistas Flutter con datos simulados; web servida con `sedyjo-app-maqueta` (puerto 8099) tras `flutter build web --release`.
- Auditoría: `docs/auditoria-diseno-maqueta-v0.1.md` (11/20 técnica, 28/40 usabilidad, antes de corregir; incluye tabla de estado de correcciones).
- Decisiones del usuario aplicadas: aviso relámpago activo y lo cierra el usuario (no se va solo, no aparece en Carrito/Cuenta/pago, "No mostrar más hoy"); bienvenida distinta la primera vez, de regreso y con sesión, y saludo al iniciar sesión; modo oscuro (Automático/Claro/Oscuro en Cuenta).
- Correcciones P1: total de pedidos sin cortar, quitar con "Deshacer" y "−" que se detiene en 1, confirmación al quitar dirección, carrusel con pausa y puntos tocables, semántica sin duplicados, resumen de errores en pago y registro, contraste del banner.
- P2/P3: inicio reordenado (ofertas primero), campana con punto azul solo si hay novedades, contador calmado, tipografía de 21 a 11 tamaños, autocompletado, búsquedas recientes, total en el pago, carga saltable con un toque, éxito/error con botones abajo.
- Tercer lote de imágenes integrado (ver `docs/ideas-nuevas-imagenes.md`, tercera tanda): banners con texto real dorado/morado sobre negro (`lib/ui/banners.dart`), ideas para tu mesa, foto en uso en la ficha, estados claro/oscuro, producto agotado, seguimiento. La bienvenida NO usa fotos de personas (feedback del usuario).
- `docs/ideas-fotos.md`: lista de fotos e ilustraciones a producir.
- Imágenes IA integradas (ZIP del usuario): 35 productos recortados, héroes, categorías, estados, bienvenida, atención y patrón de carga; ver `docs/ideas-nuevas-imagenes.md` (qué se usó, qué no y qué crear). Archivos en `assets/img/{p,hero,cat,estados,escenas,patrones}/`. Los ZIP originales están en Descargas; extraídos en la carpeta temporal.
- Pruebas: `flutter test --concurrency=1` → 105 pasan en esa fecha (hoy la suite completa pasa 344; ver el resumen del pago al final). Si el runner de Windows cae, repetir.

- Demo portátil para el cliente: `app_flutter/Sedyjo-Maqueta-Demo.zip` (carpeta `demo-cliente/`): doble clic en `Abrir-Maqueta.bat`. Para regenerarla: `flutter build web --release --no-web-resources-cdn`, copiar `build/web` a `demo-cliente/maqueta` y volver a comprimir. `?cliente=1` oculta el panel.

- (Cambió el 10 nov 2026) Sedyjo ahora tiene un local de retiro de ejemplo: Av. Collao 2480, Concepción (`tienda` en `lib/app/datos.dart`). Antes se decía que no había tienda física. Dirección en vista propia (`direccion.dart`) con la comuna escrita a mano. No se menciona ninguna comuna ni zona de despacho en la maqueta (decisión del usuario); la vista "Fuera de zona" queda para cuando el servidor responda que no hay despacho.
- Textos grandes: sin alturas fijas en tarjetas ni banners; opciones en filas; probado a 130 % y 160 % (`?letra=1.3` en la URL abre la maqueta con ese tamaño).

## Segunda ronda (9 nov 2026): diseño, movimiento y carga
- Auditoría y estado de las correcciones: `docs/auditoria-diseno-movimiento-v0.2.md`.
- Nuevo: `lib/ui/movimiento.dart` (vibración, entrada escalonada, números animados, rebote, marca de verificación), `lib/ui/carga.dart` (esqueletos, error por sección, jalar para actualizar), tokens `R`, `Esp`, `Mov` y `ColoresSedyjo` en `lib/app/tema.dart`.
- Dependencias nuevas: `animations` (contenedor transformado) y `shared_preferences` (recordar "primera vez").
- Barra inferior ahora es `NavigationBar` (se corrigió que no actualizaba la pestaña ni la insignia). Riel lateral desde 720 dp.
- Pruebas: `flutter test --concurrency=1 test/<archivo>` de a un archivo (si el ejecutor de Windows cae, repetir).

## Tercera ronda (9 nov 2026): "volar al carrito" y que deje de verse maquetada
- Animación `volarAlCarrito` (`lib/ui/vuelo_carrito.dart`): burbuja en arco de 560 ms desde el botón hasta el ícono del carrito; al llegar, pulso del ícono, rebote del contador y abanico de seis burbujitas. Dorada sobre tarjetas negras. Si el carrito no se ve, termina en el borde superior. No se desactiva con "reducir movimiento" (decisión del usuario). Conectada a: tarjetas, "+" del selector (carrito y tarjetas), ficha, Ofertas, sección negra y oferta relámpago.
- Los avisos con acción ("Deshacer", "Ver carrito") se quedaban pegados: desde Flutter 3.29 no se cierran solos sin `persist: false`. Ahora duran 5 s (4 s el de "Agregaste").
- Comportamiento coherente en vez de simulado:
  - El carrito empieza vacío y se guarda entre aperturas (también sesión, direcciones, pedidos, tema, tamaño de letra, avisos y búsquedas recientes) con `shared_preferences`.
  - Comprar crea un pedido real (SED-1043, 1044…) con lo comprado y el correo, vacía el carrito y lo deja primero en "Mis pedidos"; el estado avanza con el tiempo.
  - "Seguir mi pedido" busca de verdad (número + correo) y avisa si no existe.
  - El nombre sale del correo; crear cuenta empieza sin pedidos ni direcciones.
  - "Mis datos" valida y guarda; el teléfono se reutiliza en el pago. Las direcciones exigen calle y comuna.
  - "Llamar" y "WhatsApp" abren la app del teléfono (`url_launcher`); si no se puede, lo dicen.
  - Las imágenes de las primeras pantallas se precargan durante la pantalla de carga.
- Pruebas nuevas: `test/vuelo_carrito_test.dart` (5) y `test/coherencia_test.dart` (9).

## Pendiente
- Con servidor: cuenta, contraseñas, pedidos y despacho siguen simulados en el teléfono (sin backend). El pago ya tiene escrita la integración con Webpay vía backend, pero ese backend aún no existe: por defecto sigue simulado (ver «Pago con Webpay en la app» al final).
- Migrar los archivos antiguos de `C.*` a `context.col` y quitar `reconstruirTodo()`; aplicar la escala `Esp` a los espacios sueltos.
- Revisar en celular real (vibración, volver predictivo, arranque verde, fluidez) y con TalkBack; tableta y horizontal reales.
- Estado del código (18 nov 2026): el trabajo está commiteado en la rama `mejoras-diseno-movimiento-y-flujos`; esos commits aún no se han subido (push) a `origin` (la rama va por delante) y nada está desplegado en ningún servidor.

## Cuarta ronda (10 nov 2026): retiro en tienda y despacho gratis
- Retiro en tienda (dirección inventada): opción en el pago, pantalla `Retiro en tienda` con horario, plazo y "Cómo llegar" (Google Maps o Waze), fila en la ficha y en los beneficios del inicio, tarjeta en el detalle del pedido, textos "Listo para retirar"/"Retirado" y salida desde "Fuera de zona".
- Despacho gratis desde $39.990 en toda la app (constante `despachoGratisDesde`).
- Avisos ("Deshacer", "Agregaste…") más cerca del borde inferior; en la ficha la barra de compra pasó al Scaffold para que el aviso flote sobre ella.
- Pruebas de imagen (golden) en `test/goldens/`: `flutter test --update-goldens test/goldens_test.dart` para aceptar cambios.

## Pago con Webpay: verificación en emulador (23 nov 2026)
Hecho: el servidor de prueba `tools/webpay_falso.py` (solo desarrollo, nunca desplegar) cumple el contrato de `docs/backend-webpay.md` §4 y el cliente real `PasarelaWebpay` se probó contra él con red real (aprobado con comprobante, rechazado, cancelado, `precios_cambiaron`, sin conexión). **El recorrido completo se probó a mano en un emulador Android 15 (API 35, «Google APIs»), contra ese servidor de prueba: los 8 casos de abajo se comportan como se diseñó.** Sigue pendiente probar en un teléfono real, el 3D Secure real y iOS.

Nota sobre el emulador: en esta máquina el emulador de Android 17 (API 37, emulador 37.2.12) se cae solo al minuto o dos (`Segmentation fault`; el propio emulador avisa «Guest Angle is still unstable for API > 35»), incluso con otro modo de dibujo o con el driver de NVIDIA actualizado. El de Android 15 creado para esto (`Sedyjo_API_35`, Pixel 8, 4 GB de RAM) aguantó toda la sesión de pruebas.

Comandos (dos terminales; el emulador de Android ve el equipo anfitrión como `10.0.2.2`):
```
python tools/webpay_falso.py --puerto 8080            # añadir --precios-cambian para el caso 7
flutter run --dart-define=PAGO_MODO=webpay --dart-define=API_URL=http://10.0.2.2:8080/api/v1
```
El servidor escucha solo en `127.0.0.1` por defecto (el `10.0.2.2` del emulador llega a ese loopback del anfitrión). Con un teléfono físico: `python tools/webpay_falso.py --host 0.0.0.0 --puerto 8080` y `API_URL=http://<IP del equipo>:8080/api/v1` (queda expuesto a la red local: solo en una red de confianza).
El `http` solo funciona en debug (`android/app/src/debug/AndroidManifest.xml` permite tráfico sin cifrar y el WebView solo acepta `http` en debug); profile y release lo bloquean.

Casos manuales (emulador Android 15, servidor de prueba local):
- [x] 1. Comprar y «Aprobar» → círculo verde, pedido `SED-9000X`, comprobante visible, carrito vacío. El pedido aparece en «Seguir mi pedido».
- [x] 2. «Rechazar» → «El pago no se completó», «No te cobramos nada», carrito intacto, barra de pestañas visible; «Intentar de nuevo» vuelve al paso de pago.
- [x] 3. «Cancelar» → «Cancelaste el pago», carrito intacto.
- [x] 4. Cerrar con «✕» → «¿Salir del pago?»; «Seguir pagando» vuelve a la página; «Salir» → consulta al servidor y, como el pedido sigue pendiente, a los ~16 s muestra «Estamos confirmando tu pago… No pagues de nuevo todavía» (ver hallazgo 1). Al cancelar el pedido en el servidor, «Revisar de nuevo» muestra «Cancelaste el pago».
- [x] 5. Matar la app en la página de pago (`am force-stop`) y reabrirla → al entrar a la tienda se reanuda sola («Confirmando tu pago…» y luego «Estamos confirmando tu pago»); tras aprobar el pago en el servidor, «Revisar de nuevo» muestra la compra aprobada y registra el pedido, sin duplicarlo.
- [x] 6. Servidor apagado antes de tocar «Pagar» → «No pudimos iniciar el pago. No pudimos conectar. Revisa tu conexión: no se cobró nada.» y el botón «Pagar» vuelve a estar disponible.
- [x] 7. Con `--precios-cambian` → «Cambió el total» con el total nuevo ($743 + $500 = $1.243); «Continuar» abre Webpay con ese total y, al aprobar, el resultado dice «Pagaste $1.243». (La rama «Volver al carrito» no se probó.)
- [x] 8. Doble toque rápido en «Pagar» (tres toques seguidos) → se crea un solo pedido: el siguiente pedido es el correlativo (`SED-90006` tras `SED-90005`). El servidor de prueba no deja registro de las peticiones, así que se comprobó por la numeración.

Comprobaciones del WebView:
- [x] (Android) El `302` a `urlFin` llega a `onNavigationRequest` y se intercepta: la app sale del WebView sola y consulta el estado. **iOS: pendiente.**
- [x] (Android) El `POST` con cuerpo (`token_ws`) a la página de pago funciona: la página mostró el pedido y el total del servidor. **iOS: pendiente.**
- [ ] «Reintentar» vuelve a hacer el `POST` (no un `GET` sin cuerpo). No se probó.
- [ ] Panel «No pudimos cargar Webpay»: si falla antes de que cargue ninguna página (p. ej. sin red al abrir), dice «No se te cobró nada. Revisa tu conexión…»; si falla después de que alguna página terminó de cargar (cortar la red ya dentro del formulario), dice «Si ya confirmaste el pago en tu banco, al cerrar revisaremos cómo quedó. Si no, no se te cobró nada.»
- [ ] Los iframes de 3D Secure no los bloquea el filtro de esquemas (`about:srcdoc`, `blob:`, `data:`).
- [ ] iOS no se puede probar en Windows: probar en un Mac con el backend real por `https` (el servidor de prueba es `http`) y antes de enviar a la App Store.

Hallazgos de la prueba en emulador (ninguno bloquea; quedan para revisar):
1. **Salir de Webpay sin pagar** deja al cliente en «Estamos confirmando tu pago… No pagues de nuevo todavía» hasta que el backend marque ese pedido como expirado (o cancelado). Ya está descrito en `docs/backend-webpay.md`: el backend debe expirar rápido los pagos abandonados, o quien se arrepiente no puede reintentar.
2. ~~La pantalla «Estamos confirmando tu pago» usaba la tarjeta con triángulo rojo de alerta, que parece decir «falló» cuando el pago pudo haberse cobrado.~~ **Resuelto (23 nov 2026):** ahora lleva una ilustración propia (`lib/ui/ilustracion_pago.dart`) con la tarjeta azul y un reloj, y el sello del círculo pasó de «!» gris a un reloj azul. «Cancelaste el pago» tampoco es un error: tarjeta apagada con una cruz gris y sello gris. La alerta roja queda solo para el pago que de verdad falló.
3. ~~Tras matar la app, al reabrirla aparecía primero la bienvenida y la reanudación empezaba recién al entrar a la tienda.~~ **Resuelto:** si hay un pago por confirmar, la carga entra directo a la tienda (`entrarALaTienda`) y el pago se retoma sin pasar por la bienvenida.
4. ~~En el resultado aprobado, el comprobante quedaba parcialmente tapado por los botones y el número de pedido aparecía dos veces.~~ **Resuelto:** el número de pedido se muestra una sola vez (panel verde), la ilustración y los espacios se compactan cuando hay comprobante para que quepa casi todo sin bajar, y un degradado al pie indica que hay más abajo.
5. En el registro de la app apareció un fotograma de hasta ~24 s al abrir el WebView por primera vez. En el emulador la página llegó a verse en ~6 s, así que puede ser solo el emulador: revisar en un teléfono real.
6. Las pruebas por ADB se manejaron con el árbol de accesibilidad de Android (`uiautomator dump`), que muestra los botones de la app con nombre; sirve para automatizar más casos.

## Pago con Webpay en la app (16-18 nov 2026): resumen
- **Qué se hizo:** el pago ya no es solo una maqueta. La app tiene la integración con Webpay Plus a través de un backend (que todavía no existe) en `lib/pago/`: configuración por plataforma (`configuracion_pago.dart`), pasarelas simulada, no disponible y Webpay (`pasarela_pago.dart`, `pasarela_webpay.dart`), reglas de navegación del WebView (`navegacion_webpay.dart`), el recorrido completo (`flujo_pago.dart`) y su punto de entrada (`pago.dart`). Pantalla del WebView en `lib/pantallas/webpay.dart`; checkout, resultado del pago (aprobado, rechazado, cancelado, sin confirmar, con comprobante) y `Shell` (reanuda un pago pendiente al abrir la app) conectados a ese flujo; el pago pendiente se guarda en el teléfono (`lib/app/estado`). Paquetes nuevos: `webview_flutter` y `http`.
- **Cómo se usa:** `PAGO_MODO` (`simulado` por defecto o `webpay`) y `API_URL` por `--dart-define`. Web: siempre simulado; móvil en release: siempre Webpay; debug: lo pedido. La app no lleva el código de comercio ni la llave de Transbank; pasar a producción es cambiar 3 variables en el backend, sin recompilar la app. Detalle en `docs/integraciones.md` («Pago con Webpay») y comandos en `README.md`.
- **Para el backend:** `docs/backend-webpay.md` es el contrato (endpoints, cabeceras `Idempotency-Key` y `X-Token-Pago`, estados, `precios_cambiaron` con `total`, `urlFin`). Diseño y plan: `docs/superpowers/specs/` y `docs/superpowers/plans/` (`2026-11-16-pago-webpay-app*`). Servidor de prueba: `tools/webpay_falso.py` (solo desarrollo).
- **Pruebas:** `flutter test --concurrency=1` → 344 pasan (suite completa; las de pago están en `test/pago_*_test.dart`). `flutter analyze` → 0 errores y 0 avisos (45 `info`: la deprecación de `package:flutter/material.dart` en todos los archivos y un `print` en `test/soporte_pantallas.dart`). `flutter build web --release --no-web-resources-cdn` compila.
- **Compilación de Android:** `flutter run` compila e instala la app (`assembleDebug`) y se probó en un emulador Android 15 (ver «Pago con Webpay: verificación en emulador»). Dentro del entorno de la herramienta de IA Gradle falla con «Unable to establish loopback connection» (incluso con un programa Java mínimo); desde una terminal normal funciona. Hizo falta subir el plugin de Android a 9.1.1, el mínimo que exige Flutter 3.50 (`android/settings.gradle.kts`). El plugin de WebView pide `minSdk` 24 y `flutter.minSdkVersion` ya vale 24.
- **Pendiente:**
  - Probar el pago en un teléfono real y los casos del WebView que faltan (sección anterior: «Reintentar», panel «No pudimos cargar Webpay», 3D Secure).
  - Probar en iOS, que exige un Mac, con el backend real por `https`.
  - Construir el backend según `docs/backend-webpay.md`.
  - Validación de Transbank para pasar a producción (código de comercio y llave reales).
  - Contenido del negocio que Transbank suele exigir visible: políticas de cambios y devoluciones, datos de contacto y logo de Webpay.
