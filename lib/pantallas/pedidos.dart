import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app/datos.dart';
import '../app/tema.dart';
import '../ui/componentes.dart';
import 'inicio.dart' show abrirProducto;

(Color, Color, IconData) _estiloEstado(EstadoPedido e) => switch (e) {
      EstadoPedido.recibido => (C.oscuro ? const Color(0xFF1E2B40) : const Color(0xFFE6EEF9), C.oscuro ? const Color(0xFF9DBDF5) : C.azulOscuro, LucideIcons.receipt),
      EstadoPedido.preparando => (C.oscuro ? const Color(0xFF3A2E14) : const Color(0xFFFFF1D6), C.oscuro ? const Color(0xFFF0C36B) : const Color(0xFF7A4B00), LucideIcons.package),
      EstadoPedido.enCamino => (C.verdeSuave, C.verdeProfundo, LucideIcons.truck),
      EstadoPedido.entregado => (C.grisFondo, C.tinta, LucideIcons.packageCheck),
    };

class InsigniaEstado extends StatelessWidget {
  const InsigniaEstado(this.e, {super.key});
  final EstadoPedido e;

  @override
  Widget build(BuildContext context) {
    final (fondo, color, icono) = _estiloEstado(e);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icono, size: 17, color: color),
        const SizedBox(width: 6),
        Text(e.texto, style: T.etiqueta.copyWith(color: color, fontSize: 15)),
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
                ? ListView(padding: const EdgeInsets.fromLTRB(24, 32, 24, 28), children: [
                    const IlustracionEstado('sin-pedidos.webp'),
                    const SizedBox(height: 22),
                    Text('Aún no tienes pedidos', textAlign: TextAlign.center, style: T.titulo2),
                    const SizedBox(height: 8),
                    Text('Cuando compres, aquí verás cómo va cada pedido.', textAlign: TextAlign.center, style: T.cuerpo.copyWith(color: C.grisMedio)),
                    const SizedBox(height: 24),
                    Boton('Ir a comprar', icono: LucideIcons.shoppingBasket, onTap: () {
                      Navigator.of(context).popUntil((r) => r.isFirst);
                      estado.irAPestana(0);
                    }),
                  ])
                : ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 28), children: [
              for (final p in estado.pedidos) ...[
                Tocable(
                  etiqueta: 'Pedido ${p.numero}, ${p.estado.texto}, ${clp(p.total)}',
                  onTap: () => irA(context, DetallePedidoPantalla(p)),
                  child: Panel(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(p.numero, style: T.titulo3)),
                        InsigniaEstado(p.estado),
                      ]),
                      const SizedBox(height: 4),
                      Text(p.fecha, style: T.apoyo),
                      const SizedBox(height: 14),
                      Row(children: [
                        for (final id in p.lineas.keys.take(3)) ...[
                          ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(width: 50, height: 50, child: FotoProducto(Catalogo.porId(id)))),
                          const SizedBox(width: 6),
                        ],
                        if (p.lineas.length > 3) Text('+${p.lineas.length - 3}', style: T.cuerpoFuerte),
                        const Spacer(),
                        Icon(LucideIcons.chevronRight, color: C.grisMedio),
                      ]),
                      const SizedBox(height: 12),
                      // El total va en su propia línea: un precio nunca se abrevia.
                      Row(children: [
                        Text('Total', style: T.apoyo),
                        const Spacer(),
                        Text(clp(p.total), style: T.titulo2),
                      ]),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),
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
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 20), children: [
              Wrap(spacing: 12, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [InsigniaEstado(p.estado), Text(p.fecha, style: T.apoyo)]),
              const SizedBox(height: 14),
              Center(
                child: ExcludeSemantics(
                  child: Image.asset('assets/img/seguimiento/${switch (p.estado) {
                    EstadoPedido.recibido => 'recibido',
                    EstadoPedido.preparando => 'preparando',
                    EstadoPedido.enCamino => 'en-camino',
                    EstadoPedido.entregado => 'entregado',
                  }}.webp', height: 132, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 10),
              _Linea(p.estado),
              const SizedBox(height: 24),
              Text('Productos', style: T.titulo3),
              const SizedBox(height: 12),
              Panel(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Column(children: [
                  for (final (i, e) in p.lineas.entries.indexed) ...[
                    Tocable(
                      etiqueta: 'Ver ${Catalogo.porId(e.key).nombre}',
                      onTap: () => abrirProducto(context, Catalogo.porId(e.key)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(children: [
                          ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 54, height: 54, child: FotoProducto(Catalogo.porId(e.key)))),
                          const SizedBox(width: 12),
                          Expanded(child: Text('${e.value} × ${Catalogo.porId(e.key).nombre}', maxLines: 2, overflow: TextOverflow.ellipsis, style: T.cuerpo.copyWith(fontSize: 16))),
                          const SizedBox(width: 8),
                          Text(clp(Catalogo.porId(e.key).precioFinal * e.value), style: T.cuerpoFuerte.copyWith(fontSize: 16)),
                        ]),
                      ),
                    ),
                    if (i < p.lineas.length - 1) const Divider(height: 1),
                  ],
                ]),
              ),
              const SizedBox(height: 18),
              Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(LucideIcons.mapPin, color: C.verdeOscuro),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Entrega en ${p.direccion}', style: T.cuerpo.copyWith(fontSize: 16))),
                  ]),
                  const Divider(height: 28),
                  Row(children: [
                    Expanded(child: Text('Total pagado', style: T.titulo3)),
                    Text(clp(p.total), style: T.titulo2),
                  ]),
                ]),
              ),
              const SizedBox(height: 22),
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

