import 'package:flutter/material.dart';

const bg = Color(0xFF0B0B0F);
const card = Color(0xFF17171D);
const accent = Color(0xFF8B5CF6);

final appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: bg,
  colorScheme: ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.dark),
  appBarTheme: const AppBarTheme(backgroundColor: bg, elevation: 0, scrolledUnderElevation: 0),
  sliderTheme: const SliderThemeData(
    trackHeight: 3,
    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5),
    overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
    activeTrackColor: Colors.white,
    inactiveTrackColor: Colors.white24,
    thumbColor: Colors.white,
  ),
);
