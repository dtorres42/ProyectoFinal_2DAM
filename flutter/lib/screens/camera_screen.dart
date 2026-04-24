import 'package:flutter/material.dart';
import 'package:proyecto_final_2dam/services/services.dart';
import 'package:proyecto_final_2dam/theme/app_theme.dart';

class CamerasScreen extends StatelessWidget {
  const CamerasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: getTodasLasZonas(),
          builder: (context, zonasSnapshot) {
            if (!zonasSnapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              );
            }

            final zonas = List<Map<String, dynamic>>.from(zonasSnapshot.data!);
            zonas.sort((a, b) {
              final aOnline = _isOnline(a);
              final bOnline = _isOnline(b);
              if (aOnline == bOnline) {
                return _zoneName(a).compareTo(_zoneName(b));
              }
              return bOnline ? 1 : -1;
            });

            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: getAlertasActivas(),
              builder: (context, alertasSnapshot) {
                final alertas = alertasSnapshot.data ?? const [];
                final stats = _DashboardStats.from(zonas, alertas);

                return SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(activeZones: stats.onlineZones),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 1.15,
                              children: [
                                _MetricCard(
                                  label: 'Total personas',
                                  value: '${stats.totalPeople}',
                                ),
                                _MetricCard(
                                  label: 'Alertas activas',
                                  value: '${stats.activeAlerts}',
                                  valueColor: AppTheme.red,
                                ),
                                _MetricCard(
                                  label: 'Zonas online',
                                  value: '${stats.onlineZones}/${stats.totalZones}',
                                  valueColor: AppTheme.green,
                                ),
                                _MetricCard(
                                  label: 'Aforo medio',
                                  value: '${stats.averageOccupancy.round()}%',
                                ),
                              ],
                            ),
                            const SizedBox(height: 26),
                            const Text(
                              'ZONAS',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 18),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: zonas.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 14,
                                    childAspectRatio: 0.95,
                                  ),
                              itemBuilder: (context, index) {
                                final zona = zonas[index];
                                final zonaId = (zona['uid'] ?? '').toString();
                                final zoneAlerts = alertas
                                    .where(
                                      (alerta) =>
                                          (alerta['zona_id'] ?? '').toString() ==
                                          zonaId,
                                    )
                                    .length;

                                return _ZoneCard(
                                  name: _zoneName(zona),
                                  people: _personCount(zona),
                                  occupancy: _occupancyPercent(zona),
                                  online: _isOnline(zona),
                                  activeAlerts: zoneAlerts,
                                );
                              },
                            ),
                            if (zonas.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(top: 12),
                                child: Text(
                                  'No hay zonas configuradas todavía.',
                                  style: TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.activeZones});

  final int activeZones;
