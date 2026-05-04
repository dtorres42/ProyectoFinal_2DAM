import 'package:flutter/material.dart';
import 'package:proyecto_final_2dam/services/services.dart';
import 'package:proyecto_final_2dam/theme/app_theme.dart';
import 'package:proyecto_final_2dam/widgets/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    _inicializarApp();
  }

  // UNIFICADO: Carga de datos compatible con Huella y Login normal
  Future<void> _inicializarApp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Buscamos el UID (Firebase o Almacenamiento local si entró por huella)
      final String? uid = obtenerUidActual() ?? prefs.getString('huella_user_uid');

      if (uid != null && uid.isNotEmpty) {
        final usuario = await getUsuarioPorId(uid);
        
        if (mounted) {
          setState(() {
            _userUid = uid;
            _nombre = usuario?['nombre'] as String? ?? 'Usuario';
            _alertasGest = usuario?['alertas_gestionadas'] as int? ?? 0;
            _loading = false;
          });
        }
      } else {
        // Si no hay UID, al login
        if (mounted) Navigator.pushReplacementNamed(context, 'login');
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
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
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, 'profile'), // Para que puedas ir al perfil
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primary,
                child: Text(
                  _nombre.isNotEmpty ? _nombre[0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
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
              const Text('TUS ESTADÍSTICAS',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  )),
              const SizedBox(height: 10),
              
              // Estadísticas con el UID recuperado
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: getAlertasActivas(_userUid ?? ''),
                builder: (context, snap) {
                  final alertas = snap.data ?? [];
                  final gestionando = alertas
                      .where((a) =>
                          a['estado'] == 'en_proceso' &&
                          a['atendida_por'] == _userUid)
                      .length;

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
                    return _buildEmptyState('Sin alertas pendientes', Icons.check_circle_outline_rounded, AppTheme.green);
                  }

                  return Column(
                    children: activas.take(3).map((a) => AlertCard(alerta: a)).toList(),
                  );
                },
              ),
              
              const SizedBox(height: 24),
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
                    return _buildEmptyState('No estás gestionando ninguna alerta', Icons.inbox_outlined, AppTheme.textMuted);
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

  Widget _buildEmptyState(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        ],
      ),
    );
  }
}