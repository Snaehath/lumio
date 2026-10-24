import 'package:flutter/material.dart';

const ink = Color(0xFF201D1B);
const paper = Color(0xFFF6F3EE);
const accent = Color(0xFFB95D3D);

ThemeData buildLumioTheme() => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: paper,
  colorScheme: ColorScheme.fromSeed(
    seedColor: accent,
    brightness: Brightness.light,
    surface: paper,
  ),
  fontFamily: 'Roboto',
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide.none,
    ),
  ),
);
