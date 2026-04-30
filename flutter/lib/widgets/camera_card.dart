import 'package:flutter/material.dart';
import 'package:proyecto_final_2dam/theme/app_theme.dart';
import 'package:media_kit_video/media_kit_video.dart';

class CameraCard extends StatelessWidget {
  final Map<String, dynamic> zona;
  final VideoController? controller;
  final bool hasError;

  const CameraCard({
    super.key,
    required this.zona,
    required this.controller,
    required this.hasError,
  });

  String _formatTs(dynamic ts) {
    if (ts == null) return '';
    try {
      final dt = (ts as dynamic).toDate() as DateTime;
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = zona['estado'] as Map<String, dynamic>? ?? {};
    final online = estado['online'] as bool? ?? false;
    final ts = estado['actualizado_el'];
    final hasUrl = controller != null && !hasError;

    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasUrl)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Video(
                controller: controller!,
                fit: BoxFit.cover,
                controls: NoVideoControls,
              ),
            )
          else
            Center(
              child: Icon(
                hasError ? Icons.wifi_off_rounded : Icons.videocam_off_rounded,
                size: 48,
                color: AppTheme.border,
              ),
            ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: online ? AppTheme.green : AppTheme.textMuted,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    online ? 'Live' : 'Offline',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 14,
            right: 14,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  zona['nombre'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (ts != null)
                  Text(
                    'Act. ${_formatTs(ts)}',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: .7),
                        fontSize: 10),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
