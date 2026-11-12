# Auditoría de diseño, movimiento y carga de productos — app Comercial Sedyjo (v0.2)

**Alcance:** solo frontend de la app Flutter (`lib/`). No evalúa backend, pago real ni notificaciones push. Cuando se habla de carga de datos, se habla de lo que el frontend debe tener listo para cuando exista un servidor.
**Fecha:** 9 de noviembre de 2026.
**Método:** guías de `impeccable` (audit nativo, Android) y `ui-ux-pro-max` (reglas de animación, rendimiento y entrega de apps móviles), lectura de los 18 archivos de `lib/`, conteos con `grep` y revisión visual de la versión web compilada hoy (`build/web`, viewport 375×812, modo oscuro automático).
**Antecedente:** [auditoria-diseno-maqueta-v0.1.md](auditoria-diseno-maqueta-v0.1.md) (5 nov). Esta auditoría no repite sus hallazgos ya corregidos.

## Qué evidencia respalda cada afirmación

| Evidencia | Cubre | Límite |
|---|---|---|
| Lectura de código de todas las pantallas y componentes | Animaciones, listas, imágenes, tema, semántica | Sin perfilado: no hay mediciones de fotogramas |
| Capturas de la web compilada a 375 px (Bienvenida, Inicio, Categorías, Ofertas, Carrito) | Defectos visibles y el error de la barra inferior | Navegador, no celular: no mide fluidez ni gestos reales |
| Conteos con `grep` | Tamaños de letra, radios, `Opacity`, listas, `Hero` | — |

**No verificado:** rendimiento en un Android de gama baja, TalkBack/VoiceOver, volver predictivo, horizontal y tableta. Vistas que no abrí: ficha de producto, pago, pedidos, avisos (solo código).

---

## Estado de las correcciones (9 nov 2026, después de la auditoría)

Decisiones tomadas: vibración leve al agregar (se apaga con "reducir movimiento"); carga con canasta completa solo la primera vez y breve las siguientes (se revisa al probar en el celular); contenedor transformado del paquete oficial `animations` para abrir la ficha.

| Hallazgo | Estado |
|---|---|
| P1-1 barra inferior que no se actualiza | **Corregido.** Ahora es el `NavigationBar` de Material 3, con prueba que toca pestañas y comprueba el resaltado y la insignia |
| P1-2 sin estados de carga | **Corregido.** `lib/ui/carga.dart`: esqueletos con la misma forma que la tarjeta, error por sección (completo o de una línea), jalar para actualizar, y si falla con datos ya cargados los conserva. El panel de la maqueta tiene "Ver esqueletos de carga", "Ver error de carga" y "Red lenta" |
| P1-3 agregar sin respuesta | **Corregido.** El botón se transforma en selector, la insignia rebota, vibración leve; también en la ficha, Ofertas, la oferta relámpago y la sección negra |
| P1-4 listas que arman todo | **Corregido.** `SliverGrillaProductos` arma solo las filas visibles en Categorías, búsqueda y Ofertas; la grilla se adapta a 2, 3 o 4 columnas |
| P2-1 carga de 7 s y bienvenida | **Corregido.** Primera vez: canasta de 4,5 s. Después: logo de 1,4 s. Corre en paralelo a la carga real y no avanza hasta que esta termina. "Primera vez" se guarda en el teléfono (`shared_preferences`) |
| P2-2 parpadeo blanco al abrir | **Corregido** en Android (`launch_background.xml` y su versión v21) y iOS (`LaunchScreen.storyboard`). No probado en dispositivo |
| P2-3 cada tarjeta escucha todo | **Corregido.** `estado.cantidadDe(id)`: cada tarjeta escucha solo su producto |
| P2-4 `Tocable` sin foco ni ripple | **Corregido.** Ondulación de Material, anillo de foco azul y activación con teclado |
| P2-5 cambio de pestaña instantáneo | **Corregido.** Fundido de 200 ms; las pestañas ocultas detienen sus animaciones; tocar la activa vuelve arriba |
| P2-6 ficha sin transición | **Corregido** con `OpenContainer` (la tarjeta se expande hasta ser la ficha); la foto "en uso" se precarga |
| P2-7 fotos sin `cacheWidth` | **Corregido** en banners, carrusel, galería, logos, héroe y combos |
| P2-8 texto del banner sobre la foto | **Corregido.** Texto y foto en cajas separadas |
| P2-9 tema por variable global | **Parcial.** `ColoresSedyjo` (`ThemeExtension`, `context.col`) existe y lo usan los componentes nuevos; los ~19 archivos antiguos siguen leyendo `C.*` y `reconstruirTodo()` se mantiene. Migrarlos es una pasada mecánica pendiente |
| P2-10 radios y tamaños de letra | **Mayormente corregido.** Radios: 4 tokens (`R.s/m/l/xl`) en lugar de 19 valores (quedan solo dibujos y el marco de la maqueta). Letra: nuevos roles `cuerpoM` y `cuerpoMFuerte` y se eliminaron los tamaños redundantes; quedan variantes puntuales con `copyWith(fontSize:)` (de 112 a unas 75). Escala de espacios `Esp` creada, aún sin aplicar a los valores sueltos |
| P2-11 exceso de negrita | **Corregido.** 800 solo en titulares y precio; 700 en botones y subtítulos; 600 en énfasis y etiquetas |
| P2-12 inicio largo y producto repetido | **Corregido.** Barra de despacho de una línea; cada producto aparece una vez en la portada |
| P2-13 componentes de Material reinventados | **Parcial.** Barra inferior y riel reales de Material 3; temas de `FilledButton`, `OutlinedButton`, `TextButton`, chips, `SnackBar` y campos con los tokens. `Boton` sigue siendo propio (ahora con ondulación y foco) |
| P2-14 volver predictivo | **Corregido en configuración** (`enableOnBackInvokedCallback` y `PredictiveBackPageTransitionsBuilder`); falta verlo en un Android real |
| P3-1 a P3-6 | **Corregidos:** marca de verificación dibujada y vibración en la compra exitosa, línea de tiempo que se llena, pulso y vibración al lograr el despacho gratis, totales animados, ilustraciones con balanceo mínimo, volver arriba al repetir la pestaña |
| Tamaños (dimensión 5) | **Base hecha:** riel lateral desde 720 dp, ancho máximo de 840 dp centrado, y el marco de teléfono solo en el navegador. Sin probar en tableta real ni en horizontal |
| Miniatura que vuela al carrito | No se hizo (era opcional) |

