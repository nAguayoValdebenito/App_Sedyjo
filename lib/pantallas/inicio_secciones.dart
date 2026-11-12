part of 'inicio.dart';

// Secciones de la parte baja del inicio: Exclusivo online, beneficios y ayuda (parte de inicio.dart).

/// "Exclusivo online": único lugar de la interfaz donde viven el dorado y el morado, siempre sobre negro.
class _SeccionExclusivo extends StatelessWidget {
  const _SeccionExclusivo();

  @override
  Widget build(BuildContext context) {
    final productos = Catalogo.productos.where((p) => p.categoria == 'Galletas y Snacks' || p.categoria == 'Té e Infusiones').take(6).toList();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: Esp.x3),
      padding: const EdgeInsets.only(bottom: Esp.x6),
      color: C.negro,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Esp.x5, Esp.x8, Esp.x5, Esp.x1),
          child: Row(children: [
            const Icon(LucideIcons.sparkles, color: C.oro, size: Ico.m),
            const SizedBox(width: Esp.x3),
            Expanded(child: Text('Exclusivo online', style: T.titulo2.copyWith(color: C.oro))),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Esp.x5, 0, Esp.x5, Esp.x4),
          child: Text('Selección que solo encuentras en la app y la web.', style: T.cuerpo.copyWith(color: const Color(0xFFD7D7E0), fontSize: 16)),
        ),
        const FilaHorizontal(hijos: [
          _BannerOscuro('Galletas y snacks', 'Para cada antojo', 'hero/galletas.webp', 'Galletas y Snacks', C.oro),
          _BannerOscuro('Té e infusiones', 'Una pausa para ti', 'hero/te.webp', 'Té e Infusiones', C.morado),
        ]),
        const SizedBox(height: Esp.x4),
        FilaHorizontal(hijos: [for (final p in productos) SizedBox(width: 180, child: _TarjetaOscura(p))]),
      ]),
    );
  }
}

class _BannerOscuro extends StatelessWidget {
  const _BannerOscuro(this.titulo, this.sub, this.imagen, this.categoria, this.acento);
  final String titulo;
  final String sub;
  final String imagen;
  final String categoria;
  final Color acento;

  @override
  Widget build(BuildContext context) {
    return Tocable(
      etiqueta: '$titulo. $sub',
      onTap: () => irA(context, CategoriaPantalla(categoria)),
      child: Container(
        width: 310,
        constraints: const BoxConstraints(minHeight: 150),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: C.carbon,
          borderRadius: BorderRadius.circular(R.l),
          border: Border.all(color: acento.withValues(alpha: .55), width: 1.5),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Esp.x4, Esp.x4, Esp.x1, Esp.x4),
              child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(titulo, style: T.titulo3.copyWith(color: acento, fontSize: 22)),
                const SizedBox(height: Esp.x1),
                Text(sub, style: T.apoyo.copyWith(color: Colors.white, fontSize: 15)),
                const SizedBox(height: Esp.x3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: Esp.x4, vertical: Esp.x3),
                  decoration: BoxDecoration(color: acento, borderRadius: BorderRadius.circular(R.s)),
                  child: Text('Comprar', style: T.boton.copyWith(color: C.negro, fontSize: 16)),
                ),
              ]),
            ),
          ),
          SizedBox(width: 130, child: Image.asset('assets/img/$imagen', fit: BoxFit.contain, cacheWidth: 390, semanticLabel: '')),
        ]),
      ),
    );
  }
}

class _TarjetaOscura extends StatelessWidget {
  const _TarjetaOscura(this.p);
  final Producto p;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: C.carbon, borderRadius: BorderRadius.circular(R.l), border: Border.all(color: C.carbonBorde)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
          child: Tocable(
            etiqueta: 'Ver ${p.nombre}',
            onTap: () => abrirProducto(context, p),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              AspectRatio(aspectRatio: 1.25, child: FotoProducto(p, fondo: const Color(0xFF22222C))),
              Padding(
                padding: const EdgeInsets.fromLTRB(Esp.x3, Esp.x3, Esp.x3, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.nombre, maxLines: 3, overflow: TextOverflow.ellipsis, style: T.cuerpo.copyWith(color: Colors.white, fontSize: 16, height: 1.25, fontWeight: FontWeight.w600)),
                  const SizedBox(height: Esp.x2),
                  Text(clp(p.precioFinal), style: T.precio.copyWith(color: C.oro)),
                ]),
              ),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Esp.x3, Esp.x2, Esp.x3, Esp.x3),
          child: Boton('Agregar', icono: LucideIcons.plus, estilo: EstiloBoton.dorado, alto: 50, alTocarEn: (ctx) => agregarAlCarrito(ctx, p, oscuro: true)),
        ),
      ]),
    );
  }
}

