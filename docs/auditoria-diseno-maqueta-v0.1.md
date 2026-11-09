# Auditoría de diseño y usabilidad — maqueta de la app Comercial Sedyjo (v0.1)

**Alcance:** solo diseño frontend de las 26 vistas de la maqueta Flutter (`app_flutter/`). No evalúa backend, pago real ni notificaciones push reales.
**Fecha:** 5 de noviembre de 2026.
**Método:** auditoría en un solo contexto (sin subagentes), con las guías de `impeccable` (audit nativo: plataformas Android + iOS), `ui-ux-pro-max` (Flutter y lista de entrega de apps) y las heurísticas de Nielsen con personas. El detector automático de `impeccable` solo analiza web, así que no aplica a Flutter.

## Qué evidencia respalda cada afirmación

| Evidencia | Qué cubre | Límite |
|---|---|---|
| Capturas de la versión web en el panel (viewport 1280×900, teléfono de 400×840 dentro del marco) | 19 de las 26 vistas vistas en pantalla | No es un celular real: no mide fluidez, gestos ni brillo al sol |
| Lectura del código (`lib/`, 18 archivos) y conteos con `grep` | Colores, tamaños de letra, semántica, listas, temporizadores | — |
| Cálculo de contraste WCAG de 35 pares de colores | Texto y bordes | No se midió sobre las fotos de producto |
| Sonda del árbol de semántica de Flutter | Lo que leería un lector de pantalla | No se probó con TalkBack ni VoiceOver reales |
| 49 pruebas de humo (todas las pantallas a 100 % y 130 % de letra) | Desbordes de texto | En pruebas la fuente es más ancha que la real: es una cota conservadora |

**No verificado:** modo oscuro (no existe), horizontal, tableta, rendimiento en un gama baja, TalkBack/VoiceOver, teclado en pantalla abierto. Vistas solo revisadas en código y no en captura: Búsqueda, lista de una categoría, Pago (paso 2), Seguimiento sin cuenta, Recuperar contraseña, Mis datos, carrito vacío y el formulario de dirección.

## Estado de las correcciones (5 nov 2026, después de la auditoría)

Decisiones tomadas: el aviso relámpago viene activo y lo cierra el usuario; la bienvenida cambia (primera vez / regreso / con sesión) y saluda al iniciar sesión; se implementó el modo oscuro.

| Hallazgo | Estado |
|---|---|
| P1-1 total cortado en pedidos | Corregido (total en su propia línea) |
| P1-2 quitar sin deshacer | Corregido (el "−" se detiene en 1, "Quitar" con Deshacer, confirmación al quitar dirección) |
| P1-3 aviso relámpago | Corregido (no se va solo, solo en Inicio/Categorías/Ofertas, "No mostrar más hoy", cerrar de 48 dp) |
| P1-4 carrusel | Corregido (se detiene al arrastrar, pausa visible, puntos tocables) |
| P1-5 semántica | Corregido (sin etiquetas duplicadas, precio con "antes") |
| P1-6 errores fuera de vista | Corregido en pago y registro (resumen arriba y subida automática) |
| P1-7 contraste del banner | Corregido (texto blanco) |
| P1-8 fotos | Parcial: foto con marco unificador; falta producir fotos recortadas (ver `ideas-fotos.md`) |
| P2-1 carga y bienvenida | Parcial: se salta con un toque; la bienvenida se muestra cada vez, con saludo distinto según el caso (decisión del usuario) |
| P2-2, P2-3, P2-4, P2-6, P2-7, P2-8, P2-9 | Corregidos |
| P2-5 sistema de diseño | Parcial: roles de color con modo oscuro y 11 tamaños de letra (antes 21); falta la escala de espacios 4/8 |
| P3-1, P3-4, P3-5, P3-6 | Corregidos (P3-6: modo oscuro) |
| P3-2, P3-3 | Pendientes |
| Adaptación, rendimiento de listas, `NavigationBar`, volver predictivo, anillo de foco | Pendientes |

Verificación: 105 pruebas automáticas pasan (letra 100 % y 130 %, claro y oscuro, más 8 de comportamiento). No se probó en celular real ni con TalkBack.

---