Verificación: `flutter analyze` sin errores; 100 pruebas de pantallas en claro, 66 en oscuro y 18 de comportamiento y movimiento pasan (el ejecutor de Windows a veces se cae; repetir). Revisión visual en la web a 375 px: barra inferior, insignia, selector, carrusel, esqueletos y error de sección. No se probó en celular real: la vibración, el volver predictivo, el arranque nativo y la fluidez siguen pendientes.

---

## 1. Veredicto

La app **se siente como app, no como web portada**: hojas inferiores, snackbars con deshacer, botones grandes, modo oscuro de primera clase, fuentes variables propias (Bricolage + Figtree) y una identidad reconocible (canasta de carga, bloque negro con dorado y morado). El diseño estático está en buen nivel.

Lo que le falta para sentirse **fluida** es el movimiento entre estados: hoy casi todo cambia de golpe (agregar al carrito, quitar una línea, cambiar de pestaña, abrir una ficha, aparecer una foto). Y no existe ningún estado de carga porque los datos están en el teléfono: cuando llegue el servidor, **todas las pantallas de producto necesitarán esqueletos, foto con aparición suave y reintento**.

### Puntaje de salud (rúbrica nativa Android, 0–4)

| # | Dimensión | Nota | Hallazgo clave |
|---|---|---|---|
| 1 | Accesibilidad | **3** | Etiquetas y letra grande bien resueltas; `Tocable` no recibe foco de teclado ni muestra anillo |
| 2 | Rendimiento | **2** | Grillas y filas que arman todo de una vez con `IntrinsicHeight`; cada tarjeta escucha todo el estado; 0 `RepaintBoundary` |
| 3 | Apariencia y tema | **3** | Roles de color con oscuro real; pero depende de una variable global (`C.oscuro`) y de `reconstruirTodo()` |
| 4 | Conformidad con la plataforma | **2** | Barra inferior propia con un error visible; sin `NavigationBar`, ripple ni volver predictivo |
| 5 | Adaptación a tamaños | **1** | Solo teléfono vertical (sin cambios desde v0.1) |
| | **Total** | **11/20** | **Aceptable.** Mismo total que v0.1, distinta composición: suben accesibilidad y tema, bajan rendimiento y conformidad |

Dimensiones extra pedidas para esta auditoría:

| Dimensión | Nota | Hallazgo clave |
|---|---|---|
| Movimiento | **2** | Buenas bases (retroceso al presionar, `reducir movimiento`, carga con canasta), pero cero transiciones en el flujo de compra |
| Estados de carga | **0** | No existen: ni esqueletos, ni foto con aparición, ni reintento por sección |

