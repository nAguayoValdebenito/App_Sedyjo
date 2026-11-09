# Comercial Sedyjo — app móvil (base del frontend)

Maqueta de la aplicación móvil hecha con **Flutter**. Es solo **frontend**: pantallas, diseño y navegación con datos de ejemplo. No hay conexión con ningún servidor.

## Ejecutar

```bash
flutter pub get
flutter run -d chrome        # o un emulador / celular conectado
flutter test                 # humo visual de todas las pantallas (letra 100 %, 130 %, 160 %; claro y oscuro)
```

Para mostrarla en el navegador como celular: `flutter build web --release --no-web-resources-cdn` y abrir `build/web` con un servidor local (ver `demo-cliente/`).

En pantallas anchas se ve dentro de un celular con un panel lateral para saltar entre vistas. Parámetros útiles en la dirección: `?cliente=1` (solo el celular), `?letra=1.3` (tamaño de letra), `?splash=0.5` (congela la carga).

## Estructura

```
lib/
  main.dart            arranque, marco de celular y panel de vistas
  app/                 tema (colores por rol, modo claro/oscuro, tipografía) y datos de ejemplo
  pantallas/           una archivo por pantalla (inicio, categorías, ficha, carrito, pago, cuenta…)
  ui/                  componentes compartidos (botones, tarjetas, banners, campos)
assets/
  data/productos.json  productos de ejemplo
  img/                 fotos, banners, ilustraciones y logo
  fonts/               Bricolage Grotesque y Figtree
test/                  pruebas de pantallas y de comportamiento
docs/                  auditoría de diseño, ideas de imágenes y progreso
demo-cliente/          lanzador portátil para mostrar la maqueta en otro Windows
```

## Diseño

- Paleta de la web de Sedyjo: verde, azul de apoyo, rojo solo en descuentos; dorado y morado solo sobre negro.
- Íconos Lucide, sin emojis. Texto real en banners (nada de texto dentro de las imágenes).
- Modo claro, oscuro y automático; letra ajustable; opción de reducir animaciones.
- No hay retiro en tienda (el negocio no tiene tienda física) ni se menciona una zona de despacho.