class _Beneficios extends StatelessWidget {
  const _Beneficios();

  @override
  Widget build(BuildContext context) {
    const filas = [
      (LucideIcons.truck, 'Despacho en 24 a 48 horas', 'Gratis desde \$39.990'),
      (LucideIcons.store, 'Retira en nuestra tienda', 'Av. Collao 2480, Concepción'),
      (LucideIcons.shieldCheck, 'Pago seguro con Webpay', 'Tarjeta de débito o crédito'),
      (LucideIcons.phone, 'Te atendemos por teléfono', 'Llama o escribe por WhatsApp'),
    ];
    return Panel(
      padding: const EdgeInsets.symmetric(vertical: Esp.x2, horizontal: Esp.x4),
      child: Column(children: [
        for (var i = 0; i < filas.length; i++) ...[
          // La fila de la tienda se toca para ver cómo llegar; las demás solo informan.
          Tocable(
            etiqueta: filas[i].$1 == LucideIcons.store ? '${filas[i].$2}, ${filas[i].$3}. Ver cómo llegar' : '${filas[i].$2}, ${filas[i].$3}',
            onTap: filas[i].$1 == LucideIcons.store ? () => irA(context, const TiendaPantalla()) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Esp.x3),
              child: Row(children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: C.verdeSuave, shape: BoxShape.circle),
                  child: Icon(filas[i].$1, color: C.verdeOscuro, size: Ico.m),
                ),
                const SizedBox(width: Esp.x3),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(filas[i].$2, style: T.cuerpoFuerte),
                    Text(filas[i].$3, style: T.apoyo),
                  ]),
                ),
                if (filas[i].$1 == LucideIcons.store) Icon(LucideIcons.chevronRight, color: C.verdeOscuro),
              ]),
            ),
          ),
          if (i < filas.length - 1) const Divider(height: 1),
        ],
      ]),
    );
  }
}

class _AyudaTarjeta extends StatelessWidget {
  const _AyudaTarjeta();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Esp.x5),
      decoration: BoxDecoration(color: C.verdeBanner, borderRadius: BorderRadius.circular(R.l)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('¿Necesitas ayuda para comprar?', style: T.titulo3.copyWith(color: Colors.white, fontSize: 22)),
        const SizedBox(height: Esp.x2),
        Text('Te acompañamos paso a paso por teléfono.', style: T.cuerpo.copyWith(color: C.verdePalido, fontSize: 16)),
        const SizedBox(height: Esp.x4),
        Tocable(
          etiqueta: 'Llamar a Sedyjo al $telefonoVisible',
          onTap: () => mostrarContacto(context),
          child: Container(
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(R.m)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(LucideIcons.phone, color: C.verdeBanner, size: Ico.m),
              const SizedBox(width: Esp.x3),
              Text('Llamar $telefonoVisible', style: T.boton.copyWith(color: C.verdeBanner, fontSize: 17)),
            ]),
          ),
        ),
      ]),
    );
  }
}

/// Consejo para quien empieza: tres cosas que conviene saber. Se cierra con un toque y no vuelve.
class _ConsejoInicio extends StatelessWidget {
  const _ConsejoInicio();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: estado,
      builder: (context, _) {
        // Ya no hace falta cuando la persona miró un producto, guardó un favorito o llenó el carrito.
        final yaUso = estado.vistos.isNotEmpty || estado.favoritos.isNotEmpty || estado.cantidadCarrito > 0;
        if (estado.consejoInicioVisto || yaUso) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(Esp.x5, Esp.x3, Esp.x5, 0),
          child: Container(
            padding: const EdgeInsets.fromLTRB(Esp.x4, Esp.x3, Esp.x2, Esp.x3),
            decoration: BoxDecoration(color: C.verdeSuave, borderRadius: BorderRadius.circular(R.l)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(LucideIcons.lightbulb, color: C.verdeOscuro, size: Ico.m),
              const SizedBox(width: Esp.x3),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Para empezar', style: T.cuerpoFuerte.copyWith(color: C.verdeProfundo)),
                  const SizedBox(height: 2),
                  Text('Busca arriba lo que necesitas, toca el corazón para guardar tus favoritos y mira tu compra en el carrito de abajo.', style: T.apoyo.copyWith(color: C.verdeOscuro)),
                ]),
              ),
              BotonIcono(LucideIcons.x, 'Cerrar el consejo', onTap: estado.cerrarConsejoInicio, fondo: Colors.transparent, color: C.verdeOscuro),
            ]),
          ),
        );
      },
    );
  }
}