---

## 2. Hallazgos por severidad

### P1 — Mayores

**P1-1 · La barra inferior no se actualiza (verificado en pantalla)**
- **Dónde:** [shell.dart:96](../lib/pantallas/shell.dart) (`bottomNavigationBar: const _BarraInferior()`).
- **Evidencia:** al tocar Categorías, Ofertas y Carrito, el contenido cambia pero la pestaña resaltada sigue en "Inicio". Al agregar un producto, el carrito tenía 5 unidades y la insignia seguía en 4.
- **Causa:** el widget es `const` y lee `estado` dentro de su `build`; Flutter no lo vuelve a construir cuando `estado` cambia. Es la misma familia de fallas que obligó a crear `reconstruirTodo()`.
- **Impacto:** la persona no sabe dónde está, y la insignia del carrito (la señal principal de "se agregó") miente.
- **Arreglo:** quitar `const` y envolver en `ListenableBuilder(listenable: estado)`, o pasar `pestana` y `cantidad` por parámetro. Añadir una prueba que toque una pestaña y verifique el resaltado.
- **Comando:** `/impeccable harden`.

**P1-2 · Cero estados de carga (preparar antes del servidor)**
- **Dónde:** todo `lib/`. `Catalogo.cargar()` bloquea `main()` ([main.dart:23](../lib/main.dart)) y las fotos son `Image.asset` síncronas.
- **Impacto:** con red real, las grillas aparecerían vacías o saltarían de alto al llegar los datos y las fotos.
- **Recomendación:** ver sección 4 (esqueletos con la misma geometría que la tarjeta, fotos con fundido sobre el color pastel de la categoría, reintento por sección con la ilustración "sin conexión" que ya existe).
- **Comando:** `/impeccable harden` + `/impeccable animate`.

**P1-3 · Agregar al carrito no tiene respuesta de movimiento**
- **Dónde:** [componentes.dart:368-382](../lib/ui/componentes.dart) (el botón "Agregar" se reemplaza de golpe por el selector de cantidad), [shell.dart:162-173](../lib/pantallas/shell.dart) (la insignia aparece sin animar).
- **Impacto:** es la acción más repetida de la app y no se siente. El usuario mayor depende de ver "algo pasó".
- **Recomendación:** transformación del botón en selector (`AnimatedSwitcher` + `AnimatedSize`, 200 ms), vibración leve, y rebote de la insignia (1 → 1,25 → 1 en 300 ms).
- **Comando:** `/impeccable animate`.

**P1-4 · Listas que arman todo de una vez y se miden dos veces**
- **Dónde:** [componentes.dart:429-454](../lib/ui/componentes.dart) (`GrillaProductos`: `Column` + `IntrinsicHeight` por fila), [componentes.dart:696-713](../lib/ui/componentes.dart) (`FilaHorizontal`), [inicio.dart:370-389](../lib/pantallas/inicio.dart), [pedidos.dart:203](../lib/pantallas/pedidos.dart).
- **Impacto:** hoy son 35 productos y pasa; con un catálogo real de cientos, "Todo el catálogo" tardará y se entrecortará. `IntrinsicHeight` obliga a medir cada hijo dos veces.
- **Recomendación:** `CustomScrollView` con `SliverList` de **filas** (cada fila conserva su `IntrinsicHeight`, así se mantiene la altura pareja y el soporte de letra grande, pero solo se arma lo visible). Preparar paginación.
- **Comando:** `/impeccable optimize`.

### P2 — Menores