## 1. Veredicto

### ¿Se ve como app o como sitio web portado? — **Aprobado con reservas**
Se siente como una app propia, no como una web encogida: navegación inferior con etiquetas, hojas inferiores para confirmaciones, interruptores y snackbars de Material, páginas de una sola tarea y botones grandes. Reservas: la barra inferior es un componente propio (no el `NavigationBar` de Material 3), el gesto de volver de Android no usa la animación predictiva, y los formularios no aprovechan el autocompletado del sistema.

### Puntaje de salud (5 dimensiones, 0–4)

| # | Dimensión | Nota | Hallazgo clave |
|---|---|---|---|
| 1 | Accesibilidad | **2** | Lector de pantalla dice "Agregar / Agregar" (etiqueta duplicada); avisos y carrusel se mueven solos sin pausa |
| 2 | Rendimiento | **3** | Imágenes sin reducir (banners de 550 KB), listas que arman todo de una vez; sin medir en dispositivo |
| 3 | Apariencia y tema | **2** | 21 tamaños de letra distintos, 24 colores sueltos, sin modo oscuro |
| 4 | Conformidad con la plataforma | **3** | Barra inferior propia; sin gesto de volver predictivo |
| 5 | Adaptación a tamaños | **1** | Solo teléfono vertical; en pantalla ancha usa un marco de maqueta |
| | **Total** | **11/20** | **Aceptable: falta trabajo antes de producción** |

Contexto: es una maqueta de la etapa 1. La dimensión 5 pesa poco hoy; las dimensiones 1 y 3 son las que conviene corregir antes de escribir el código real.

### Heurísticas de usabilidad de Nielsen (0–4)

| # | Heurística | Nota | Hallazgo clave |
|---|---|---|---|
| 1 | Visibilidad del estado | 3 | La tarjeta pasa a selector de cantidad al agregar, barra de despacho gratis; el aviso "Agregaste…" dura solo 2,2 s |
| 2 | Lenguaje cercano | 3 | Español claro; "Exclusivo online" dentro de una app confunde |
| 3 | Control y libertad | 3 | Volver en todas partes; pero quitar productos y direcciones es inmediato, sin deshacer |
| 4 | Consistencia | 3 | Componentes coherentes; escalas de letra y espacios sin sistema |
| 5 | Prevención de errores | 2 | El "−" con cantidad 1 elimina el producto sin avisar |
| 6 | Reconocer en vez de recordar | 3 | Íconos siempre con texto; buscador sin recientes ni sugerencias |
| 7 | Flexibilidad y eficiencia | 2 | "Volver a comprar" sí; sin favoritos ni lista habitual |
| 8 | Diseño estético y minimalista | 3 | Limpio, pero el inicio tiene 7 secciones largas |
| 9 | Recuperación de errores | 3 | Mensajes específicos y en lenguaje simple; pero pueden quedar fuera de pantalla |
| 10 | Ayuda | 3 | Teléfono y preguntas frecuentes siempre a mano; sin ayuda dentro de los pasos |
| | **Total** | **28/40** | **Bueno (límite inferior)** |

### Especificidad del diseño
La maqueta tiene identidad propia: logo dorado como protagonista de la carga, canasta que se llena, paleta verde/azul de la web, rojo solo en descuentos, dorado y morado solo sobre negro, fotos reales del catálogo. Podría confundirse con otra tienda en la barra inferior, las tarjetas de categoría y la grilla de productos, que son estándar del rubro. Lo más propio y lo que más vale la pena reforzar: la canasta de carga y el bloque negro de ofertas.

---

## 2. Resumen ejecutivo

- **Hallazgos:** 0 bloqueantes (P0), 8 mayores (P1), 9 menores (P2), 6 de pulido (P3).
- **Lo más importante, en orden:**
  1. El precio se corta en "Mis pedidos" (`$9.9…`). Es una regresión que introduje al corregir un desborde.
  2. Quitar cosas es peligroso para este público: el "−" con 1 unidad elimina el producto, y "Quitar" borra productos y direcciones sin confirmar ni deshacer.
  3. Lo que se mueve solo: aviso relámpago que desaparece a los 14 s y aparece sobre cualquier pantalla (incluso "Mi cuenta"), carrusel que gira cada 6 s sin pausa.
  4. El lector de pantalla repite etiquetas y lee precios sin decir cuál es el "antes".
  5. Al fallar el formulario de pago, los errores pueden quedar arriba, fuera de la vista, y el botón de abajo parece no hacer nada.
