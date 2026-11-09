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

- Sedyjo NO tiene tienda física: la maqueta no ofrece retiro en tienda (solo despacho a domicilio). Dirección en vista propia (`direccion.dart`) con la comuna escrita a mano. No se menciona ninguna comuna ni zona de despacho en la maqueta (decisión del usuario); la vista "Fuera de zona" queda para cuando el servidor responda que no hay despacho.
- Textos grandes: sin alturas fijas en tarjetas ni banners; opciones en filas; probado a 130 % y 160 % (`?letra=1.3` en la URL abre la maqueta con ese tamaño).

## Pendiente
- Sin hacer: adaptación a tableta/horizontal, listas perezosas, `NavigationBar` de Material 3, volver predictivo de Android, escala de espacios 4/8, anillo de foco para teclado.
- Revisar en celular real y con TalkBack.
- Nada se ha commiteado ni desplegado.
