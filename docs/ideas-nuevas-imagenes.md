# Ideas de nuevas imágenes para la app de Sedyjo

Segunda tanda, después de integrar los dos ZIP. Primero, qué se usó y qué no; luego, qué conviene crear para que todo calce con la estética de Sedyjo (blanco y verde fresco, azul de apoyo, dorado y morado solo sobre negro).

## 1. Qué se integró y qué quedó fuera

| Pieza | Estado | Dónde se ve |
|---|---|---|
| 35 fotos de producto con fondo transparente | **Usadas** (limpié rayitas sueltas del recorte en varias de ellas y las dejé en 640 × 640, ~30 KB cada una) | Tarjetas, ficha, carrito, pedidos, oferta relámpago, avisos |
| 5 ilustraciones de categoría sin texto | **Usadas** | Tarjetas del inicio y lista de Categorías |
| Banners de abarrotes, dulces y bebidas | **Usados recortados**: solo el grupo de productos (el texto y el botón dibujados se quitaron; el texto ahora es real) | Carrusel del inicio |
| Banners de galletas y té (fondo negro) | **Usados recortados**, con el borde izquierdo difuminado | Bloque negro "Exclusivo online" |
| Estados: carrito vacío, compra exitosa, pago no completado, sin pedidos, sin resultados | **Usados** (recortada la ilustración, sin el texto dibujado) | Carrito, pago, búsqueda, pedidos |
| Escena de bienvenida | **Usada** recortada (sin el globo de texto) | Pantalla de bienvenida |
| Escena de atención telefónica | **Usada** recortada | Ayuda y contacto |
| Patrón de doodles oscuro | **Usado** como textura | Pantalla de carga |
| Patrón de doodles claro | Guardado, sin usar todavía | Disponible para fondos de tarjetas |
| Estado "sin conexión" | Guardado, sin usar (la maqueta aún no tiene esa vista) | — |
| Logo "conceptual no oficial" | **No usado** | Es un logo inventado; el oficial es el escudo dorado |
| Escena de fachada | **No usada** | Es ficticia, y el negocio no tiene tienda física |
| Escena de despacho | **No usada** | Texto "Tu pedido ¡En camino!" tapa a la persona; uniforme y logo inventados |
| Tarjetas de categoría con título y "todo el catálogo" | **No usadas** | Baja resolución (ampliadas de una lámina) y con texto incrustado |
| Bocetos de producto (12) | **No usados** | Las 35 fotos nuevas son mejores y más consistentes |
| Canasta "Cargando…" | **No usada** | La carga ya tiene su canasta animada (con texto incrustado no sirve) |

Detalle a corregir en la escena de bienvenida: la bolsa de papel lleva un logo verde con carrito y hoja que **no es el oficial** (el de Sedyjo es el escudo dorado). Se dejó porque la foto transmite calidez, pero conviene regenerarla con el escudo real.

## 2. Reglas para todo lo que se cree desde ahora

1. **Nunca texto dentro de la imagen.** Títulos, precios y botones son texto real de la app (escalan con "Letra grande", los lee el lector de pantalla y se traducen).
2. **Siempre fondo transparente** para productos, banners y categorías; así sirven en modo claro y oscuro.
3. **Un solo logo:** el escudo dorado oficial. Ningún uniforme, bolsa, camioneta o fachada con logos inventados.
4. **Resolución real:** crear en 2× el tamaño de uso (no ampliar recortes de láminas).
5. **Paleta:** verdes `#2E7D5B` / `#1F5C42`, azul `#1E4B8F` solo de apoyo, rojo solo en descuentos, dorado y morado solo sobre negro `#0B0B0F`.
6. **Luz y estilo:** luz suave de arriba a la izquierda, sombra de contacto muy suave, aspecto ilustrado-realista como los empaques ya generados.
7. Nombre de archivo en minúsculas con guiones, peso final bajo 120 KB (WebP).

## 3. Imágenes nuevas, por prioridad

### Prioridad alta (completan pantallas que ya existen)