- **Siguiente paso recomendado:** corregir los P1 en un solo lote (son pequeños), y recién después seguir con el pulido visual.

---

## 3. Hallazgos detallados

### P1: mayores (corregir antes de producción)

**P1-1 · Precio cortado en "Mis pedidos"**
- **Dónde:** [pedidos.dart:66](../lib/pantallas/pedidos.dart) (visto en captura de "Mis pedidos").
- **Categoría:** Apariencia / Accesibilidad.
- **Impacto:** el total aparece como `$9.9…`, `$5.0…`, `$6.6…` incluso con letra normal. Un dato que el cliente necesita queda ilegible.
- **Causa:** la corrección de desborde (`Flexible` + puntos suspensivos) prioriza que quepa sobre que se lea.
- **Recomendación:** nunca abreviar precios. Apilar fecha y total en una columna a la derecha y reducir las miniaturas a 2 más "+N".
- **Comando sugerido:** `/impeccable layout`.

**P1-2 · Quitar sin confirmar ni deshacer**
- **Dónde:** `Cantidad` con `minimo = 0` en [componentes.dart:188](../lib/ui/componentes.dart), "Quitar" del carrito ([carrito.dart](../lib/pantallas/carrito.dart)) y "Quitar" de direcciones ([cuenta.dart](../lib/pantallas/cuenta.dart)).
- **Categoría:** Usabilidad (prevención de errores).
- **Impacto:** un dedo impreciso toca "−" estando en 1 y el producto desaparece sin aviso; borrar una dirección es definitivo. Para adultos mayores es la causa más probable de frustración.
- **Recomendación:** (a) en el carrito, "−" se detiene en 1 y "Quitar" es la única forma de eliminar; (b) al quitar, mostrar "Quitaste X · Deshacer" durante 6 s; (c) borrar dirección pide confirmación en hoja inferior; (d) "Quitar" no debe tener el mismo peso visual que "Editar".
- **Comando sugerido:** `/impeccable harden`.

**P1-3 · Aviso relámpago: se va solo, interrumpe y no se puede controlar**
- **Dónde:** temporizador de 14 s en [shell.dart:66](../lib/pantallas/shell.dart); se muestra sobre cualquier pestaña (en la captura apareció sobre "Mi cuenta").
- **Categoría:** Accesibilidad (WCAG 2.2.1 tiempo ajustable) / Usabilidad.
- **Impacto:** una persona que lee despacio no alcanza a leerlo ni a tocar "Ver oferta"; además aparece mientras mira su carrito o sus datos.
- **Recomendación:** no mostrarlo en Carrito ni Cuenta ni durante el pago; que se quede hasta que el usuario lo cierre (o 30 s como mínimo); agregar "No mostrar más hoy"; no activar la frecuencia de 10 min por defecto: pedir permiso la primera vez ("¿Quieres enterarte de las ofertas?").
- **Comando sugerido:** `/impeccable clarify` + `/impeccable onboard`.

**P1-4 · Carrusel que gira solo y sin pausa**
- **Dónde:** [inicio.dart:167](../lib/pantallas/inicio.dart) (cada 6 s).
- **Categoría:** Accesibilidad (WCAG 2.2.2).
- **Impacto:** el contenido cambia mientras se lee o se está a punto de tocar; los puntos no son tocables, no hay flechas ni botón de pausa.
- **Recomendación:** detener el giro al primer toque/desplazamiento y con "reducir animaciones"; puntos tocables de 48 dp; botón "Pausar".
- **Comando sugerido:** `/impeccable adapt`.

