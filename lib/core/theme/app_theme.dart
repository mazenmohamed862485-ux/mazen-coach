import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

enum AppThemeMode { light, dark, luxury, sports, future }

class AppTheme {
  AppTheme._();

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: Brightness.light,
        primary: AppColors.accent,
        secondary: AppColors.accentLight,
        surface: AppColors.bgLight,
        background: AppColors.bgLight,
      ),
      scaffoldBackgroundColor: AppColors.bgLight,
      fontFamily: 'Cairo',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFAF7F4EE),
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.text1Light,
        ),
        iconTheme: IconThemeData(color: AppColors.text1Light),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.bgCardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: const BorderSide(color: AppColors.accent, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xB8FFFFFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.err),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(
          color: AppColors.text3Light,
          fontSize: 14,
          fontFamily: 'Cairo',
        ),
        labelStyle: const TextStyle(
          color: AppColors.text2Light,
          fontSize: 14,
          fontFamily: 'Cairo',
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFAF7F4EE),
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.text3Light,
        selectedLabelStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 11,
        ),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
        space: 0,
      ),
      textTheme: _buildTextTheme(AppColors.text1Light, AppColors.text2Light),
      extensions: const [
        AppColorExtension(
          bg: AppColors.bgLight,
          bgCard: AppColors.bgCardLight,
          text1: AppColors.text1Light,
          text2: AppColors.text2Light,
          text3: AppColors.text3Light,
          border: AppColors.borderLight,
          accent: AppColors.accent,
        ),
      ],
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: Brightness.dark,
        primary: AppColors.accentLight,
        secondary: AppColors.accent,
        surface: AppColors.bgDark,
        background: AppColors.bgDark,
      ),
      scaffoldBackgroundColor: AppColors.bgDark,
      fontFamily: 'Cairo',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xF5111210),
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.text1Dark,
        ),
        iconTheme: IconThemeData(color: AppColors.text1Dark),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgCardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.borderDark, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x0DFFFFFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(
          color: AppColors.text3Dark,
          fontSize: 14,
          fontFamily: 'Cairo',
        ),
        labelStyle: const TextStyle(
          color: AppColors.text2Dark,
          fontSize: 14,
          fontFamily: 'Cairo',
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xF5111210),
        selectedItemColor: AppColors.accentLight,
        unselectedItemColor: AppColors.text3Dark,
        selectedLabelStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 11,
        ),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: _buildTextTheme(AppColors.text1Dark, AppColors.text2Dark),
      extensions: const [
        AppColorExtension(
          bg: AppColors.bgDark,
          bgCard: AppColors.bgCardDark,
          text1: AppColors.text1Dark,
          text2: AppColors.text2Dark,
          text3: AppColors.text3Dark,
          border: AppColors.borderDark,
          accent: AppColors.accentLight,
        ),
      ],
    );
  }

  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: TextStyle(fontFamily: 'Cairo', fontSize: 32, fontWeight: FontWeight.w900, color: primary),
      displayMedium: TextStyle(fontFamily: 'Cairo', fontSize: 28, fontWeight: FontWeight.w800, color: primary),
      displaySmall: TextStyle(fontFamily: 'Cairo', fontSize: 24, fontWeight: FontWeight.w700, color: primary),
      headlineLarge: TextStyle(fontFamily: 'Cairo', fontSize: 22, fontWeight: FontWeight.w700, color: primary),
      headlineMedium: TextStyle(fontFamily: 'Cairo', fontSize: 19, fontWeight: FontWeight.w700, color: primary),
      headlineSmall: TextStyle(fontFamily: 'Cairo', fontSize: 17, fontWeight: FontWeight.w700, color: primary),
      titleLarge: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w700, color: primary),
      titleMedium: TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.w600, color: primary),
      titleSmall: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w600, color: primary),
      bodyLarge: TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.w400, color: primary),
      bodyMedium: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w400, color: primary),
      bodySmall: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w400, color: secondary),
      labelLarge: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w600, color: primary),
      labelMedium: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w600, color: secondary),
      labelSmall: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w500, color: secondary),
    );
  }
}

class AppColorExtension extends ThemeExtension<AppColorExtension> {
  final Color bg;
  final Color bgCard;
  final Color text1;
  final Color text2;
  final Color text3;
  final Color border;
  final Color accent;

  const AppColorExtension({
    required this.bg,
    required this.bgCard,
    required this.text1,
    required this.text2,
    required this.text3,
    required this.border,
    required this.accent,
  });

  @override
  AppColorExtension copyWith({
    Color? bg, Color? bgCard, Color? text1, Color? text2,
    Color? text3, Color? border, Color? accent,
  }) {
    return AppColorExtension(
      bg: bg ?? this.bg,
      bgCard: bgCard ?? this.bgCard,
      text1: text1 ?? this.text1,
      text2: text2 ?? this.text2,
      text3: text3 ?? this.text3,
      border: border ?? this.border,
      accent: accent ?? this.accent,
    );
  }

  @override
  AppColorExtension lerp(AppColorExtension? other, double t) {
    if (other is! AppColorExtension) return this;
    return AppColorExtension(
      bg: Color.lerp(bg, other.bg, t)!,
      bgCard: Color.lerp(bgCard, other.bgCard, t)!,
      text1: Color.lerp(text1, other.text1, t)!,
      text2: Color.lerp(text2, other.text2, t)!,
      text3: Color.lerp(text3, other.text3, t)!,
      border: Color.lerp(border, other.border, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
    );
  }
}
