import 'package:flutter/material.dart';
import 'package:proyecto_final_2dam/services/services.dart';
import 'package:proyecto_final_2dam/theme/app_theme.dart';
import 'package:proyecto_final_2dam/widgets/widgets.dart';

class AlertScreen extends StatefulWidget {
  const AlertScreen({super.key});

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  bool _alertas = true;
  final String _userUid = obtenerUidActual() ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: StreamBuilder<List<Map<String, dynamic>>>(
          stream: getAlertasActivas(_userUid),
          builder: (context, snap) {
            final activas = snap.data?.length ?? 0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alertas',
                  style: TextStyle(
                    color: AppTheme.textPrim,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '$activas activas',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => setState(() => _alertas = !_alertas),
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Stack(
                    children: [
                      AnimatedAlign(
                        alignment: _alertas
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        child: FractionallySizedBox(
                          widthFactor: 0.5,
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Center(
                              child: Text(
                                'Alertas',
                                style: TextStyle(
                                  color: _alertas
                                      ? Colors.white
                                      : AppTheme.textMuted,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                'Resueltas',
                                style: TextStyle(
                                  color: !_alertas
                                      ? Colors.white
                                      : AppTheme.textMuted,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _alertas ? _listaAlertas() : _listasResueltas(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _listaAlertas() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: getAlertasActivas(_userUid),
      builder: (context, aSnap) {
        if (aSnap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        final alertas = aSnap.data ?? [];

        if (alertas.isEmpty) {
          return const Text(
            'Sin alertas activas',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          );
        }

        return Column(
          children: alertas.map((a) => AlertCard(alerta: a)).toList(),
        );
      },
    );
  }

  Widget _listasResueltas() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: getAlertasResueltas(),
      builder: (context, aSnap) {
        if (aSnap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        final alertas = aSnap.data ?? [];

        if (alertas.isEmpty) {
          return const Text(
            'Sin alertas',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          );
        }

        return Column(
          children: alertas.map((a) => AlertCard(alerta: a)).toList(),
        );
      },
    );
  }
}