| Pieza | Para qué | Idea |
|---|---|---|
| **Bienvenida con sesión iniciada** | Variante "Hola de nuevo, María" | Misma señora (u otra persona mayor) abriendo su pedido ya entregado o mirando la lista; bolsa con el escudo oficial |
| **Bienvenida de regreso sin sesión** | Variante "Qué bueno verte de nuevo" | Escena distinta: persona adulta de mediana edad con el celular en la cocina |
| **Despacho en 4 pasos** | Línea de tiempo del pedido (Recibido, Preparando, En camino, Entregado) | 4 ilustraciones pequeñas del mismo estilo: caja recibida, bolsa armándose, camioneta en ruta, bolsa en la puerta; 400 × 300 |
| **Escena de despacho sin texto** | "En camino" y notificación | Repartidor entregando una bolsa, camioneta con el escudo oficial, cielo claro |
| **Estados que faltan** | Pantallas vacías | Sin direcciones guardadas, sesión expirada, producto agotado, fuera de la zona de despacho |
| **Sin conexión con la misma tarjeta** | Cuando se agregue la vista | Ya existe la ilustración; falta versión con fondo transparente |
| **Estados en versión oscura** | Modo oscuro | Hoy las ilustraciones van sobre una tarjeta verde claro; versión con fondo transparente o verde profundo `#1D2C25` |

### Prioridad media (mejoran las ventas y la confianza)

| Pieza | Para qué | Idea |
|---|---|---|
| **Categorías que faltan** | La web menciona aseo, higiene personal y detergentes | 3 ilustraciones de categoría (trío de productos transparentes) para ampliar el catálogo |
| **Ilustración "Todo el catálogo"** | Tarjeta verde del inicio | Las cinco siluetas de categoría en abanico |
| **Banner de oferta del día** | Bloque negro de Ofertas | Producto grande con estallido de luz dorada, sin texto; versión para cada producto en oferta |
| **Sellos de descuento** | Etiquetas -20 %, -25 % | Set de 4 sellos/cintas rojos (solo descuentos) listos para superponer |
| **Combos "Once" y "Desayuno"** | Packs temáticos chilenos | Composición de pan, té, mermelada y galletas; otra de bebidas y snacks para compartir |
| **Segunda foto de producto** | Ficha | Vista trasera con tabla nutricional real (fotografiada, no generada) para los 12 productos del inicio |
| **Producto en uso** | Ficha y banners | Lata con hielo, plato de fideos, taza de té; 6 a 8 productos estrella |
| **Logos de medios de pago** | Pago | Webpay, Redcompra, tarjetas (usar los recursos oficiales de Transbank, no generados) |

### Prioridad baja (identidad y campañas)

| Pieza | Idea |
|---|---|
| **Escudo oficial en vector (SVG)** y versión solo escudo | Para ícono de la app, tienda y notificaciones |
| **Canasta y productos de la carga en vector** | Para reemplazar el dibujo hecho en código y animarlo con más detalle |
| **Patrón de doodles repetible** (claro y oscuro) | Que se junte sin costura en los bordes |
| **Campañas de temporada** (Chile) | Fiestas Patrias, Navidad, Año Nuevo, Día de la Madre, vuelta a clases: 1 ilustración transparente por fecha |
| **Bodega y equipo reales** | Fotos auténticas del armado de pedidos y del reparto, para "Quiénes somos" y confianza (Sedyjo no tiene tienda física) |
| **Mapa de despacho** | Ilustración de la comuna con el área de reparto, cuando el negocio confirme las zonas |
| **Tutorial de 3 pasos** | "Elige, paga, recibe": 3 ilustraciones simples para la primera vez (adultos mayores) |
| **Avatares de cuenta** | 6 avatares amables (canasta, manzana, estrella) para quien no sube foto |
| **Ícono y piezas de notificación** | Ícono pequeño blanco monocromo (96 × 96), imagen grande 1024 × 512 por oferta, ícono de 1024 × 1024 |
| **Gráficos de tienda** | Ficha de Google Play 1024 × 500 y 5 capturas con marco de celular |

## 4. Mejoras a las imágenes que ya están

