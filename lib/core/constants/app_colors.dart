import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── الألوان الأساسية (Theme: Meridian - Cream & Deep Teal) ──
  static const Color accent = Color(0xFF0D7377);
  static const Color accentLight = Color(0xFF14B8BD);
  static const Color accentDark = Color(0x1A0D7377);

  // ── Light Theme ──
  static const Color bgLight = Color(0xFFF7F4EE);
  static const Color bgCardLight = Color(0xD1FFFFFF);
  static const Color text1Light = Color(0xFF1C1917);
  static const Color text2Light = Color(0x841C1917);
  static const Color text3Light = Color(0x4D1C1917);
  static const Color borderLight = Color(0x171C1917);

  // ── Dark Theme ──
  static const Color bgDark = Color(0xFF111210);
  static const Color bgCardDark = Color(0x0AFFFFFF);
  static const Color text1Dark = Color(0xFFEDE8DF);
  static const Color text2Dark = Color(0x80EDE8DF);
  static const Color text3Dark = Color(0x42EDE8DF);
  static const Color borderDark = Color(0x14FFFFFF);

  // ── Status Colors ──
  static const Color ok = Color(0xFF0A7A4F);
  static const Color okLight = Color(0x170A7A4F);
  static const Color warn = Color(0xFFB45309);
  static const Color warnLight = Color(0x17B45309);
  static const Color err = Color(0xFFC0392B);
  static const Color errLight = Color(0x17C0392B);
  static const Color info = Color(0xFF0369A1);

  // ── Luxury Theme Accent ──
  static const Color luxuryAccent = Color(0xFFC9962A);
  static const Color sportsAccent = Color(0xFF0050C8);
  static const Color futureAccent = Color(0xFF5E35B1);

  // ── Gradient ──
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFFF7F4EE), Color(0xFFEEEBE4)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
