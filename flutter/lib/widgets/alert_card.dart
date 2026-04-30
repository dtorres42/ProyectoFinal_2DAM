import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:proyecto_final_2dam/theme/app_theme.dart';

class AlertCard extends StatelessWidget {
  final Map<String, dynamic> alerta;

  const AlertCard({super.key, required this.alerta});

  Color _colorEstado(String estado) {
    if (estado == 'resuelta') return AppTheme.border;
    if (estado == 'en_proceso') return AppTheme.amber;
    return AppTheme.red;
  }

  String _formatTs(dynamic ts) {
    if (ts == null) return '';
    try {
      final dt = (ts as Timestamp).toDate();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = alerta['estado'] as String? ?? '';
    final zonaNombre = alerta['zona_nombre'] as String? ?? '';
    final objeto = alerta['objeto'] as String? ?? '';
    final cantidad = alerta['cantidad'] as int? ?? 0;
    final limite = alerta['limite'] as int? ?? 0;
    final ts = alerta['timestamp'];
    final color = _colorEstado(estado);
    final resuelta = estado == 'resuelta';
    final btnLabel = resuelta
        ? 'Resuelta'
        : estado == 'en_proceso'
            ? 'En proceso'
            : 'Gestionar';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$objeto — $zonaNombre',
                  style: TextStyle(
                    color: resuelta ? AppTheme.textMuted : AppTheme.textPrim,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$cantidad detectados · máx $limite · ${_formatTs(ts)}',
                  style:
                      const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              btnLabel,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
