import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:proyecto_final_2dam/services/services.dart';
import 'package:proyecto_final_2dam/theme/app_theme.dart';

class AlertCard extends StatelessWidget {
  final Map<String, dynamic> alerta;

  const AlertCard({super.key, required this.alerta});

  String get uid => alerta['uid'] as String? ?? '';
  String get zonaNombre => alerta['zona_nombre'] as String? ?? '';
  String get objeto => alerta['objeto'] as String? ?? '';
  int get cantidad => alerta['cantidad'] as int? ?? 0;
  int get limite => alerta['limite'] as int? ?? 0;
  String get descripcion => alerta['descripcion'] as String? ?? '';
  String get atendidaPor => alerta['atendida_por'] as String? ?? '';
  String get estado => alerta['estado'] as String? ?? '';
  dynamic get ts => alerta['timestamp'];

  bool get resuelta => estado == 'resuelta';
  bool get enProceso => estado == 'en_proceso';
  bool get esActiva => !resuelta && !enProceso;
  bool get esMia => atendidaPor == (obtenerUidActual() ?? '');

  Color get colorEstado {
    if (resuelta) return AppTheme.primaryLight;
    if (enProceso) return AppTheme.amber;
    return AppTheme.red;
  }

  String get estadoTexto {
    if (resuelta) return 'Resuelta';
    if (enProceso) return 'En proceso';
    return 'Activa';
  }

  String _formatTs() {
    if (ts == null) return '';
    try {
      final dt = (ts as Timestamp).toDate();
      return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  void _mostrarDetalle(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: colorEstado, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$objeto — $zonaNombre',
                style: const TextStyle(
                  color: AppTheme.textPrim,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colorEstado.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                estadoTexto,
                style: TextStyle(
                  color: colorEstado,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _detailRow('Objeto', objeto),
            _detailRow('Zona', zonaNombre),
            _detailRow('Detectados', '$cantidad'),
            _detailRow('Límite', limite == 0 ? 'Prohibido' : '$limite'),
            _detailRow('Descripción', descripcion),
            _detailRow('Hora', _formatTs()),
            if (atendidaPor.isNotEmpty) _detailRow('Atendida por', atendidaPor),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          if (esActiva)
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                await atenderAlerta(uid, obtenerUidActual() ?? '');
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Atender'),
            )
          else if (enProceso && esMia)
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                await resolverAlerta(uid);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Resolver'),
            )
          else
            const SizedBox(),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style:
                    const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                  color: AppTheme.textPrim,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                )),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _mostrarDetalle(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: colorEstado, width: 4)),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: colorEstado, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$objeto — $zonaNombre',
                    style: TextStyle(
                      color: AppTheme.textPrim,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$cantidad detectados · máx $limite · ${_formatTs()}',
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8)
          ],
        ),
      ),
    );
  }
}
