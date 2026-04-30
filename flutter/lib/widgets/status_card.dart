import 'package:flutter/material.dart';
import 'package:proyecto_final_2dam/theme/app_theme.dart';

class StatusCard extends StatelessWidget {
  final String nombre;
  final int cantidad;
  final int limite;

  const StatusCard({
    super.key,
    required this.nombre,
    required this.cantidad,
    required this.limite,
  });

  Color _colorEstado() {
    if (limite == 0 && cantidad == 0) return AppTheme.green;
    if (cantidad > limite) return AppTheme.red;
    if (cantidad >= (limite * 0.8).ceil()) return AppTheme.amber;
    return AppTheme.green;
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorEstado();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(nombre,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          Text('$cantidad',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700)),
          Text(
            limite == 0 ? 'prohibido' : 'máx $limite',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
