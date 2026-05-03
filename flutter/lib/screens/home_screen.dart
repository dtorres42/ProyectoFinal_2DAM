import 'package:flutter/material.dart';
import 'package:proyecto_final_2dam/services/services.dart';
import 'package:proyecto_final_2dam/theme/app_theme.dart';
import 'package:proyecto_final_2dam/widgets/widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _nombre = 'Usuario';
  int _alertasGest = 0;
  bool _loading = true;
  String? _userUid;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = obtenerUidActual() ?? '';
    final usuario = await getUsuarioPorId(uid);
    if (mounted) {
      setState(() {
        _userUid = uid;
        _nombre = usuario?['nombre'] as String? ?? 'Usuario';
        _alertasGest = usuario?['alertas_gestionadas'] as int? ?? 0;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppTheme.bg,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bienvenido, $_nombre',
              style: const TextStyle(
                color: AppTheme.textPrim,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Text(
              'Vigilancia activa',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primary,
              child: Text(
                _nombre[0].toUpperCase(),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),

              // ── Mis estadísticas personales ───────────────────────
              const Text('TUS ESTADÍSTICAS',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  )),
              const SizedBox(height: 10),

              StreamBuilder<List<Map<String, dynamic>>>(
                stream: getAlertasActivas(_userUid ?? ''),
                builder: (context, snap) {
                  final alertas = snap.data ?? [];
                  final gestionando = alertas
                      .where((a) =>
                          a['estado'] == 'en_proceso' &&
                          a['atendida_por'] == _userUid)
                      .length;
                  final sinGestionar =
                      alertas.where((a) => a['estado'] == 'activa').length;

                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.8,
                    children: [
                      SummaryCard(
                        title: 'Gestionando',
                        value: '$gestionando',
                        valueColor: AppTheme.amber,
                      ),
                      SummaryCard(
                        title: 'Resueltas totales',
                        value: '$_alertasGest',
                        valueColor: AppTheme.green,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // ── Alertas que requieren atención ────────────────────
              const Text('REQUIERE ATENCIÓN',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  )),
              const SizedBox(height: 10),

              StreamBuilder<List<Map<String, dynamic>>>(
                stream: getAlertasActivas(_userUid ?? ''),
                builder: (context, snap) {
                  final activas = (snap.data ?? [])
                      .where((a) => a['estado'] == 'activa')
                      .toList();

                  if (activas.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_outline_rounded,
                              color: AppTheme.green, size: 18),
                          SizedBox(width: 10),
                          Text('Sin alertas pendientes',
                              style: TextStyle(
                                  color: AppTheme.textMuted, fontSize: 13)),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: activas
                        .take(3)
                        .map((a) => AlertCard(alerta: a))
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 24),

              // ── Mis alertas en proceso ────────────────────────────
              const Text('GESTIONANDO AHORA',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  )),
              const SizedBox(height: 10),

              StreamBuilder<List<Map<String, dynamic>>>(
                stream: getAlertasActivas(_userUid ?? ''),
                builder: (context, snap) {
                  final mias = (snap.data ?? [])
                      .where((a) =>
                          a['estado'] == 'en_proceso' &&
                          a['atendida_por'] == _userUid)
                      .toList();

                  if (mias.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.inbox_outlined,
                              color: AppTheme.textMuted, size: 18),
                          SizedBox(width: 10),
                          Text('No estás gestionando ninguna alerta',
                              style: TextStyle(
                                  color: AppTheme.textMuted, fontSize: 13)),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: mias.map((a) => AlertCard(alerta: a)).toList(),
                  );
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