| ID | Hallazgo | Dónde | Recomendación |
|---|---|---|---|
| P2-1 | La carga dura 7 s y la bienvenida sale **en cada apertura**; ninguna espera el trabajo real | [splash.dart:13](../lib/pantallas/splash.dart), [main.dart:82](../lib/main.dart) | Animación completa solo la primera vez; después 0,8–1,5 s y en paralelo a la carga real. Un toque ya la salta, mantenerlo |
| P2-2 | Parpadeo blanco al abrir: el arranque nativo es blanco antes del verde de la carga | [launch_background.xml](../android/app/src/main/res/drawable/launch_background.xml), [LaunchScreen.storyboard](../ios/Runner/Base.lproj/LaunchScreen.storyboard) | Igualar el fondo nativo a `#12372A` (y logo centrado) para que el cambio sea invisible |
| P2-3 | Cada `TarjetaProducto` escucha **todo** `estado`: agregar un producto reconstruye todas las tarjetas visibles | [componentes.dart:315](../lib/ui/componentes.dart) | Un `ValueNotifier<int>` por producto (o `ListenableBuilder` con selector) |
| P2-4 | `Tocable` no es enfocable ni dibuja ripple; `splashFactory: InkSparkle` en el tema no se usa | [componentes.dart:17-55](../lib/ui/componentes.dart), [tema.dart:110](../lib/app/tema.dart) | Envolver con `InkWell` sobre `Material` transparente y `FocusableActionDetector` con anillo de foco |
| P2-5 | Cambio de pestaña instantáneo (`IndexedStack`); las 5 pestañas viven con sus temporizadores | [shell.dart:86](../lib/pantallas/shell.dart) | Fundido-a-través de 200 ms entre pestañas manteniendo estado |
| P2-6 | La ficha de producto no comparte la foto con la tarjeta (sin `Hero`) y la segunda foto de la galería no se precarga | [producto.dart:277-292](../lib/pantallas/producto.dart) | `Hero` con etiqueta por producto (o contenedor transformado de Material) y `precacheImage` de la foto "en uso" |
| P2-7 | Fotos sin `cacheWidth` en banners, hero, ficha y combos (se decodifican a tamaño completo) | [banners.dart:88](../lib/ui/banners.dart), [inicio.dart:290](../lib/pantallas/inicio.dart), [producto.dart:291](../lib/pantallas/producto.dart) | `cacheWidth` según el ancho real × devicePixelRatio; ya se hace bien en `FotoProducto` |
| P2-8 | El texto del primer banner se **pisa con la foto** a 375 px ("Arroz, fideos y conservas" sobre los envases) | [inicio.dart:290-306](../lib/pantallas/inicio.dart) (velo con degradado sobre la imagen) | Mismo patrón que `BannerPromo`: texto y foto en una `Row`, cada uno con su caja |
| P2-9 | Tema por variable global: `C.oscuro` + `reconstruirTodo()` recorre **todo el árbol** al cambiar de modo | [tema.dart:14](../lib/app/tema.dart), [tema.dart:138](../lib/app/tema.dart) | `ThemeExtension<ColoresSedyjo>` accesible con `Theme.of(context)`; elimina esta clase de errores (incluida P1-1) |
| P2-10 | Sin sistema de forma ni de letra: 19 radios distintos (3 a 54), 12 tamaños de letra literales con `copyWith(fontSize:)` 112 veces (el 16 aparece 35) | `lib/` | 4 radios (12 · 16 · 24 · píldora), roles de letra en `TextTheme`, escala de espacios 4/8 |
| P2-11 | Jerarquía plana por exceso de negrita: títulos 800, cuerpo fuerte 700, botones 800, etiquetas 700 | [tema.dart:73-92](../lib/app/tema.dart) | 800 solo en titulares y precio; 600 para énfasis de cuerpo; 700 para botones |
| P2-12 | Inicio con cuatro bloques antes del primer producto (cabecera, búsqueda, barra de despacho, carrusel) y el mismo producto repetido 4 veces (Crush: tarjeta, banner, relámpago, héroe de Ofertas) | [inicio.dart:26-34](../lib/pantallas/inicio.dart) | Compactar la barra de despacho a una línea o moverla al carrito; variar los productos destacados |
| P2-13 | Componentes de Material reinventados (`Boton`, chips, `OpcionFila`, barra inferior) | [componentes.dart](../lib/ui/componentes.dart), [shell.dart](../lib/pantallas/shell.dart) | Tematizar `FilledButton`/`NavigationBar`/`ChoiceChip` con los tokens y dejar `Boton` como envoltorio delgado |
| P2-14 | Volver predictivo: `PopScope` solo existe en el pago; no revisé la activación en el manifest | [checkout.dart:93](../lib/pantallas/checkout.dart) | Activar `enableOnBackInvokedCallback` y confirmar que ninguna pantalla lo interfiere |

### P3 — Pulido

- **P3-1** Pantallas de éxito y error de pago: dibujar la marca de verificación (600 ms) y un único destello contenido; hoy son estáticas.
- **P3-2** Línea de tiempo del seguimiento: llenar el progreso hasta el estado actual al abrir (las ilustraciones ya existen en `assets/img/seguimiento/`).
- **P3-3** Al cruzar el umbral de despacho gratis, solo cambia el texto. Un pequeño pulso en la barra y el ícono del camión cierra el logro.
- **P3-4** Totales del carrito: contador numérico animado (250 ms) en vez de salto.
- **P3-5** Ilustraciones de estados vacíos con un balanceo mínimo (4–6 px, 3 s) para dar vida.
- **P3-6** Repetir el toque en la pestaña activa debería volver arriba del todo.