**P1-5 · Lector de pantalla: etiquetas duplicadas y precios ambiguos**
- **Dónde:** `Tocable` en [componentes.dart](../lib/ui/componentes.dart) (etiqueta + texto interno), `PrecioProducto`, `TarjetaProducto`.
- **Evidencia:** la sonda de semántica devolvió `"Agregar / Agregar"` para cada botón y `"Ver Bebida Crush… / -25% / Bebida Crush… / $743 / $990"` para una tarjeta (nombre dicho dos veces y dos precios sin decir cuál es el actual).
- **Impacto:** con TalkBack cada botón se escucha dos veces y el usuario no sabe cuál precio es el vigente.
- **Recomendación:** que `Tocable` excluya la semántica de sus hijos; tarjeta con una sola etiqueta: "Bebida Crush, 743 pesos, antes 990, 25 % de descuento"; marcar el precio tachado como "antes".
- **Comando sugerido:** `/impeccable harden`.

**P1-6 · Errores del formulario fuera de la vista**
- **Dónde:** [checkout.dart](../lib/pantallas/checkout.dart) (`_continuar`), registro e ingreso en [auth.dart](../lib/pantallas/auth.dart).
- **Impacto:** el botón "Continuar al pago" está fijo abajo; si el error está en el primer campo, el usuario toca y no ve ningún cambio. Frustración alta y abandono en el paso más importante.
- **Recomendación:** tras un intento fallido, subir hasta el primer error y enfocarlo; mostrar arriba "Revisa 2 campos" con enlaces; el lector de pantalla debe anunciarlo.
- **Comando sugerido:** `/impeccable harden`.

**P1-7 · Texto de apoyo del primer banner con contraste insuficiente**
- **Dónde:** [inicio.dart](../lib/pantallas/inicio.dart), subtítulo del banner verde.
- **Medición:** verde pálido sobre verde `#2E7D5B` = **3,86:1** (mínimo 4,5:1 para texto de 15 px). Los otros dos banners pasan (6,1:1 y 6,6:1).
- **Recomendación:** usar blanco (5,0:1) o un verde más oscuro de fondo para ese banner.
- **Comando sugerido:** `/impeccable colorize`.

**P1-8 · Fotos de producto heterogéneas**
- **Dónde:** todas las tarjetas, `FotoProducto` con `BoxFit.cover`.
- **Impacto:** cada foto trae su propio fondo, iluminación y resolución; sobre los fondos pastel se ven como recortes pegados, algunas pixeladas al ampliarse (fuente de 210×400). Es lo que más resta calidad percibida a la maqueta.
- **Recomendación (contenido, no código):** pedir fotos con fondo transparente o blanco y mínimo 600 px; mientras tanto mostrar el producto sobre un marco blanco con `contain` como ya se hizo en la ficha.
- **Comando sugerido:** `/impeccable polish` (con nuevos assets).

### P2: menores (siguiente pasada)

| ID | Hallazgo | Dónde | Recomendación |
|---|---|---|---|
| P2-1 | La bienvenida y la carga de 4,3 s aparecen en cada apertura y no se pueden saltar; la animación no espera la carga real | [splash.dart](../lib/pantallas/splash.dart), [bienvenida.dart](../lib/pantallas/bienvenida.dart) | Bienvenida solo la primera vez; carga de 1,5 a 4 s según lo que tarde la app, con toque para saltar |
| P2-2 | El inicio tiene 7 bloques; "Exclusivo online" (negro, de alto contraste) va antes de las ofertas, que son lo que más vende | [inicio.dart](../lib/pantallas/inicio.dart) | Orden: búsqueda, ofertas, categorías, exclusivo; recortar "Recomendados" a 4 |
| P2-3 | Punto rojo permanente en la campana (rojo es solo para descuentos según la marca y crea falsa urgencia) | [inicio.dart:100](../lib/pantallas/inicio.dart) | Mostrarlo solo si hay avisos nuevos y usar el azul |
| P2-4 | Cuenta regresiva que reconstruye toda la pestaña cada segundo; presión innecesaria | [ofertas.dart:34](../lib/pantallas/ofertas.dart) | Aislar el contador en su propio widget; mostrar horas y minutos |
| P2-5 | Sin sistema tipográfico ni de espacios: 21 tamaños de letra (12 a 32, con medios), espacios de 14, 18, 22 y 26 fuera del ritmo de 4/8, 24 colores `Color(0x…)` fuera del tema | `lib/` completo | Definir 8 roles de texto en `TextTheme` y 6 espacios; mover pastel de categorías a tokens |
| P2-6 | Etiquetas por debajo del mínimo propio de 14 sp (13,5 en barra inferior; 12,5 en insignias y selector de letra) | [shell.dart:179](../lib/pantallas/shell.dart), [cuenta.dart:196](../lib/pantallas/cuenta.dart) | Mínimo 14 sp; barra inferior con 5 destinos en 360 dp admite 14 sp con "Cuenta" corto |
| P2-7 | Botón de cerrar del aviso relámpago de 44 dp (mínimo Android 48) | [shell.dart:233](../lib/pantallas/shell.dart) | 48 dp |
| P2-8 | El pago, paso 1, no muestra total ni resumen; no se ve el costo de despacho hasta pagar | [checkout.dart](../lib/pantallas/checkout.dart) | Resumen plegable arriba y total junto al botón |
| P2-9 | Formularios sin ayudas del teclado: sin `autofillHints`, sin `textInputAction` "siguiente", sin gestor de contraseñas | [componentes.dart `Campo`](../lib/ui/componentes.dart), [auth.dart](../lib/pantallas/auth.dart) | Agregar tipos de teclado, "siguiente" y autocompletado del sistema: menos tipeo y menos errores |

