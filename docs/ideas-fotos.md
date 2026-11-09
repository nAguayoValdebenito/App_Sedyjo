# Ideas de fotos e ilustraciones para la app de Comercial Sedyjo

Objetivo: reemplazar las fotos actuales (cada una con su propio fondo, luz y resolución) por un set coherente. Hoy el mayor freno visual de la maqueta son las fotos de producto; el resto de la interfaz ya está resuelto.

**Regla de oro:** todo con fondo **transparente** (PNG o WebP con alfa) para que funcione igual en modo claro y oscuro y sobre los pasteles de cada categoría. Las sombras van aparte o muy suaves.

## Estilo común (para que todo parezca de la misma mano)

- **Luz:** suave, desde arriba a la izquierda, sin reflejos duros ni flash directo.
- **Ángulo:** producto levemente de tres cuartos (unos 15° hacia arriba), etiqueta bien legible.
- **Encuadre:** el producto ocupa un 80 % del cuadro, centrado, con 10 % de aire por lado.
- **Sombra:** una sombra de contacto muy suave debajo (gris cálido al 12 %), nunca negra dura.
- **Color:** saturación natural; que los rojos, naranjas y verdes de los envases se vean vivos (los pasteles de fondo son cálidos y suaves).
- **Formato:** WebP con transparencia, 1200 × 1200 px (cuadrado), menos de 120 KB. Nombre igual al `slug` del producto (por ejemplo `bebida-crush-orange-lata-350-ml.webp`).

## 1. Prioridad alta: fotos de producto (35 productos)

