import 'package:flutter/material.dart';

class AppTheme {
  static const Color bg = Color(0xFF0F0F1A);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color border = Color(0xFF2A2A3E);
  static const Color textPrim = Color(0xFFE2E2F0);
  static const Color textMuted = Color(0xFF8B8BA7);
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color green = Color(0xFF22C55E);
  static const Color red = Color(0xFFEF4444);
  static const Color amber = Color(0xFFF59E0B);

  static final ThemeData darkTheme = ThemeData.dark().copyWith(
    primaryColor: primary,
    scaffoldBackgroundColor: bg,
    cardColor: surface,

    colorScheme: const ColorScheme.dark(
      primary: primary,
      surface: surface,
      error: red,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: textPrim),
      titleTextStyle: TextStyle(
        color: textPrim,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      suffixIconColor: textMuted,
      hintStyle: const TextStyle(color: textMuted, fontSize: 13),
      labelStyle: const TextStyle(color: textMuted, fontSize: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: red, width: 1.5),
      ),
      errorStyle: const TextStyle(color: red, fontSize: 11),
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? primary : null,
      ),
      side: const BorderSide(color: border, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Colors.white
            : Colors.grey.shade600,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? primary
            : const Color(0xFF2A2A3E),
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => Colors.transparent,
      ),
    ),
  );
}