### P3: pulido

- **P3-1** Pantallas de éxito, error e ingreso quedan con el contenido arriba y gran vacío abajo; anclar los botones abajo.
- **P3-2** Barra superior de ingreso y registro deja un título vacío y mucho aire.
- **P3-3** El texto del banner se solapa con la foto a letra "Muy grande"; limitar el ancho de la foto.
- **P3-4** El buscador no tiene búsquedas recientes ni sugerencias mientras se escribe.
- **P3-5** El aviso "Agregaste…" dura 2,2 s con una acción dentro; subir a 5 s.
- **P3-6** Sin modo oscuro ni color dinámico de Android. Para este público y esta marca blanca no es urgente; planificarlo al migrar a roles de color.

### Adaptación a tamaños de pantalla (para la etapa de producción)
- Sin versión para tableta ni horizontal; ningún tope de ancho de contenido.
- El marco de teléfono de la maqueta se activa con ancho ≥ 600 dp: en una tableta real mostraría un teléfono dentro de otro. Eliminarlo al pasar a producción.
- Barras fijas inferiores (Carrito, Pago, Ficha) sin probar con teclado abierto: pueden dejar solo 2 o 3 líneas visibles.
- **Comando sugerido:** `/impeccable adapt`.

### Rendimiento (a medir en un celular real)
- Imágenes sin `cacheWidth`: se decodifican a tamaño completo (2,6 MB de imágenes; banners PNG de hasta 550 KB).
- 23 listas arman todos sus elementos de una vez; "Todo el catálogo" construye 35 tarjetas juntas.
- `IndexedStack` mantiene las 5 pestañas vivas, con temporizadores activos para el carrusel, el contador y el aviso.
- La web compilada pesa 2,6 MB de código; irrelevante para el celular pero útil para la demo.
- **Comando sugerido:** `/impeccable optimize`.

---

## 4. Revisión por vista

Leyenda: ✔ bien · ⚠ con observaciones · ✖ requiere cambio antes de producción. "(código)" = revisada solo en código y pruebas.

