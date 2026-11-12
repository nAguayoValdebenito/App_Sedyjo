import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app/datos.dart';
import '../app/tema.dart';
import '../ui/componentes.dart';
import 'inicio.dart' show abrirProducto;
import 'tienda.dart';

(Color, Color, IconData) _estiloEstado(EstadoPedido e) => switch (e) {
      EstadoPedido.recibido => (C.oscuro ? const Color(0xFF1E2B40) : const Color(0xFFE6EEF9), C.oscuro ? const Color(0xFF9DBDF5) : C.azulOscuro, LucideIcons.receipt),
      EstadoPedido.preparando => (C.oscuro ? const Color(0xFF3A2E14) : const Color(0xFFFFF1D6), C.oscuro ? const Color(0xFFF0C36B) : const Color(0xFF7A4B00), LucideIcons.package),
      EstadoPedido.enCamino => (C.verdeSuave, C.verdeProfundo, LucideIcons.truck),
      EstadoPedido.entregado => (C.grisFondo, C.tinta, LucideIcons.packageCheck),
    };

class InsigniaEstado extends StatelessWidget {
  const InsigniaEstado(this.e, {super.key, this.retiro = false});
  final EstadoPedido e;
  final bool retiro;

  @override
  Widget build(BuildContext context) {
    final (fondo, color, icono) = _estiloEstado(e);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Esp.x3, vertical: 7),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(R.l)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icono, size: Ico.s, color: color),
        const SizedBox(width: Esp.x2),
        Text(e.textoPara(retiro), style: T.etiqueta.copyWith(color: color, fontSize: 15)),
      ]),
    );
  }
}

