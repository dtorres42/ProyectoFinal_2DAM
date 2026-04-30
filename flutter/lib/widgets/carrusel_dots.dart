import 'package:flutter/material.dart';
import 'package:proyecto_final_2dam/theme/app_theme.dart';

class CarruselDots extends StatelessWidget {
  final int zonaIdx;
  final int totalZonas;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const CarruselDots({
    super.key,
    required this.zonaIdx,
    required this.totalZonas,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onPrev,
          child: Icon(Icons.arrow_back_ios_rounded,
              size: 24,
              color: zonaIdx > 0 ? AppTheme.textMuted : AppTheme.border),
        ),
        const SizedBox(width: 12),
        ...List.generate(
          totalZonas,
          (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == zonaIdx ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == zonaIdx ? AppTheme.primary : AppTheme.border,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: onNext,
          child: Icon(Icons.arrow_forward_ios_rounded,
              size: 24,
              color: zonaIdx < totalZonas - 1
                  ? AppTheme.textMuted
                  : AppTheme.border),
        ),
      ],
    );
  }
}
