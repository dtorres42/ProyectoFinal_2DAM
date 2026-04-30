import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:proyecto_final_2dam/theme/app_theme.dart';
import 'package:proyecto_final_2dam/widgets/camera_card.dart';

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

    // Captura local: aunque dispose() anule _player, 'player' sigue vivo en el closure
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
        title: const Text(
          'Cámaras',
          style: TextStyle(
              color: AppTheme.textPrim,
              fontSize: 16,
              fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () {/*enclaer form*/},
            child: const Text(
              'Editar',
              style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
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
          ],
        ),
      ),
    );
  }
}