class PedidosPantalla extends StatelessWidget {
  const PedidosPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          const BarraSuperior('Mis pedidos'),
          Expanded(
            child: estado.pedidos.isEmpty
                ? ListView(padding: const EdgeInsets.fromLTRB(Esp.x6, Esp.x8, Esp.x6, Esp.x8), children: [
                    const IlustracionEstado('sin-pedidos.webp'),
                    const SizedBox(height: Esp.x6),
                    Text('Aún no tienes pedidos', textAlign: TextAlign.center, style: T.titulo2),
                    const SizedBox(height: Esp.x2),
                    Text('Cuando compres, aquí verás cómo va cada pedido.', textAlign: TextAlign.center, style: T.cuerpo.copyWith(color: C.grisMedio)),
                    const SizedBox(height: Esp.x6),
                    Boton('Ir a comprar', icono: LucideIcons.shoppingBasket, onTap: () {
                      Navigator.of(context).popUntil((r) => r.isFirst);
                      estado.irAPestana(0);
                    }),
                  ])
                : ListView(padding: const EdgeInsets.fromLTRB(Esp.x5, Esp.x2, Esp.x5, Esp.x8), children: [
              for (final p in estado.pedidos) ...[
                Tocable(
                  etiqueta: 'Pedido ${p.numero}, ${p.estado.textoPara(p.retiro)}, ${clp(p.total)}',
                  onTap: () => irA(context, DetallePedidoPantalla(p)),
                  child: Panel(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // Con letra grande la insignia baja a otra línea en vez de empujar el número fuera de la tarjeta.
                      SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 6,
                          children: [Text(p.numero, style: T.titulo3), InsigniaEstado(p.estado, retiro: p.retiro)],
                        ),
                      ),
                      const SizedBox(height: Esp.x1),
                      Text(p.fecha, style: T.apoyo),
                      const SizedBox(height: Esp.x3),
                      Row(children: [
                        for (final id in p.lineas.keys.take(3)) ...[
                          ClipRRect(borderRadius: BorderRadius.circular(R.s), child: SizedBox(width: 50, height: 50, child: FotoProducto(Catalogo.porId(id)))),
                          const SizedBox(width: Esp.x2),
                        ],
                        if (p.lineas.length > 3) Text('+${p.lineas.length - 3}', style: T.cuerpoFuerte),
                        const Spacer(),
                        Icon(LucideIcons.chevronRight, color: C.grisMedio),
                      ]),
                      const SizedBox(height: Esp.x3),
                      // El total va en su propia línea: un precio nunca se abrevia.
                      SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [Text('Total', style: T.apoyo), Text(clp(p.total), style: T.titulo2)],
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: Esp.x3),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

class DetallePedidoPantalla extends StatelessWidget {
  const DetallePedidoPantalla(this.p, {super.key});
  final Pedido p;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          BarraSuperior('Pedido ${p.numero}'),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(Esp.x5, Esp.x1, Esp.x5, Esp.x5), children: [
              Wrap(spacing: 12, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [InsigniaEstado(p.estado, retiro: p.retiro), Text(p.fecha, style: T.apoyo)]),
              const SizedBox(height: Esp.x3),
              Center(
                child: ExcludeSemantics(
                  child: Image.asset('assets/img/seguimiento/${switch (p.estado) {
                    EstadoPedido.recibido => 'recibido',
                    EstadoPedido.preparando => 'preparando',
                    EstadoPedido.enCamino => 'en-camino',
                    EstadoPedido.entregado => 'entregado',
                  }}.webp', height: 132, cacheHeight: 400, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: Esp.x3),
              _Linea(p.estado),
              const SizedBox(height: Esp.x6),
              if (p.franja != null || p.notas != null) ...[
                Panel(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (p.franja != null) Row(children: [Icon(LucideIcons.calendarClock, size: Ico.s, color: C.verdeOscuro), const SizedBox(width: Esp.x2), Expanded(child: Text(p.franja!, style: T.cuerpoM))]),
                    if (p.notas != null) ...[
                      if (p.franja != null) const SizedBox(height: Esp.x2),
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(LucideIcons.messageSquareText, size: Ico.s, color: C.verdeOscuro), const SizedBox(width: Esp.x2), Expanded(child: Text(p.notas!, style: T.cuerpoM))]),
                    ],
                  ]),
                ),
                const SizedBox(height: Esp.x6),
              ],
              if (p.retiro) ...[
                const TarjetaTienda(),
                const SizedBox(height: Esp.x4),
              ],
              Text('Productos', style: T.titulo3),
              const SizedBox(height: Esp.x3),
              Panel(
                padding: const EdgeInsets.symmetric(horizontal: Esp.x3, vertical: Esp.x2),
                child: Column(children: [
                  for (final (i, e) in p.lineas.entries.indexed) ...[
                    Tocable(
                      etiqueta: 'Ver ${Catalogo.porId(e.key).nombre}',
                      onTap: () => abrirProducto(context, Catalogo.porId(e.key)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: Esp.x3),
                        child: Row(children: [
                          ClipRRect(borderRadius: BorderRadius.circular(R.s), child: SizedBox(width: 54, height: 54, child: FotoProducto(Catalogo.porId(e.key)))),
                          const SizedBox(width: Esp.x3),
                          Expanded(child: Text('${e.value} × ${Catalogo.porId(e.key).nombre}', maxLines: 2, overflow: TextOverflow.ellipsis, style: T.cuerpoM)),
                          const SizedBox(width: Esp.x2),
                          Text(clp(Catalogo.porId(e.key).precioFinal * e.value), style: T.cuerpoMFuerte),
                        ]),
                      ),
                    ),
                    if (i < p.lineas.length - 1) const Divider(height: 1),
                  ],
                ]),
              ),
              const SizedBox(height: Esp.x4),
              Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(LucideIcons.mapPin, color: C.verdeOscuro),
                    const SizedBox(width: Esp.x3),
                    Expanded(child: Text('Entrega en ${p.direccion}', style: T.cuerpoM)),
                  ]),
                  const Divider(height: 28),
                  Row(children: [
                    Expanded(child: Text('Total pagado', style: T.titulo3)),
                    Text(clp(p.total), style: T.titulo2),
                  ]),
                ]),
              ),
              const SizedBox(height: Esp.x6),
              Boton('Volver a comprar', icono: LucideIcons.refreshCw, onTap: () {
                for (final e in p.lineas.entries) {
                  estado.agregar(Catalogo.porId(e.key), e.value);
                }
                Navigator.of(context).popUntil((r) => r.isFirst);
                estado.irAPestana(3);
              }),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Línea de tiempo del pedido: al abrir, el progreso se llena paso a paso hasta el estado actual.
class _Linea extends StatefulWidget {
  const _Linea(this.actual);
  final EstadoPedido actual;

  @override
  State<_Linea> createState() => _LineaState();
}

