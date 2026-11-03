import 'package:flutter/material.dart';

// Tunr's AMOLED palette: true black canvas with carefully layered surfaces.
const bg = Color(0xFF000000);
const surface = Color(0xFF09090D);
const card = Color(0xFF121219);
const cardRaised = Color(0xFF1A1A24);
const outline = Color(0xFF292934);
const accent = Color(0xFFB69CFF);
const accentSoft = Color(0xFF8062D6);
const textMuted = Color(0xFF92909E);

final appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: bg,
  colorScheme: const ColorScheme(
    brightness: Brightness.dark,
    primary: accent,
    onPrimary: Color(0xFF100B1C),
    secondary: Color(0xFF9D8ACB),
    onSecondary: Colors.black,
    error: Color(0xFFFF6B81),
    onError: Colors.black,
    surface: surface,
    onSurface: Colors.white,
  ),
  dividerColor: outline,
  appBarTheme: const AppBarTheme(
    backgroundColor: bg,
    foregroundColor: Colors.white,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: bg,
    indicatorColor: accent.withOpacity(.13),
    labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
      color: states.contains(WidgetState.selected) ? accent : textMuted,
      fontSize: 11,
      fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
    )),
    iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
      color: states.contains(WidgetState.selected) ? accent : textMuted,
    )),
  ),
  cardTheme: CardThemeData(
    color: card,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: outline, width: .6),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: card,
    hintStyle: const TextStyle(color: textMuted),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: accent, width: 1),
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: cardRaised,
    contentTextStyle: const TextStyle(color: Colors.white),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  ),
  sliderTheme: const SliderThemeData(
    trackHeight: 3,
    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5),
    overlayShape: RoundSliderOverlayShape(overlayRadius: 14),
    activeTrackColor: accent,
    inactiveTrackColor: Colors.white24,
    thumbColor: Colors.white,
  ),
);
