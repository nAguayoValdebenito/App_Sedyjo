import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app/datos.dart';
import '../app/tema.dart';
import '../ui/componentes.dart';
import 'shell.dart' show mostrarRelampago;

/// Preferencias de avisos: el usuario decide cuántas ofertas ve y si quiere notificaciones push.
class AvisosPantalla extends StatelessWidget {
  const AvisosPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: estado,
      builder: (context, _) {
        const frecuencias = [(5, 'Cada 5 min'), (10, 'Cada 10 min'), (0, 'No mostrar')];
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(children: [
              const BarraSuperior('Avisos y ofertas'),
              Expanded(
                child: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 28), children: [
                  Text('Tú decides cuánto quieres enterarte de las ofertas. Puedes cambiarlo cuando quieras.', style: T.cuerpo.copyWith(color: C.grisMedio)),
                  const SizedBox(height: 22),
                  Text('Ofertas relámpago dentro de la app', style: T.titulo3),
                  const SizedBox(height: 4),
                  Text('Un aviso en la parte de arriba mientras miras la tienda. Se queda hasta que lo cierres y no aparece en el carrito ni en el pago.', style: T.apoyo),
                  const SizedBox(height: 14),
                  Column(children: [
                    for (final (i, f) in frecuencias.indexed) ...[
                      if (i > 0) const SizedBox(height: 8),
                      OpcionFila(texto: f.$2, icono: f.$1 == 0 ? LucideIcons.bellOff : LucideIcons.clock, activo: estado.minutosOfertas == f.$1, alTocar: () => estado.ajustarAvisos(minutos: f.$1)),
                    ],
                  ]),
                  const SizedBox(height: 26),
                  Text('Notificaciones en tu celular', style: T.titulo3),
                  const SizedBox(height: 12),
                  Panel(
                    padding: EdgeInsets.zero,
                    child: Column(children: [
                      _Interruptor(LucideIcons.zap, 'Ofertas del día', 'Máximo 2 al día', estado.pushOfertas, (v) => estado.ajustarAvisos(ofertas: v)),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _Interruptor(LucideIcons.truck, 'Estado de mis pedidos', 'Cuando salga a despacho o llegue', estado.pushPedidos, (v) => estado.ajustarAvisos(pedidos: v)),
                    ]),
                  ),
                  const SizedBox(height: 26),
                  Text('Así se verá', style: T.titulo3),
                  const SizedBox(height: 12),
                  const _PruebaNotificacion(),
                  const SizedBox(height: 18),
                  Boton('Probar oferta relámpago', icono: LucideIcons.zap, onTap: () {
                    Navigator.of(context).popUntil((r) => r.isFirst);
                    estado.irAPestana(0);
                    mostrarRelampago(forzar: true);
                  }),
                ]),
              ),
            ]),
          ),
        );
      },
    );
  }
}

class _Interruptor extends StatelessWidget {
  const _Interruptor(this.icono, this.titulo, this.sub, this.valor, this.cambia);
  final IconData icono;
  final String titulo;
  final String sub;
  final bool valor;
  final ValueChanged<bool> cambia;

  @override
  Widget build(BuildContext context) {
    return Tocable(
      etiqueta: '$titulo, ${valor ? 'activado' : 'desactivado'}',
      onTap: () => cambia(!valor),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: C.verdeSuave, shape: BoxShape.circle),
            child: Icon(icono, color: C.verdeOscuro, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(titulo, style: T.cuerpoFuerte),
              Text(sub, style: T.apoyo),
            ]),
          ),
          Switch(value: valor, onChanged: cambia, activeThumbColor: Colors.white, activeTrackColor: C.verde),
        ]),
      ),
    );
  }
}

/// Simulación de cómo se ve una notificación push en el celular.
class _PruebaNotificacion extends StatelessWidget {
  const _PruebaNotificacion();

  @override
  Widget build(BuildContext context) {
    final p = Catalogo.porId(2);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: C.grisFondo, borderRadius: BorderRadius.circular(22), border: Border.all(color: C.borde)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
          child: ClipOval(child: Image.asset('assets/img/logo.webp', fit: BoxFit.cover)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text('Comercial Sedyjo', style: T.etiqueta.copyWith(fontSize: 14, color: C.grisMedio))),
              Text('ahora', style: T.apoyo.copyWith(fontSize: 14)),
            ]),
            const SizedBox(height: 2),
            Text('Oferta del día: -${p.descuento}% en Coca-Cola', style: T.cuerpoFuerte.copyWith(fontSize: 16)),
            Text('Ahora ${clp(p.precioFinal)}. Solo hoy, hasta agotar stock.', style: T.apoyo.copyWith(fontSize: 15, color: C.grisMedio)),
          ]),
        ),
      ]),
    );
  }
}
