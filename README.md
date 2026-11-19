# Comercial Sedyjo — app móvil (base del frontend)

Maqueta de la aplicación móvil hecha con **Flutter**. Es solo **frontend**: pantallas, diseño y navegación con datos de ejemplo. El catálogo, la cuenta y los pedidos no usan ningún servidor. El pago tiene escrita la integración con Webpay Plus a través de un backend que todavía no existe, así que por defecto el pago es simulado y no se cobra nada.

## Ejecutar

```bash
flutter pub get
flutter run -d chrome        # o un emulador / celular conectado; el pago es simulado
flutter test                 # humo visual de todas las pantallas (letra 100 %, 130 %, 160 %; claro y oscuro)
```

### Pago

```bash
# Simulado (por defecto): no se cobra nada
flutter run

# Webpay contra el servidor de prueba local (python tools/webpay_falso.py --puerto 8080).
# El emulador de Android ve el equipo anfitrión como 10.0.2.2
flutter run --dart-define=PAGO_MODO=webpay --dart-define=API_URL=http://10.0.2.2:8080/api/v1

# Estilo producción: backend real por https (en release, en móvil, el modo es siempre Webpay)
flutter run --release --dart-define=API_URL=https://<host>/api/v1
```

Reglas: en la web el pago es siempre simulado; en móvil en release es siempre Webpay (necesita `API_URL`); en debug se usa lo que pida `PAGO_MODO`. La app no contiene el código de comercio ni la llave de Transbank: eso vive en el backend (contrato en `docs/backend-webpay.md`, detalle en `docs/integraciones.md`).

Para mostrarla en el navegador como celular: `flutter build web --release --no-web-resources-cdn` y abrir `build/web` con un servidor local (ver `demo-cliente/`).

En pantallas anchas se ve dentro de un celular con un panel lateral para saltar entre vistas. Parámetros útiles en la dirección: `?cliente=1` (solo el celular), `?letra=1.3` (tamaño de letra), `?splash=0.5` (congela la carga).

## Estructura

```
lib/
  main.dart            arranque, marco de celular y panel de vistas
  app/                 tema (colores por rol, modo claro/oscuro, tipografía) y datos de ejemplo
  pago/                pago con Webpay: configuración, pasarelas (simulada y Webpay), filtro del WebView y flujo
  pantallas/           una archivo por pantalla (inicio, categorías, ficha, carrito, pago, cuenta…)
  ui/                  componentes compartidos (botones, tarjetas, banners, campos)
assets/
  data/productos.json  productos de ejemplo
  img/                 fotos, banners, ilustraciones y logo
  fonts/               Bricolage Grotesque y Figtree
test/                  pruebas de pantallas y de comportamiento
tools/                 webpay_falso.py: servidor de prueba del pago (solo desarrollo)
docs/                  auditoría de diseño, ideas de imágenes, progreso e integraciones (backend-webpay.md: guía del pago para el backend)
demo-cliente/          lanzador portátil para mostrar la maqueta en otro Windows
```

## Diseño

- Paleta de la web de Sedyjo: verde, azul de apoyo, rojo solo en descuentos; dorado y morado solo sobre negro.
- Íconos Lucide, sin emojis. Texto real en banners (nada de texto dentro de las imágenes).
- Modo claro, oscuro y automático; letra ajustable; opción de reducir animaciones.
- No hay retiro en tienda (el negocio no tiene tienda física) ni se menciona una zona de despacho.
