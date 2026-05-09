import 'package:flutter/material.dart';
import 'package:proyecto_final_2dam/theme/app_theme.dart';

enum ToastTipo { exito, error, aviso }

class ToastNotis {
  static void show(
    BuildContext context,
    String mensaje, {
    ToastTipo tipo = ToastTipo.aviso,
  }) {
    final overlay = Overlay.of(context);

    final (color, icono) = switch (tipo) {
      ToastTipo.exito => (AppTheme.primary, Icons.check_circle_rounded),
      ToastTipo.error => (AppTheme.red, Icons.error_rounded),
      ToastTipo.aviso => (Colors.orange, Icons.warning_amber_rounded),
    };

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastWidget(
        mensaje: mensaje,
        color: color,
        icono: icono,
        onDone: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }
}

class _ToastWidget extends StatefulWidget {
  final String mensaje;
  final Color color;
  final IconData icono;
  final VoidCallback onDone;

  const _ToastWidget({
    required this.mensaje,
    required this.color,
    required this.icono,
    required this.onDone,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _ctrl.forward();

    Future.delayed(const Duration(seconds: 3), () async {
      if (mounted) await _ctrl.reverse();
      widget.onDone();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 12,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _opacity,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: widget.color.withValues(alpha: .4)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(widget.icono, color: widget.color, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.mensaje,
                      style: const TextStyle(
                        color: AppTheme.textPrim,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
