import 'package:flutter/material.dart';
import 'package:proyecto_final_2dam/theme/app_theme.dart';

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color valueColor;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
                color: valueColor, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
