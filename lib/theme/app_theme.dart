import 'package:flutter/material.dart';

class AppColors {
  static const caramel      = Color(0xFFC8873A);
  static const caramelLight = Color(0xFFF0C48A);
  static const caramelPale  = Color(0xFFFDF5EA);
  static const sage         = Color(0xFF7BA68A);
  static const sageLight    = Color(0xFFA8C9B4);
  static const sagePale     = Color(0xFFEFF5F1);
  static const warmCream    = Color(0xFFFDFAF5);
  static const textDark     = Color(0xFF3D2E1E);
  static const textMid      = Color(0xFF7A6555);
  static const textLight    = Color(0xFFB5A090);
  static const gold         = Color(0xFFD4A843);
  static const goldRing     = Color(0xFFE8C06A);
  static const background   = Color(0xFFFDFAF5);

  // カテゴリ別カラー
  static const catFood    = Color(0xFFF59E0B);
  static const catMedical = Color(0xFF10B981);
  static const catGoods   = Color(0xFF3B82F6);
  static const catBeauty  = Color(0xFFEC4899);
  static const catOther   = Color(0xFF8B5CF6);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.caramel,
      primary: AppColors.caramel,
      secondary: AppColors.sage,
      surface: Colors.white,
      background: AppColors.background,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textDark,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.caramel,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.caramelPale,
      hintStyle: const TextStyle(color: AppColors.textLight),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.caramelLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.caramel, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.caramelLight),
      ),
    ),
    fontFamily: 'NotoSansJP',
  );
}
