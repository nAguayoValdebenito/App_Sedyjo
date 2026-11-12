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
- Pruebas: `flutter test --concurrency=1` → 105 pasan (si el runner de Windows cae, repetir).

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
- Con servidor: cuenta, contraseñas, pedidos, pago y despacho siguen simulados en el teléfono (sin backend).
- Migrar los archivos antiguos de `C.*` a `context.col` y quitar `reconstruirTodo()`; aplicar la escala `Esp` a los espacios sueltos.
- Revisar en celular real (vibración, volver predictivo, arranque verde, fluidez) y con TalkBack; tableta y horizontal reales.
- Nada se ha commiteado ni desplegado.

## Cuarta ronda (10 nov 2026): retiro en tienda y despacho gratis
- Retiro en tienda (dirección inventada): opción en el pago, pantalla `Retiro en tienda` con horario, plazo y "Cómo llegar" (Google Maps o Waze), fila en la ficha y en los beneficios del inicio, tarjeta en el detalle del pedido, textos "Listo para retirar"/"Retirado" y salida desde "Fuera de zona".
- Despacho gratis desde $39.990 en toda la app (constante `despachoGratisDesde`).
- Avisos ("Deshacer", "Agregaste…") más cerca del borde inferior; en la ficha la barra de compra pasó al Scaffold para que el aviso flote sobre ella.
- Pruebas de imagen (golden) en `test/goldens/`: `flutter test --update-goldens test/goldens_test.dart` para aceptar cambios.
