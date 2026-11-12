part of 'componentes.dart';

// Campo de texto con etiqueta visible (parte de componentes.dart).

/// Campo de texto con etiqueta visible arriba (nunca solo placeholder).
class Campo extends StatefulWidget {
  const Campo(this.etiqueta,
      {super.key,
      this.controlador,
      this.error,
      this.ayuda,
      this.clave = false,
      this.teclado,
      this.icono,
      this.alCambiar,
      this.valorInicial,
      this.accion = TextInputAction.next,
      this.autofill,
      this.mayusculas = TextCapitalization.none});
  final String etiqueta;
  final TextEditingController? controlador;
  final String? error;
  final String? ayuda;
  final bool clave;
  final TextInputType? teclado;
  final IconData? icono;
  final ValueChanged<String>? alCambiar;
  final String? valorInicial;
  final TextInputAction accion;
  final Iterable<String>? autofill;
  final TextCapitalization mayusculas;

  @override
  State<Campo> createState() => _CampoState();
}

class _CampoState extends State<Campo> {
  bool _ver = false;

  @override
  Widget build(BuildContext context) {
    final hayError = widget.error != null;
    OutlineInputBorder borde(Color c, double w) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(R.s), borderSide: BorderSide(color: c, width: w));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.etiqueta, style: T.cuerpoMFuerte),
        const SizedBox(height: Esp.x2),
        TextFormField(
          controller: widget.controlador,
          initialValue: widget.controlador == null ? widget.valorInicial : null,
          obscureText: widget.clave && !_ver,
          keyboardType: widget.teclado,
          textInputAction: widget.accion,
          autofillHints: widget.autofill,
          textCapitalization: widget.mayusculas,
          enableSuggestions: !widget.clave,
          autocorrect: !widget.clave,
          onChanged: widget.alCambiar,
          style: T.cuerpo.copyWith(fontSize: 18),
          cursorColor: C.verde,
          decoration: InputDecoration(
            filled: true,
            fillColor: C.oscuro ? C.grisFondo : C.superficie,
            contentPadding: const EdgeInsets.symmetric(horizontal: Esp.x4, vertical: 17),
            prefixIcon: widget.icono == null ? null : Icon(widget.icono, size: Ico.m, color: C.grisTexto),
            suffixIcon: widget.clave
                ? Padding(
                    padding: const EdgeInsets.only(right: Esp.x2),
                    child: Tocable(
                        etiqueta: _ver ? 'Ocultar contraseña' : 'Mostrar contraseña',
                        onTap: () => setState(() => _ver = !_ver),
                        child: SizedBox(
                            width: 52,
                            child: Icon(_ver ? LucideIcons.eyeOff : LucideIcons.eye, color: C.grisMedio, size: Ico.m))),
                  )
                : null,
            enabledBorder: borde(hayError ? C.error : C.bordeControl, hayError ? 2 : 1.5),
            focusedBorder: borde(hayError ? C.error : C.verde, 2.5),
            border: borde(C.bordeControl, 1.5),
          ),
        ),
        if (hayError)
          Padding(
            padding: const EdgeInsets.only(top: Esp.x2),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: EdgeInsets.only(top: 2), child: Icon(LucideIcons.circleAlert, size: Ico.s, color: C.error)),
              const SizedBox(width: Esp.x2),
              Expanded(child: Text(widget.error!, style: T.apoyo.copyWith(color: C.error, fontWeight: FontWeight.w600))),
            ]),
          )
        else if (widget.ayuda != null)
          Padding(padding: const EdgeInsets.only(top: Esp.x2), child: Text(widget.ayuda!, style: T.apoyo)),
      ],
    );
  }
}

