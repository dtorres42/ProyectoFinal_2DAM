import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:proyecto_final_2dam/services/services.dart';
import 'package:proyecto_final_2dam/theme/app_theme.dart';
import 'package:proyecto_final_2dam/widgets/widgets.dart';

class ZonaDetalleScreen extends StatefulWidget {
  final Map<String, dynamic> zona;
  const ZonaDetalleScreen({super.key, required this.zona});

  @override
  State<ZonaDetalleScreen> createState() => _ZonaDetalleScreenState();
}

class _ZonaDetalleScreenState extends State<ZonaDetalleScreen> {
  Player? _player;
  VideoController? _controller;
  bool _hasError = false;
  String? _url;

  @override
  void initState() {
    super.initState();
    _url = widget.zona['url_conexion'] as String?;
    _initPlayer();
  }

  void _initPlayer() {
    if (_url == null || _url!.isEmpty) {
      setState(() => _hasError = true);
      return;
    }

    final player = Player(
      configuration: const PlayerConfiguration(bufferSize: 256 * 1024),
    );
    _player = player;
    _controller = VideoController(player);

    player.stream.error.listen((error) {
      debugPrint('MediaKit error: $error');
      if (mounted) setState(() => _hasError = true);
    });

    Future.delayed(const Duration(seconds: 8), () {
      if (!mounted) return;
      if (!player.state.playing && !_hasError) {
        setState(() => _hasError = true);
      }
    });

    player.open(Media(_url!, extras: {
      'network-caching': '300',
      'clock-jitter': '0',
      'clock-synchro': '0',
      'live-caching': '300',
    }));
  }

  String _formatTs(dynamic ts) {
    if (ts == null) return '';
    try {
      final dt = (ts as Timestamp).toDate();
      return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppTheme.textPrim, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.zona['nombre'] as String? ?? 'Zona',
          style: const TextStyle(
            color: AppTheme.textPrim,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text(
              'Editar',
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CameraCard(
              zona: widget.zona,
              controller: _hasError ? null : _controller,
              hasError: _hasError,
            ),
            const SizedBox(height: 20),
            StreamBuilder<Map<String, dynamic>?>(
              stream: getZonaPorId(widget.zona['uid'] as String),
              builder: (context, zSnap) {
                if (!zSnap.hasData) return const SizedBox();

                final objetivos =
                    zSnap.data!['objetivos'] as Map<String, dynamic>? ?? {};
                final objetos =
                    (zSnap.data!['estado'] as Map<String, dynamic>?)?['objetos']
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
                                cantidad: (objetos[e.key] as num? ?? 0).toInt(),
                                limite: (e.value as num).toInt(),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
            const Text(
              'HISTORIAL',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: getHistorialZona(widget.zona['uid'] as String, limite: 1),
              builder: (context, hSnap) {
                if (!hSnap.hasData || hSnap.data!.isEmpty) {
                  return const Text(
                    'Sin datos de historial',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  );
                }

                final ultimo = hSnap.data!.first;
                final medias = ultimo['medias'] as Map<String, dynamic>? ?? {};
                final maximos =
                    ultimo['maximos'] as Map<String, dynamic>? ?? {};
                final ts = ultimo['timestamp'];

                return Column(
                  children: medias.entries.map((entry) {
                    final objeto = entry.key;
                    final media = (entry.value as num).toInt();
                    final maximo = (maximos[objeto] as num? ?? 0).toInt();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatTs(ts),
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 9,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                objeto,
                                style: const TextStyle(
                                  color: AppTheme.textPrim,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Row(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        '$media',
                                        style: const TextStyle(
                                          color: AppTheme.textPrim,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const Text(
                                        'media',
                                        style: TextStyle(
                                          color: AppTheme.textMuted,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 40),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        '$maximo',
                                        style: const TextStyle(
                                          color: AppTheme.primary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const Text(
                                        'máximo',
                                        style: TextStyle(
                                          color: AppTheme.textMuted,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