- **Regenerar los 5 banners sin texto** y con el producto a la derecha y espacio libre a la izquierda (así ya no hay que recortar y se aprovecha todo el cuadro).
- **Banners oscuros con fondo realmente transparente** (o negro puro `#0B0B0F`): hoy el borde se difumina con una máscara.
- **Revisar a mano los recortes de producto** frente a un fondo oscuro: algunos envases blancos o muy brillantes (leche, arroz) podrían necesitar un borde de luz tenue.
- **Unificar la escala:** las galletas y el caramelo salen más pequeños que las latas porque la imagen es cuadrada; crear una versión "apaisada" 1200 × 800 para productos largos.
- **Retocar las fotos con rayitas sueltas** en el original (ya filtradas en la app, pero conviene limpiarlas en origen).

---

# Tercera tanda: lote "Nuevas imágenes por secciones"

## Qué se usó

| Pieza | Dónde se ve |
|---|---|
| Banners sin texto de abarrotes, bebidas y dulces (recortados al grupo de productos) | Carrusel del inicio y tarjeta de bienvenida |
| Ofertas oscuras (Crush, Mecano, Coca-Cola, té, spaghetti) | Banners "Destacados de hoy" del inicio y tarjeta "Oferta del día" |
| Campaña de Navidad (canasta con confeti) | Banner "Prepara tu Navidad" |
| Combos (desayuno, once, bebidas y snacks) | "Ideas para tu mesa" del inicio (llevan a una categoría real, no se venden como pack) |
| Fotos "en uso" (6) | Segunda foto deslizable en la ficha de Coca-Cola, Rama de Leche, Galletas Costa, Jugo de Mango, Spaghetti y Té Ceylán |
| Seguimiento (4 pasos) | Ilustración del paso actual en el detalle del pedido |
| Estados nuevos claro/oscuro (sin conexión, sesión expirada, fuera de zona, sin direcciones, producto agotado) | Pantallas nuevas en el panel lateral y "sin direcciones" en Direcciones |
| Tutorial elige / paga / recibe | Primera vez en la bienvenida |
| Todo el catálogo | Tarjeta verde del inicio |
| Patrón de doodles claro y oscuro | Tarjeta de visitante en Cuenta y tarjeta de bienvenida |

## Qué quedó fuera (y por qué)

- **Fotos de personas en la bienvenida:** probadas y descartadas. El contraste con la marca no funcionaba y la app no se dirige a un público en particular; la bienvenida usa la identidad de Sedyjo (verde, productos reales y escudo).
- **Categorías aseo, detergentes e higiene personal:** no hay productos de esas categorías en el catálogo, así que no se muestran; quedan listas (`assets/img/cat/`) para cuando existan.
- **Sellos de descuento:** el descuento se dibuja con texto real y rojo de marca; los sellos sin texto no aportan.
- **Avatares:** salen ovalados (no son círculos); pendientes de corregir.
- **Despacho sin marca:** estilo plano distinto al resto.
- **Banners de galletas y té del lote:** quedan muy bajos y anchos para tarjeta; se mantuvieron los del lote anterior.

## Cómo se hicieron los banners con texto

El texto es real (no está en la imagen): título en **dorado o morado sobre negro**, subtítulo blanco, precio y descuento desde los datos, y un botón del mismo color de acento. Así escalan con "Letra grande", cambian con el precio y los lee el lector de pantalla.

## Ideas para la próxima ronda de imágenes

- **Banners con la misma lógica, listos para más campañas:** Día del Padre/Madre, Fiestas Patrias, Vuelta a clases, Año Nuevo; cada uno con el producto a la derecha, fondo negro transparente y brillo del color de acento.
- **Ofertas oscuras de los otros 6 productos en oferta** (Zuko, Watt's, Jugo Guallarauco, Leche Soprole, Chicle Loop, Rama de Leche) en el mismo formato que Crush/Mecano.
- **Banner morado "Exclusivo online"** con productos propios y brillo morado (hoy solo hay dorado).
- **Estados en el mismo estilo ilustrado de la canasta** (hoy los nuevos son planos): sin direcciones, sesión expirada, sin conexión.
- **Íconos de seguimiento más grandes y animables** (caja, bolsa, camioneta, puerta) para una pantalla de pedido más viva.
- **Fotos "en uso" para los 29 productos restantes**, empezando por los más vendidos.
- **Avatares redondos** (canasta, manzana, estrella, camioneta) para el perfil.
- **Escena del escudo oficial** en bolsa y camioneta, sin fotos de personas, para despacho y bienvenida.
