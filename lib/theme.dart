import 'package:flutter/material.dart';

class C {
  static const bg = Color(0xFF0B0C0E);
  static const bg2 = Color(0xFF131519);
  static const card = Color(0xFF181B20);
  static const card2 = Color(0xFF1F232A);
  static const line = Color(0xFF2A2F38);
  static const text = Color(0xFFF2F3F5);
  static const text2 = Color(0xFFC4C8D0);
  static const muted = Color(0xFF8B919C);
  static const accent = Color(0xFFFF6B1F);
  static const accent2 = Color(0xFFFF9A3D);
  static const ok = Color(0xFF2ECC71);
  static const warn = Color(0xFFF5B833);
  static const bad = Color(0xFFFF5B6B);
  static const blue = Color(0xFF4EA1FF);
  static const violet = Color(0xFFB48CFF);
}

ThemeData cgTheme() {
  final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);
  final scheme = const ColorScheme.dark(primary: C.accent, onPrimary: Colors.white, secondary: C.accent2, surface: C.card, onSurface: C.text, error: C.bad);
  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: C.bg,
    textTheme: base.textTheme.apply(bodyColor: C.text, displayColor: C.text),
    appBarTheme: const AppBarTheme(backgroundColor: C.bg, surfaceTintColor: Colors.transparent, elevation: 0, centerTitle: false, titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: C.text, letterSpacing: -0.3)),
    cardTheme: CardThemeData(color: C.card, elevation: 0, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: C.line))),
    dividerTheme: const DividerThemeData(color: C.line, thickness: 1, space: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.bg2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(color: C.muted),
      hintStyle: const TextStyle(color: C.muted),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.line)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.accent, width: 1.6)),
    ),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: C.accent, foregroundColor: Colors.white, minimumSize: const Size(48, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(foregroundColor: C.text, side: const BorderSide(color: C.line), minimumSize: const Size(48, 46), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: C.accent2)),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: C.bg2,
      surfaceTintColor: Colors.transparent,
      indicatorColor: C.accent.withAlpha(40),
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(fontSize: 11.5, fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500, color: s.contains(WidgetState.selected) ? C.text : C.muted)),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(color: s.contains(WidgetState.selected) ? C.accent : C.muted)),
    ),
    snackBarTheme: SnackBarThemeData(backgroundColor: C.card2, contentTextStyle: const TextStyle(color: C.text), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
    switchTheme: SwitchThemeData(thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : C.muted), trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? C.accent : C.card2)),
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: C.bg2, surfaceTintColor: Colors.transparent, showDragHandle: true),
    dialogTheme: DialogThemeData(backgroundColor: C.bg2, surfaceTintColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: C.accent),
  );
}