class _LineaState extends State<_Linea> with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(vsync: this, duration: Duration(milliseconds: 250 + 330 * widget.actual.index));
  bool _iniciado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    _iniciado = true;
    if (sinMovimiento(context)) {
      _ctl.value = 1;
    } else {
      _ctl.forward();
    }
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actual = widget.actual;
    const pasos = [
      (EstadoPedido.recibido, 'Pedido recibido', 'Ya tenemos tu pedido'),
      (EstadoPedido.preparando, 'Preparando', 'Estamos armando tu compra'),
      (EstadoPedido.enCamino, 'En camino', 'Va rumbo a tu dirección'),
      (EstadoPedido.entregado, 'Entregado', 'Que lo disfrutes'),
    ];
    return AnimatedBuilder(
      animation: _ctl,
      builder: (context, _) {
        // El avance recorre los pasos hasta el actual: 0 → actual.index.
        final avance = Curves.easeOutCubic.transform(_ctl.value) * actual.index;
        return Panel(
          padding: const EdgeInsets.fromLTRB(Esp.x4, Esp.x4, Esp.x4, Esp.x2),
          child: Column(children: [
            for (final (i, p) in pasos.indexed)
              Semantics(
                label: '${p.$2}${p.$1.index < actual.index ? ', listo' : p.$1 == actual ? ', ahora' : ', pendiente'}',
                child: IntrinsicHeight(
                  child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    SizedBox(
                      width: 36,
                      child: Column(children: [
                        Builder(builder: (context) {
                          final alcanzado = i <= avance + .0001;
                          return Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: alcanzado ? C.verde : C.superficie,
                              shape: BoxShape.circle,
                              border: Border.all(color: alcanzado ? C.verde : C.bordeControl, width: 2),
                            ),
                            child: p.$1.index < actual.index
                                ? (alcanzado ? const Icon(LucideIcons.check, size: Ico.s, color: Colors.white) : null)
                                : p.$1 == actual
                                    ? (alcanzado ? Center(child: Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))) : null)
                                    : null,
                          );
                        }),
                        if (i < pasos.length - 1)
                          Expanded(
                            // El tramo se llena de arriba abajo con un degradado de corte duro (sin medir hijos extra).
                            child: Container(
                              width: 3,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [C.verde, C.verde, C.borde, C.borde],
                                  stops: [0, (avance - i).clamp(0.0, 1.0), (avance - i).clamp(0.0, 1.0), 1],
                                ),
                              ),
                            ),
                          ),
                      ]),
                    ),
                    const SizedBox(width: Esp.x3),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: Esp.x5),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p.$2, style: T.cuerpoFuerte.copyWith(color: p.$1.index <= actual.index ? C.tinta : C.grisTexto)),
                          Text(p.$3, style: T.apoyo),
                        ]),
                      ),
                    ),
                  ]),
                ),
              ),
          ]),
        );
      },
    );
  }
}

/// Seguimiento sin cuenta: número de pedido + correo.
class SeguimientoPantalla extends StatefulWidget {
  const SeguimientoPantalla({super.key, this.numero});
  final String? numero;

  @override
  State<SeguimientoPantalla> createState() => _SeguimientoPantallaState();
}

class _SeguimientoPantallaState extends State<SeguimientoPantalla> {
  late final _numero = TextEditingController(text: widget.numero ?? '');
  final _correo = TextEditingController();
  Pedido? _pedido;
  bool _intentado = false;
  bool _noEncontrado = false;

  @override
  void initState() {
    super.initState();
    // Desde la compra recién hecha se muestra ese pedido directamente.
    if (widget.numero != null) _pedido = estado.buscarPedido(widget.numero!);
  }

  @override
  void dispose() {
    _numero.dispose();
    _correo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          const BarraSuperior('Seguir mi pedido'),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(Esp.x5, Esp.x1, Esp.x5, Esp.x8), children: [
              if (_pedido == null) ...[
                Text('Escribe el número que te enviamos al comprar y el correo que usaste. No necesitas cuenta.', style: T.cuerpo.copyWith(color: C.grisMedio)),
                const SizedBox(height: Esp.x5),
                Campo('Número de pedido', controlador: _numero, icono: LucideIcons.receipt, ayuda: 'Ejemplo: SED-1042', error: _intentado && _numero.text.trim().isEmpty ? 'Escribe el número de tu pedido.' : null, alCambiar: (_) => setState(() => _noEncontrado = false)),
                const SizedBox(height: Esp.x4),
                Campo('Correo electrónico', controlador: _correo, teclado: TextInputType.emailAddress, icono: LucideIcons.mail, error: _intentado && !_correo.text.contains('@') ? 'Escribe el correo de la compra.' : null, alCambiar: (_) => setState(() {})),
                const SizedBox(height: Esp.x6),
                if (_noEncontrado) ...[
                  Semantics(
                    liveRegion: true,
                    child: Panel(
                      fondo: C.error.withValues(alpha: .10),
                      borde: C.error,
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(LucideIcons.circleAlert, color: C.error, size: Ico.m),
                        const SizedBox(width: Esp.x3),
                        Expanded(child: Text('No encontramos ese pedido. Revisa que el número y el correo sean los de tu compra.', style: T.cuerpoM)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: Esp.x4),
                ],
                Boton('Buscar mi pedido', icono: LucideIcons.search, onTap: () {
                  setState(() => _intentado = true);
                  if (_numero.text.trim().isNotEmpty && _correo.text.contains('@')) {
                    final p = estado.buscarPedido(_numero.text, correo: _correo.text);
                    setState(() {
                      _pedido = p;
                      _noEncontrado = p == null;
                    });
                  }
                }),
              ] else ...[
                Panel(
                  fondo: C.verdeSuave,
                  borde: C.verdeSuave,
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Pedido', style: T.apoyo.copyWith(color: C.verdeOscuro)),
                      Text(_pedido!.numero, style: T.titulo2.copyWith(color: C.verdeProfundo)),
                    ])),
                    InsigniaEstado(_pedido!.estado, retiro: _pedido!.retiro),
                  ]),
                ),
                const SizedBox(height: Esp.x4),
                _Linea(_pedido!.estado),
                const SizedBox(height: Esp.x4),
                Boton('Buscar otro pedido', estilo: EstiloBoton.suave, onTap: () => setState(() {
                      _pedido = null;
                      _noEncontrado = false;
                    })),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}
