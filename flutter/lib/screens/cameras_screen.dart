import 'package:flutter/material.dart';
import 'package:proyecto_final_2dam/services/services.dart';
import 'package:proyecto_final_2dam/theme/app_theme.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: StreamBuilder<List<Map<String, dynamic>>>(
          stream: getZonasActivas(),
          builder: (context, snap) {
            final activas = snap.data?.length ?? 0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cámaras',
                  style: TextStyle(
                    color: AppTheme.textPrim,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '$activas zonas activas',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: getTodasLasZonas(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text('Error al cargar',
                    style: TextStyle(color: AppTheme.textMuted)),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary));
            }

            final zonas = snapshot.data ?? [];

            int alertasActivas = 0;
            int zonasOnline = 0;
            final Set<String> zonasConAlerta = {};

            for (final zona in zonas) {
              final estado = zona['estado'] as Map<String, dynamic>? ?? {};
              final objetos = estado['objetos'] as Map<String, dynamic>? ?? {};
              final objetivos =
                  zona['objetivos'] as Map<String, dynamic>? ?? {};
              final online = estado['online'] as bool? ?? false;
              final activo = zona['activo'] as bool? ?? false;

              if (online && activo) {
                zonasOnline++;
                for (final entry in objetivos.entries) {
                  final limite = (entry.value as num).toInt();
                  final cantidad = (objetos[entry.key] as num? ?? 0).toInt();
                  if (cantidad > limite) {
                    alertasActivas++;
                    zonasConAlerta.add(zona['uid'] as String? ?? '');
                    break;
                  }
                }
              }
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.8,
                    children: [
                      _buildSummaryCard(
                        'Alertas activas',
                        '$alertasActivas',
                        alertasActivas > 0 ? AppTheme.red : AppTheme.textPrim,
                      ),
                      _buildSummaryCard(
                        'Zonas online',
                        '$zonasOnline/${zonas.length}',
                        AppTheme.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'ZONAS',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (zonas.isEmpty)
                    const Center(
                      child: Text('Sin zonas configuradas',
                          style: TextStyle(color: AppTheme.textMuted)),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: zonas.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.1,
                      ),
                      itemBuilder: (context, index) {
                        final zona = zonas[index];
                        final activo = zona['activo'] as bool? ?? false;

                        return GestureDetector(
                          onTap: activo
                              ? () => Navigator.pushNamed(
                                    context,
                                    'zona_detalle',
                                    arguments: zona,
                                  )
                              : null,
                          child: _buildZoneCard(
                            zona,
                            zonasConAlerta
                                .contains(zona['uid'] as String? ?? ''),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
                color: valueColor, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneCard(Map<String, dynamic> zona, bool tieneAlerta) {
    final estado = zona['estado'] as Map<String, dynamic>? ?? {};
    final nombre = zona['nombre'] as String? ?? 'Sin nombre';
    final online = estado['online'] as bool? ?? false;
    final activo = zona['activo'] as bool? ?? false;

    Color statusColor;
    if (!activo) {
      statusColor = AppTheme.border;
    } else if (tieneAlerta) {
      statusColor = AppTheme.red;
    } else if (online) {
      statusColor = AppTheme.green;
    } else {
      statusColor = AppTheme.amber;
    }

    return Opacity(
      opacity: activo ? 1.0 : 0.4,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!activo)
                  const Text('Inactiva',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 9))
                else if (online) ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('Live',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w600)),
                ] else
                  const Text('Offline',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 9)),
              ],
            ),
            const Spacer(),
            Icon(Icons.videocam_rounded, color: statusColor, size: 28),
            const Spacer(),
            Text(
              nombre,
              style: const TextStyle(
                  color: AppTheme.textPrim,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }
}