| Vista | Estado | Observación principal |
|---|---|---|
| Carga con canasta | ✔ | Muy buena idea y ejecución; falta saltar y adaptar al tiempo real (P2-1) |
| Bienvenida | ✔ | Jerarquía clara: una acción principal y dos secundarias; solo la primera vez (P2-1) |
| Inicio | ⚠ | Demasiado largo (P2-2); campana (P2-3); subtítulo del banner 1 (P1-7); carrusel (P1-4) |
| Categorías | ✔ | Lista simple y táctil; las fotos pesan más que el texto (P1-8) |
| Lista de categoría (código) | ⚠ | Filtros claros; todo el listado se arma de una vez (rendimiento) |
| Búsqueda (código) | ⚠ | Sin recientes ni sugerencias (P3-4) |
| Ofertas | ⚠ | Gancho fuerte con el bloque negro; contador por segundo (P2-4) |
| Ficha de producto | ✔ | Mejor pantalla: precio grande, ahorro explícito, barra de compra fija; marco blanco ayuda con las fotos |
| Carrito | ⚠ | Barra de despacho gratis excelente; quitar sin deshacer (P1-2) |
| Carrito vacío (código) | ✔ | Explica y ofrece dos salidas |
| Pago, paso 1 (datos) | ⚠ | Compra como invitado muy visible; errores fuera de vista (P1-6); sin total (P2-8) |
| Pago, paso 2 (código) | ⚠ | Resumen y Webpay claros; botón con "Conectando…" y sin cancelar |
| Compra exitosa | ✔ | Número de pedido grande y explicación de seguimiento; contenido arriba (P3-1) |
| Error de pago | ✔ | Tranquiliza ("no te cobramos nada") y da dos caminos |
| Seguimiento sin cuenta (código) | ✔ | Dos campos y resultado con línea de tiempo |
| Ingresar | ⚠ | Limpio; falta autocompletado (P2-9); barra superior vacía (P3-2) |
| Registro | ⚠ | Reglas de contraseña antes del error; casilla de términos grande; autocompletado (P2-9) |
| Recuperar contraseña (código) | ✔ | Estado de "revisa tu correo" bien resuelto |
| Cuenta (visitante y con sesión) | ✔ | Agrupación clara; el selector de letra a la vista es un acierto |
| Mis pedidos | ✖ | Total cortado (P1-1); mucho espacio vacío |
| Detalle de pedido | ✔ | Línea de tiempo vertical con estado actual; "Volver a comprar" |
| Direcciones | ⚠ | "Quitar" sin confirmar (P1-2) |
| Mis datos (código) | ✔ | Cambio de contraseña separado |
| Avisos y ofertas | ⚠ | Muy buena idea (frecuencia a elección y vista previa); ver P1-3 |
| Ayuda | ✔ | Teléfono primero y preguntas plegables |
| Aviso relámpago | ⚠ | Visualmente fuerte; comportamiento a corregir (P1-3) |

---

## 5. Facilidad de uso según el tipo de usuario

### Tarea medida: comprar como invitado desde el inicio
Agregar producto (1 toque) → Carrito (1) → Ir a pagar (1) → completar 3 datos de contacto + 2 de dirección (5 campos de texto) → Continuar (1) → Pagar (1). **5 toques y 5 campos.** Es un recorrido corto y sin sorpresas; el mayor costo es el tipeo, que mejora con P2-9.

### Marta, 68 años, ve poco y no usa mucho el celular (persona del público objetivo)
- **A favor:** letra de 17, botones de 58–62 dp, "Agregar" siempre con texto, teléfono de ayuda en la bienvenida, el inicio y el error de pago, selector de tamaño de letra visible en Cuenta.
- **Banderas rojas:** el "−" que elimina el producto (P1-2); el aviso que desaparece antes de leerlo y la tarjeta de oferta que aparece cuando mira su carrito (P1-3); el carrusel que cambia solo (P1-4); el total cortado en pedidos (P1-1); etiquetas de 12,5 a 13,5 sp (P2-6); la bienvenida cada vez que abre la app (P2-1).

### Jordan, primera vez con compras en línea
- **A favor:** "Comprar sin crear cuenta" como primer botón; mensajes de error con la solución; plazos de despacho a la vista.
- **Banderas:** "Exclusivo online" y "Avisos y ofertas" no explican qué son; el costo de despacho bajo $49.990 dice "se calcula al elegir tu dirección" y recién se sabe al pagar (P2-8).

### Casey, una mano y poco tiempo
- **A favor:** acciones principales abajo (barra de compra, "Ir a pagar"), barra inferior alcanzable, tarjetas grandes.
- **Banderas:** botón de volver y campana arriba a la izquierda y derecha (zona difícil de alcanzar); el aviso relámpago llega arriba, justo donde no se alcanza para cerrarlo con una mano (además de 44 dp).

