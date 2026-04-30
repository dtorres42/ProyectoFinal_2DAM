import 'package:flutter/material.dart';
import 'package:proyecto_final_2dam/services/services.dart';
import 'package:proyecto_final_2dam/theme/app_theme.dart';
import 'package:proyecto_final_2dam/widgets/widgets.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _nombre = 'Usuario';
  bool _loading = true;
  int _zonaIdx = 0;

  final Map<String, Player> _players = {};
  final Map<String, VideoController> _controllers = {};
  final Set<String> _errors = {};
  List<Map<String, dynamic>>? _lastZonas;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    for (final player in _players.values) {
      player.dispose();
    }
    super.dispose();
  }

  void _setZonaIdx(int idx) {
    setState(() => _zonaIdx = idx);
    if (_lastZonas == null || idx >= _lastZonas!.length) return;
    final url = _lastZonas![idx]['url_conexion'] as String?;
    if (url == null || url.isEmpty) return;
    if (_players.containsKey(url)) {
      _players[url]!.open(Media(url, extras: {
        'network-caching': '300',
        'clock-jitter': '0',
        'clock-synchro': '0',
        'live-caching': '300',
      }));
    }
  }

  VideoController _getOrCreateController(String url) {
    if (!_players.containsKey(url)) {
      final player = Player(
        configuration: const PlayerConfiguration(bufferSize: 256 * 1024),
      );
      final controller = VideoController(player);
      _players[url] = player;
      _controllers[url] = controller;

      player.stream.error.listen((error) {
        debugPrint('MediaKit error: $error');
        if (mounted) setState(() => _errors.add(url));
      });

      Future.delayed(const Duration(seconds: 8), () {
        if (!mounted) return;
        final isPlaying = _players[url]?.state.playing ?? false;
        if (!isPlaying && !_errors.contains(url)) {
          setState(() => _errors.add(url));
        }
      });

      player.open(Media(url, extras: {
        'network-caching': '300',
        'clock-jitter': '0',
        'clock-synchro': '0',
        'live-caching': '300',
      }));
    }
    return _controllers[url]!;
  }

  Future<void> _loadData() async {
    final uid = obtenerUidActual() ?? '';
    final usuario = await getUsuarioPorId(uid);
    if (mounted) {
      setState(() {
        _nombre = usuario?['nombre'] ?? 'Usuario';
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
        title: Text(
          'Bienvenido, $_nombre',
          style: const TextStyle(
            color: AppTheme.textPrim,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
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
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: getZonasActivas(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Center(
                        child:
                            CircularProgressIndicator(color: AppTheme.primary),
                      ),
                    );
                  }

                  final zonas = snapshot.data ?? [];
                  _lastZonas = zonas;

                  if (zonas.isNotEmpty && _zonaIdx >= zonas.length) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _zonaIdx = 0);
                    });
                    _zonaIdx = 0;
                  }

                  if (zonas.isEmpty) {
                    return Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Center(
                        child: Text(
                          'Sin zonas activas',
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 13),
                        ),
                      ),
                    );
                  }

                  final zona = zonas[_zonaIdx];
                  final urlConexion = zona['url_conexion'] as String?;
                  final hasUrl = urlConexion != null && urlConexion.isNotEmpty;
                  final hasError = hasUrl && _errors.contains(urlConexion);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CameraCard(
                        zona: zona,
                        controller:
                            hasUrl ? _getOrCreateController(urlConexion) : null,
                        hasError: hasError,
                      ),
                      const SizedBox(height: 8),
                      if (zonas.length > 1)
                        CarruselDots(
                          zonaIdx: _zonaIdx,
                          totalZonas: zonas.length,
                          onPrev: _zonaIdx > 0
                              ? () => _setZonaIdx(_zonaIdx - 1)
                              : null,
                          onNext: _zonaIdx < zonas.length - 1
                              ? () => _setZonaIdx(_zonaIdx + 1)
                              : null,
                        ),
                      const SizedBox(height: 20),
                      StreamBuilder<Map<String, dynamic>?>(
                        stream: getZonaPorId(zona['uid'] as String),
                        builder: (context, zSnap) {
                          if (!zSnap.hasData) return const SizedBox();

                          final objetivos = zSnap.data!['objetivos']
                                  as Map<String, dynamic>? ??
                              {};
                          final objetos = (zSnap.data!['estado']
                                      as Map<String, dynamic>?)?['objetos']
                                  as Map<String, dynamic>? ??
                              {};

                          if (objetivos.isEmpty) return const SizedBox();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ESTADO ACTUAL',
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 1.5,
                                children: objetivos.entries
                                    .map((e) => StatusCard(
                                          nombre: e.key,
                                          cantidad:
                                              (objetos[e.key] as num? ?? 0)
                                                  .toInt(),
                                          limite: (e.value as num).toInt(),
                                        ))
                                    .toList(),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'ALERTAS RECIENTES',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      StreamBuilder<List<Map<String, dynamic>>>(
                        stream: getAlertasActivas(),
                        builder: (context, aSnap) {
                          if (aSnap.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                  color: AppTheme.primary),
                            );
                          }

                          final alertas = aSnap.data ?? [];

                          if (alertas.isEmpty) {
                            return const Text(
                              'Sin alertas activas',
                              style: TextStyle(
                                  color: AppTheme.textMuted, fontSize: 13),
                            );
                          }

                          return Column(
                            children: alertas
                                .take(3)
                                .map((a) => AlertCard(alerta: a))
                                .toList(),
                          );
                        },
                      ),
                    ],
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