---

## 3. Mapa de movimiento

### Lo que ya existe (mantener)
| Dónde | Qué hace | Nota |
|---|---|---|
| `Tocable` | Se hunde a 0,97 en 110 ms | Bien; respeta `reducir movimiento` |
| `BarraDespacho` | Progreso animado 500 ms `easeOutCubic` | Bien |
| Oferta relámpago | Baja con `easeOutBack` 420 ms, cierra a mano | Bien |
| Carga con canasta | Cae cada producto, "golpe" de la canasta, fundido al logo | Marca propia; demasiado larga (7 s) |
| Puntos del carrusel y opciones | `AnimatedContainer` 160–250 ms | Bien |
| `dur()` / `sinMovimiento()` | Centraliza `reducir movimiento` | Excelente base; falta usarla en todo |

### Lo que falta (orden por impacto percibido)
| # | Interacción | Patrón recomendado | Duración |
|---|---|---|---|
| 1 | Agregar al carrito | Botón → selector (`AnimatedSwitcher`+`AnimatedSize`), rebote de insignia, vibración leve; opcional: miniatura que vuela al carrito | 200 / 300 / 450 ms |
| 2 | Aparición de fotos | `frameBuilder` con fundido de 180 ms sobre el color pastel de la categoría (ya existe: `p.fondo`) | 180 ms |
| 3 | Abrir ficha | `Hero` de la foto (tarjeta → ficha); alternativa: contenedor transformado del paquete oficial `animations` | 300 ms |
| 4 | Cambio de pestaña | Fundido-a-través entre pestañas | 200 ms |
| 5 | Primera carga de listas | Entrada escalonada (opacidad + 12 px de subida, 40 ms entre elementos, máximo 8) **solo la primera vez** | 240 ms |
| 6 | Quitar línea del carrito | `SizeTransition` + fundido, junto al aviso con "Deshacer" | 220 ms |
| 7 | Totales | Contador numérico animado | 250 ms |
| 8 | Búsqueda | Barra que se contrae al bajar y reaparece al subir (`SliverAppBar` flotante), filtros pegajosos en el listado | — |
| 9 | Compra exitosa | Marca de verificación dibujada + un destello | 600 ms |
| 10 | Actualizar | `RefreshIndicator.adaptive` con color de marca (cuando haya servidor) | — |

### Tokens de movimiento propuestos
Hoy hay 9 duraciones sueltas (110, 160, 200, 220, 250, 350, 400, 420, 500). Reducir a cuatro y centralizar:

| Token | Valor | Uso |
|---|---|---|
| `Mov.toque` | 120 ms | Presión, ripple |
| `Mov.estado` | 200 ms | Cambios de estado pequeños |
| `Mov.pantalla` | 300 ms | Pestañas, `Hero`, hojas |
| `Mov.enfasis` | 450 ms | Logros, entradas destacadas |

Curvas: `easeOutCubic` al entrar, `easeInCubic` al salir (la salida dura ~70 % de la entrada), resorte solo para la insignia. Todo pasa por `dur()` para respetar `reducir movimiento`. Solo animar `transform` y `opacity`, nunca ancho o alto de elementos que fuerzan nueva medición (por eso `AnimatedSize` solo en contenedores pequeños).

---

## 4. Carga de productos (para cuando haya servidor)

Hoy: datos locales, cero latencia, cero estados intermedios. Plan de frontend:

1. **Esqueleto de tarjeta** (`EsqueletoProducto`) con la **misma geometría** que `TarjetaProducto` (foto 1,18:1, dos líneas de texto, precio, botón) para que no haya saltos de diseño. Un solo `AnimationController` compartido para el brillo, dentro de `RepaintBoundary`. Con `reducir movimiento`: bloque fijo sin brillo.
2. **Foto con fundido:** `Image` con `frameBuilder` → color pastel de la categoría mientras llega → fundido de 180 ms. Con red, `cacheWidth` según el tamaño real y `errorBuilder` ya existente (ícono de paquete).
3. **Primera carga vs. refresco:** la primera vez, esqueletos y entrada escalonada; al refrescar, mantener lo que hay y mostrar solo el indicador.
4. **Error por sección, no por pantalla:** si fallan las ofertas, solo esa sección muestra "No pudimos cargar. Reintentar" con la ilustración `sin-conexion`; el resto sigue usable.
5. **Paginación:** `SliverList` de filas con carga al 80 % del desplazamiento; fila de esqueleto al final.
6. **Agregar con confianza:** el botón cambia al instante (optimista); si el servidor falla, vuelve atrás con aviso. Nunca bloquear con ruedas de espera.
7. **Tiempos:** menos de 100 ms, sin indicador; 100 ms a 1 s, esqueleto; más de 1 s, esqueleto con texto de apoyo ("Buscando las ofertas…", frase que ya usa la carga inicial).