| Qué | Para qué pantalla | Detalle |
|---|---|---|
| Producto aislado, fondo transparente, cuadrado 1200 × 1200 | Tarjetas, ficha, carrito, pedidos, avisos | Un archivo por producto. Empezar por los 12 que aparecen en Inicio y Ofertas (Coca-Cola, Crush, Zuko, Jugo Mango, Néctar Watt's, Leche chocolate, Chocolates Costa, Chicle Loop, Spaghetti Carozzi, Mermelada, Lasagna, Atún) |
| Mismo producto, **foto de la etiqueta/tabla nutricional** (vista trasera) | Ficha de producto, segunda imagen deslizable | Útil para adultos mayores y para quien revisa ingredientes; 1200 × 1200 |
| Producto **en uso** (opcional, 6 a 8 productos estrella) | Ficha de producto y banners | Ejemplo: lata de bebida con vaso y hielo, plato de fideos, taza de té |

Sugerencia de producción: fotografiar sobre fondo blanco o gris liso con luz de caja, y recortar con un removedor de fondo; revisar a mano bordes de latas y envases brillantes.

## 2. Banners de portada (3 claros + 2 oscuros)

| Banner | Composición sugerida | Tamaño |
|---|---|---|
| **Abarrotes de todos los días** (verde) | Arroz, fideos, conservas y duraznos apilados en una pequeña "montaña" de despensa, vistos desde un poco arriba, sobre transparente; dejar el 45 % izquierdo libre para el texto | 1080 × 540, transparente |
| **Dulces y chocolates** (verde oscuro) | Chocolates y caramelos "cayendo" en diagonal, con una barra partida mostrando el interior | 1080 × 540, transparente |
| **Bebidas para compartir** (azul) | Tres botellas y latas en fila con gotas de agua y un par de rodajas de naranja/limón | 1080 × 540, transparente |
| **Galletas y snacks** (oscuro, dorado) | Galletas con luz de borde dorada sobre negro, migas flotando; los productos "brillan" como en vitrina | 960 × 480, fondo negro `#0B0B0F` |
| **Té e infusiones** (oscuro, morado) | Taza humeante y cajas de té con luz de borde morada `#D15BFF`, vapor suave | 960 × 480, fondo negro `#0B0B0F` |

## 3. Categorías (5 + "todo el catálogo")

Una imagen cuadrada de 600 × 600 px por categoría con **tres productos representativos agrupados** (en lugar de una sola foto): Abarrotes (arroz, fideos, conserva), Bebidas (lata, botella, jugo), Confitería (chocolate, caramelos, chicle), Galletas y snacks (galleta, salmas, snack), Té e infusiones (caja de té, taza, hierbas). Más un ícono de "ver todo" con las cinco siluetas.

## 4. Imágenes de apoyo emocional (adultos mayores y primerizos)

| Escena | Uso | Idea |
|---|---|---|
| Bienvenida | Pantalla de bienvenida | Persona mayor sonriendo en su cocina, mirando el celular, con una bolsa de compras sobre la mesa; luz cálida de mañana, sin marcas visibles. Si se prefiere ilustración: mismo estilo plano con los verdes de la marca |
| Despacho | Línea de tiempo del pedido y aviso "En camino" | Repartidor entregando una bolsa en una puerta (ilustración o foto con la camioneta rotulada "Comercial Sedyjo") |
| Atención por teléfono | Ayuda y contacto | Persona del equipo con audífonos sonriendo, fondo azul de la marca |
| Bodega y armado de pedidos | "Quiénes somos", confianza | Fotos reales del equipo preparando pedidos y de la camioneta de despacho (el negocio no tiene tienda física, así que no hay fachada ni local de atención) |

## 5. Estados vacíos y de resultado (ilustraciones simples, estilo plano)

- **Carrito vacío:** canasta de mimbre (la misma de la carga) vacía, con una hojita.
- **Sin resultados de búsqueda:** lupa sobre una canasta.
- **Sin pedidos aún:** caja abierta con un lazo.
- **Compra exitosa:** bolsas de compra con un check verde grande.
- **Pago no completado:** tarjeta con una marca de alerta, tono tranquilo (no rojo agresivo).
- **Sin conexión:** canasta con un cable desenchufado.
Tamaño: 600 × 480 px, vectorial (SVG) si es posible, solo con paleta de marca.

## 6. Marca y pantalla de carga

- **Logo en vector (SVG) o en 2048 × 2048 con fondo transparente.** El actual es un archivo muy liviano (9 KB), por lo que conviene confirmar su resolución antes de usarlo en tamaños grandes; también conviene una versión **solo del escudo sin texto** para íconos pequeños.
- **Canasta de mimbre** de la carga como ilustración propia (hoy está dibujada por código), en SVG, y los 5 productos que caen (bebida, manzana, leche, croissant, zanahoria) con el mismo estilo; sumar 3 extras (pan, huevos, queso) por si se quiere variar.
- **Patrón de "doodles"** de comercio (carrito, manzana, lata, etc.) en versión clara y oscura, repetible (tileable), para fondos de bienvenida y avisos.

## 7. Notificaciones y tiendas de aplicaciones

| Pieza | Detalle |
|---|---|
| Ícono de la app | 1024 × 1024, el escudo sobre verde `#2E7D5B`, sin texto; versión adaptativa de Android (primer plano 432 × 432 con zona segura) |
| Ícono pequeño de notificación (Android) | Silueta **blanca** monocroma del carrito o la corona, 96 × 96, sin color |
| Imagen grande de notificación | 1024 × 512 por oferta: producto grande a la derecha, precio y porcentaje a la izquierda, sobre negro con dorado (mismo lenguaje de la oferta relámpago) |
| Gráfico de ficha en Google Play | 1024 × 500 |
| Capturas de tienda | 5 pantallas (inicio, ficha, carrito, oferta relámpago, seguimiento) con marco de celular y una frase corta cada una; versión clara y oscura |

## 8. Fotos para el modo oscuro

Mientras los productos tengan fondo transparente, no se necesitan fotos distintas. Solo dos cosas: (1) que las sombras de contacto sean un archivo aparte o muy sutiles, y (2) probar los envases blancos (leche, arroz) sobre el fondo oscuro `#17211C` por si necesitan un borde de luz tenue.

## Orden sugerido de producción

1. Los 12 productos de Inicio y Ofertas (recortados, 1200 × 1200).
2. Los 5 banners (3 claros, 2 oscuros).
3. Logo en vector y canasta de la carga.
4. Resto de los productos (23).
5. Escena de bienvenida y las 6 ilustraciones de estados vacíos.
6. Piezas de tienda y notificaciones.
