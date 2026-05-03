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
  bool _esAdmin = false;

  @override
  void initState() {
    super.initState();
    _cargarRol();
  }

  Future<void> _cargarRol() async {
    final rol = await getRolUsuarioActual();
    if (mounted) setState(() => _esAdmin = rol == 'admin');
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
  Widget build(BuildContext context) {
    final zonaId = widget.zona['uid'] as String;

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
          if (_esAdmin)
            TextButton(
              onPressed: () => Navigator.pushNamed(
                context,
                'edit_zona',
                arguments: widget.zona,
              ),
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
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: getZonaPorId(zonaId),
        builder: (context, zSnap) {
          final zona = zSnap.data ?? widget.zona;
          final url = zona['url_conexion'] as String? ?? '';
          final activo = zona['activo'] as bool? ?? true;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Cámara ────────────────────────────────────────────
                _VideoPlayer(
                  url: url,
                  zona: zona,
                  activo: activo,
                ),
                const SizedBox(height: 20),

                // ── Estado actual ─────────────────────────────────────
                Builder(builder: (_) {
                  final objetivos =
                      zona['objetivos'] as Map<String, dynamic>? ?? {};
                  final objetos =
                      (zona['estado'] as Map<String, dynamic>?)?['objetos']
                              as Map<String, dynamic>? ??
                          {};

                  if (objetivos.isEmpty) return const SizedBox();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ESTADO ACTUAL',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          )),
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
                                      (objetos[e.key] as num? ?? 0).toInt(),
                                  limite: (e.value as num).toInt(),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                }),

                // ── Historial ─────────────────────────────────────────
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: getHistorialZona(zonaId, limite: 1),
                  builder: (context, hSnap) {
                    if (!hSnap.hasData || hSnap.data!.isEmpty) {
                      return const Text(
                        'Sin datos de historial',
                        style:
                            TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      );
                    }

                    final ultimo = hSnap.data!.first;
                    final medias =
                        ultimo['medias'] as Map<String, dynamic>? ?? {};
                    final maximos =
                        ultimo['maximos'] as Map<String, dynamic>? ?? {};
                    final ts = ultimo['timestamp'];
                    final objetivos =
                        zona['objetivos'] as Map<String, dynamic>? ?? {};

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('HISTORIAL',
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                )),
                            Text(_formatTs(ts),
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 10,
                                )),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...medias.entries.map((entry) {
                          final objeto = entry.key;
                          final media = (entry.value as num).toInt();
                          final maximo = (maximos[objeto] as num? ?? 0).toInt();
                          final limite =
                              (objetivos[objeto] as num? ?? 0).toInt();
                          return _buildHistorialCard(
                              objeto, media, maximo, limite);
                        }),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistorialCard(String objeto, int media, int maximo, int limite) {
    final prohibido = limite == 0;
    final porcentaje =
        prohibido ? (media > 0 ? 1.0 : 0.0) : (media / limite).clamp(0.0, 1.0);

    Color barColor;
    Color badgeColor;
    Color badgeBg;
    String badgeLabel;

    if (prohibido && media > 0) {
      barColor = AppTheme.red;
      badgeColor = AppTheme.red;
      badgeBg = AppTheme.red.withValues(alpha: .12);
      badgeLabel = 'Prohibido';
    } else if (!prohibido && porcentaje >= 0.8) {
      barColor = AppTheme.amber;
      badgeColor = AppTheme.amber;
      badgeBg = AppTheme.amber.withValues(alpha: .12);
      badgeLabel = 'Cerca del límite';
    } else {
      barColor = AppTheme.green;
      badgeColor = prohibido ? AppTheme.textMuted : AppTheme.green;
      badgeBg = prohibido
          ? AppTheme.textMuted.withValues(alpha: .12)
          : AppTheme.green.withValues(alpha: .12);
      badgeLabel = prohibido ? 'Sin detecciones' : 'Dentro del límite';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(objeto,
                  style: const TextStyle(
                    color: AppTheme.textPrim,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(badgeLabel,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ],
          ),
          if (!prohibido) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: porcentaje,
                minHeight: 6,
                backgroundColor: AppTheme.border,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _statItem('$media', 'media'),
              _divider(),
              _statItem('$maximo', 'máximo',
                  valueColor: maximo > limite && !prohibido
                      ? AppTheme.amber
                      : prohibido && maximo > 0
                          ? AppTheme.red
                          : AppTheme.textPrim),
              _divider(),
              _statItem(limite == 0 ? '0' : '$limite', 'límite'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, {Color? valueColor}) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                color: valueColor ?? AppTheme.textPrim,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
        ],
      ),
    );
  }

  Widget _divider() =>
      Container(width: 0.5, height: 32, color: AppTheme.border);
}

// ── Widget propio para el player ───────────────────────────────────────────
class _VideoPlayer extends StatefulWidget {
  final String url;
  final Map<String, dynamic> zona;
  final bool activo;

  const _VideoPlayer({
    required this.url,
    required this.zona,
    required this.activo,
  });

  @override
  State<_VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<_VideoPlayer> {
  late final Player player =
      Player(configuration: const PlayerConfiguration(bufferSize: 256 * 1024));
  late final VideoController controller = VideoController(player);
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    if (widget.activo) _initPlayer();
  }

  @override
  void didUpdateWidget(_VideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Zona se desactiva — paramos el player
    if (!widget.activo && oldWidget.activo) {
      player.stop();
    }

    // Zona se activa — arrancamos el player
    if (widget.activo && !oldWidget.activo) {
      setState(() => _hasError = false);
      _initPlayer();
    }
  }

  void _initPlayer() {
    if (widget.url.isEmpty) {
      setState(() => _hasError = true);
      return;
    }

    player.stream.error.listen((error) {
      debugPrint('MediaKit error: $error');
      if (mounted) setState(() => _hasError = true);
    });

    player.open(Media(widget.url, extras: {
      'network-caching': '300',
      'clock-jitter': '0',
      'clock-synchro': '0',
      'live-caching': '300',
    }));
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CameraCard(
      zona: widget.zona,
      controller:
          _hasError || widget.url.isEmpty || !widget.activo ? null : controller,
      hasError: _hasError,
      inactiva: !widget.activo,
    );
  }
}