class _Linea extends StatelessWidget {
  const _Linea(this.actual);
  final EstadoPedido actual;

  @override
  Widget build(BuildContext context) {
    const pasos = [
      (EstadoPedido.recibido, 'Pedido recibido', 'Ya tenemos tu pedido'),
      (EstadoPedido.preparando, 'Preparando', 'Estamos armando tu compra'),
      (EstadoPedido.enCamino, 'En camino', 'Va rumbo a tu dirección'),
      (EstadoPedido.entregado, 'Entregado', 'Que lo disfrutes'),
    ];
    return Panel(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
      child: Column(children: [
        for (final (i, p) in pasos.indexed)
          Semantics(
            label: '${p.$2}${p.$1.index < actual.index ? ', listo' : p.$1 == actual ? ', ahora' : ', pendiente'}',
            child: IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                SizedBox(
                  width: 36,
                  child: Column(children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: p.$1.index <= actual.index ? C.verde : C.superficie,
                        shape: BoxShape.circle,
                        border: Border.all(color: p.$1.index <= actual.index ? C.verde : C.bordeControl, width: 2),
                      ),
                      child: p.$1.index < actual.index
                          ? const Icon(LucideIcons.check, size: 18, color: Colors.white)
                          : p.$1 == actual
                              ? Center(child: Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)))
                              : null,
                    ),
                    if (i < pasos.length - 1) Expanded(child: Container(width: 3, color: p.$1.index < actual.index ? C.verde : C.borde)),
                  ]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
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
  late bool _auto = widget.numero != null;

  @override
  void initState() {
    super.initState();
    if (_auto) {
      _pedido = Pedido(widget.numero!, 'Hoy', EstadoPedido.recibido, {2: 1, 32: 1}, 'tu dirección');
    }
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
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 28), children: [
              if (_pedido == null) ...[
                Text('Escribe el número que te enviamos al comprar y el correo que usaste. No necesitas cuenta.', style: T.cuerpo.copyWith(color: C.grisMedio)),
                const SizedBox(height: 20),
                Campo('Número de pedido', controlador: _numero, icono: LucideIcons.receipt, ayuda: 'Ejemplo: SED-1042', error: _intentado && _numero.text.trim().isEmpty ? 'Escribe el número de tu pedido.' : null, alCambiar: (_) => setState(() {})),
                const SizedBox(height: 16),
                Campo('Correo electrónico', controlador: _correo, teclado: TextInputType.emailAddress, icono: LucideIcons.mail, error: _intentado && !_correo.text.contains('@') ? 'Escribe el correo de la compra.' : null, alCambiar: (_) => setState(() {})),
                const SizedBox(height: 22),
                Boton('Buscar mi pedido', icono: LucideIcons.search, onTap: () {
                  setState(() => _intentado = true);
                  if (_numero.text.trim().isNotEmpty && _correo.text.contains('@')) {
                    setState(() => _pedido = Pedido(_numero.text.trim().toUpperCase(), '3 nov 2026', EstadoPedido.enCamino, {2: 2, 31: 1}, 'Los Aromos 1234'));
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
                    InsigniaEstado(_pedido!.estado),
                  ]),
                ),
                const SizedBox(height: 16),
                _Linea(_pedido!.estado),
                const SizedBox(height: 16),
                Boton('Buscar otro pedido', estilo: EstiloBoton.suave, onTap: () => setState(() {
                      _pedido = null;
                      _auto = false;
                    })),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}
