import 'package:flutter/material.dart';

const bg = Color(0xFF080411);
const card = Color(0xFF171027);
const accent = Color(0xFFB52CFF);
const purple = Color(0xFF7900FF);
const pink = Color(0xFFE52CFF);
const muted = Color(0xFFAAA0C0);

final appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: bg,
  colorScheme: ColorScheme.fromSeed(
    seedColor: accent,
    brightness: Brightness.dark,
    surface: card,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: bg,
    elevation: 0,
    scrolledUnderElevation: 0,
    foregroundColor: Colors.white,
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: const Color(0xFF10091D),
    indicatorColor: purple.withOpacity(.24),
    labelTextStyle: WidgetStateProperty.all(
      const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
    ),
  ),
  cardTheme: CardThemeData(
    color: card,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: accent.withOpacity(.12)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: card,
    hintStyle: const TextStyle(color: muted),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
  ),
  sliderTheme: const SliderThemeData(
    trackHeight: 4,
    activeTrackColor: accent,
    inactiveTrackColor: Colors.white12,
    thumbColor: Colors.white,
    overlayColor: Color(0x33B52CFF),
  ),
);