### Sam, usa lector de pantalla
- **A favor:** los controles tienen etiqueta (36 declaradas), los títulos están marcados como encabezados, la cantidad se anuncia con `liveRegion` y las fotos llevan texto alternativo.
- **Banderas:** etiquetas duplicadas y precios ambiguos (P1-5); los errores no mueven el foco (P1-6); no hay modo de saltar entre secciones del inicio (encabezados marcados solo en parte).

---

## 6. Patrones sistémicos

1. **Se prefirió "que quepa" a "que se lea"** (P1-1, P2-6, P3-3): las correcciones de desborde acortaron texto en vez de reorganizar. Regla propuesta: precios, totales y plazos nunca se abrevian.
2. **Acciones destructivas sin red** (P1-2): ocurre en tres lugares y siempre con el mismo componente; resolver una vez en `Cantidad` y en un helper de "Deshacer".
3. **Movimiento y tiempo por defecto** (P1-3, P1-4, P2-4, P2-1): carrusel, aviso, contador, carga y snackbar suponen un usuario rápido. Todo lo temporizado necesita pausa, extensión o ausencia.
4. **Sistema de diseño a medias** (P2-5): tokens de color existen, pero no hay escala de tipografía ni de espacios; cada pantalla "afina" a mano.
5. **Semántica de accesibilidad pensada por pieza y no por pantalla** (P1-5, P1-6): etiquetas bien intencionadas que se duplican; falta revisar cómo se lee una pantalla completa.

## 7. Lo que ya funciona (mantener)

- Paleta y reglas de marca respetadas casi siempre: dorado y morado solo sobre negro; verde de acción con 5,0:1 contra blanco; texto de apoyo con 5,6 a 6,4:1.
- Contraste excelente en la mayor parte del texto: 29 de 35 pares medidos superan 4,5:1; los que no, salvo el subtítulo del banner (P1-7), son bordes, pistas de progreso o decoración.
- Botones de 56 a 62 dp con 8 a 12 dp de separación, selector de cantidad de 48 a 58 dp.
- La tarjeta de producto cambia a selector de cantidad al agregar: feedback inmediato sin salir de la pantalla.
- Compra como invitado en primer plano y seguimiento sin cuenta.
- Mensajes de error con causa y solución ("Falta la @. Ejemplo: nombre@correo.cl").
- Selector de tamaño de letra hasta 130 % sin desbordes (49 pruebas) y opción de reducir animaciones.
- Íconos de un solo juego (Lucide, trazo uniforme), sin emojis; todos con etiqueta de texto o nombre accesible.
- La pantalla de carga: personalidad de marca y respeta "reducir animaciones".

## 8. Acciones recomendadas, en orden

1. **[P1] `/impeccable harden`:** P1-2 (quitar con deshacer y confirmaciones), P1-5 (semántica sin duplicados y precios con "antes"), P1-6 (foco y resumen de errores).
2. **[P1] `/impeccable layout`:** P1-1 (total de pedidos sin cortar) y revisión de que ningún precio se abrevie.
3. **[P1] `/impeccable clarify` + `/impeccable onboard`:** P1-3 (aviso relámpago: dónde aparece, cuánto dura, permiso inicial) y P2-1 (bienvenida solo la primera vez).
4. **[P1] `/impeccable adapt`:** P1-4 (carrusel con pausa), P2-7, y base responsive (tope de ancho, tableta y horizontal).
5. **[P1] `/impeccable colorize`:** P1-7 (contraste del banner) y revisar todo texto sobre color.
6. **[P2] `/impeccable typeset`:** P2-5 y P2-6 (escala de 8 roles y mínimo de 14 sp).
7. **[P2] `/impeccable distill`:** P2-2 y P2-3 (inicio más corto y ordenado por intención de compra).
8. **[P2] `/impeccable optimize`:** imágenes reducidas, listas perezosas, contador aislado.
9. **[P1 con contenido] fotos de producto:** pedir al negocio fotos con fondo limpio (P1-8).
10. **Cierre: `/impeccable polish`** y repetir esta auditoría para comparar el puntaje.

**Decisiones que dependen de ti** (cambian lo que se construye): si el aviso relámpago debe pedir permiso la primera vez o venir activo; si la bienvenida se muestra siempre o solo en el primer uso; y si el modo oscuro entra en la versión 1.