---

## 5. Oportunidades de diseño visual

- **Mantener y reforzar:** la regla dorado/morado solo sobre negro, rojo solo en descuentos, el pastel por categoría detrás de cada foto, las ilustraciones de estados y la canasta de carga. Es lo que distingue a Sedyjo de una tienda genérica.
- **Estructura del inicio:** subir el primer producto a la vista: cabecera + búsqueda + una sola línea de despacho gratis, luego carrusel. La barra grande de despacho pertenece al carrito.
- **Superficies:** hay "cajas dentro de cajas" con borde en casi todo. Usar elevación tonal (superficie un escalón más clara) en vez de borde en tarjetas, y reservar el borde para controles. Mejora el modo oscuro.
- **Carrusel:** cambiar a diseño de dos cajas (texto | foto) como los banners negros; mismo ritmo, sin velo.
- **Barra inferior:** `NavigationBar` de Material 3 con el indicador de píldora que ya imitan (62×36) y `Badge` nativo para el carrito.
- **Letra:** conservar Bricolage + Figtree (distintivas y ligeras: 124 KB en total). Corregir el exceso de peso (P2-11).
- **Iconos:** Lucide es coherente; no mezclar con Material Symbols.

---

## 6. Lo que ya funciona (no tocar)

- Fotos y assets livianos: 3 MB en total, la imagen más pesada pesa 89 KB, todo en WebP.
- `FotoProducto` ya usa `cacheWidth: 520` y color de categoría de fondo (base perfecta para el marcador de posición).
- `reducir movimiento` y tamaño de letra respetados desde un único lugar (`dur()`, `sinMovimiento()`).
- Modo oscuro real, con colores de categoría propios y contraste revisado.
- Retroceso al presionar en todo lo tocable, semántica sin etiquetas duplicadas, errores con resumen arriba.
- Compra como invitado, deshacer al quitar, confirmación al borrar direcciones, carga que se salta con un toque.
- Carrusel con pausa visible y puntos tocables de 48 dp.

---

## 7. Hoja de ruta (solo frontend)

| Etapa | Contenido | Comando |
|---|---|---|
| **0 · Hoy (1 h)** | Arreglar la barra inferior (P1-1) con su prueba | `/impeccable harden` |
| **1 · Fluidez** | Tokens de movimiento; agregar al carrito (P1-3); fundido de fotos; `Hero`; fundido entre pestañas; quitar línea animada | `/impeccable animate` |
| **2 · Carga** | Esqueletos, listas por filas perezosas, selector por producto, errores por sección, `cacheWidth` (P1-2, P1-4, P2-3, P2-7) | `/impeccable harden` + `/impeccable optimize` |
| **3 · Sistema** | `ThemeExtension`, radios, letra, espacios, `NavigationBar`, botones de Material, foco y ripple (P2-4, P2-9, P2-10, P2-11, P2-13) | `/impeccable extract` + `/impeccable typeset` |
| **4 · Entrada** | Carga corta tras la primera vez, arranque nativo verde, carrusel y inicio reordenados (P2-1, P2-2, P2-8, P2-12) | `/impeccable onboard` + `/impeccable layout` |
| **5 · Deleite** | Éxito animado, seguimiento que se llena, despacho gratis con pulso, estados vacíos vivos (P3) | `/impeccable delight` |
| **6 · Tamaños** | Tableta, horizontal, volver predictivo (P2-14) | `/impeccable adapt` |
| **Cierre** | Revisión final y repetir esta auditoría | `/impeccable polish` |

**Decisiones que dependen de ti:**
1. ¿La carga con canasta se ve completa solo la primera vez (recomendado) o en cada apertura?
2. ¿`Hero` (sin dependencias) o contenedor transformado del paquete oficial `animations` (más pulido, una dependencia)?
3. ¿Se acepta una vibración leve al agregar? Es opcional y se apaga con `reducir movimiento`.
