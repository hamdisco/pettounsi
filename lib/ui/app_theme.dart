import 'package:flutter/material.dart';

class AppTheme {
  // Keep old names for compatibility across your project
  static const Color orange = Color(0xFFF58A6C);
  static const Color orangeDark = Color(0xFFE86C4F);

  static const Color bg = Color(0xFFFFFBFD);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF2D2733);
  static const Color muted = Color(0xFF7E748A);
  static const Color outline = Color(0xFFEDE4F1);
  static const Color softOrange = Color(0xFFFFE6DC);
  static const Color orchid = Color(0xFFE8D9FF);
  static const Color orchidDark = Color(0xFF7C62D7);
  static const Color rose = Color(0xFFF7D7E8);
  static const Color roseDark = Color(0xFFC86B9A);
  static const Color mist = Color(0xFFF8F5FF);
  static const Color blush = Color(0xFFFFEFF4);
  static const Color lilac = Color(0xFFF1EEFF);
  static const Color mint = Color(0xFFEAFBF3);
  static const Color sky = Color(0xFFEEF7FF);
  static const Color butter = Color(0xFFFFF7D9);

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: orange,
      onPrimary: Colors.white,
      secondary: Color(0xFFB89BFF),
      onSecondary: ink,
      surface: surface,
      onSurface: ink,
      outline: outline,
      error: Color(0xFFE05555),
      onError: Colors.white,
    );

    final base = ThemeData(
      useMaterial3: true,
      fontFamily: "Roboto",
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      splashFactory: InkSparkle.splashFactory,
    );

    final text = base.textTheme;

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: ink,
          fontWeight: FontWeight.w900,
          fontSize: 18,
          letterSpacing: 0.1,
        ),
        iconTheme: IconThemeData(color: ink),
      ),

      textTheme: text.copyWith(
        headlineSmall: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          height: 1.05,
          color: ink,
          letterSpacing: -0.3,
        ),
        titleLarge: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: ink,
          letterSpacing: -0.1,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: ink,
        ),
        bodyLarge: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: ink,
          height: 1.3,
        ),
        bodyMedium: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: muted,
          height: 1.3,
        ),
        labelLarge: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shadowColor: Colors.black.withAlpha(10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: outline),
        ),
        margin: EdgeInsets.zero,
      ),

      dividerTheme: DividerThemeData(color: ink.withAlpha(18), thickness: 1),

      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        labelColor: ink,
        unselectedLabelColor: muted,
        labelStyle: const TextStyle(fontWeight: FontWeight.w900),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8F4FB),
        hintStyle: const TextStyle(color: muted, fontWeight: FontWeight.w600),
        labelStyle: TextStyle(
          color: ink.withAlpha(205),
          fontWeight: FontWeight.w800,
        ),
        prefixIconColor: ink.withAlpha(150),
        suffixIconColor: ink.withAlpha(150),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: orange, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: orange,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          backgroundColor: Colors.white,
          side: const BorderSide(color: outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: orangeDark,
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: orangeDark,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: const Color(0xFFFFEEE8),
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11.8,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            color: selected ? orangeDark : muted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? orangeDark : ink.withAlpha(155),
            size: selected ? 24 : 23,
          );
        }),
      ),
    );
  }

  static List<BoxShadow> softShadows([double strength = 1]) {
    return [
      BoxShadow(
        color: const Color(0xFF7B5DA8).withAlpha((10 * strength).round()),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: Colors.black.withAlpha((5 * strength).round()),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ];
  }
}
