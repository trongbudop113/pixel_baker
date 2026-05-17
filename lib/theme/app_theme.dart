import 'package:flutter/material.dart';

class AppThemeColors {
  const AppThemeColors({
    required this.primary,
    required this.secondary,
    required this.surface,
    required this.onSurface,
    required this.mutedText,
    required this.scaffoldBackground,
    required this.appBarBackground,
    required this.cardBackground,
    required this.inputFill,
    required this.inputBorder,
    required this.inputFocusBorder,
    required this.inputHint,
    required this.snackBarBackground,
  });

  final Color primary;
  final Color secondary;
  final Color surface;
  final Color onSurface;
  final Color mutedText;
  final Color scaffoldBackground;
  final Color appBarBackground;
  final Color cardBackground;
  final Color inputFill;
  final Color inputBorder;
  final Color inputFocusBorder;
  final Color inputHint;
  final Color snackBarBackground;

  static const light = AppThemeColors(
    primary: Color(0xFF1E88E5),
    secondary: Color(0xFFE53935),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF1F1F1F),
    mutedText: Color(0xFF6B7280),
    scaffoldBackground: Color(0xFFFFFFFF),
    appBarBackground: Color(0xFFFFFFFF),
    cardBackground: Color(0xFFFFFFFF),
    inputFill: Color(0xFFF8FAFC),
    inputBorder: Color(0xFFD1D5DB),
    inputFocusBorder: Color(0xFF1E88E5),
    inputHint: Color(0xFF6B7280),
    snackBarBackground: Color(0xFF111827),
  );

  static const dark = AppThemeColors(
    primary: Color(0xFF7CC4FF),
    secondary: Color(0xFFFF8A80),
    surface: Color(0xFF161B22),
    onSurface: Color(0xFFF7FAFD),
    mutedText: Color(0xFFC7D9F0),
    scaffoldBackground: Color(0xFF0D1117),
    appBarBackground: Color(0xFF11161D),
    cardBackground: Color(0xFF151C24),
    inputFill: Color(0xFF1D3148),
    inputBorder: Color(0xFF5C83B4),
    inputFocusBorder: Color(0xFF8ED0FF),
    inputHint: Color(0xFFB9D2EE),
    snackBarBackground: Color(0xFF1C2530),
  );
}

class AppThemeController {
  AppThemeController._();
  static final AppThemeController instance = AppThemeController._();

  // Dark mode tạm tắt — đổi lại ThemeMode.system để bật
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(ThemeMode.light);

  bool get isDark => themeMode.value == ThemeMode.dark;

  void setDarkMode(bool enabled) {
    themeMode.value = enabled ? ThemeMode.dark : ThemeMode.light;
  }

  void toggleDarkMode() {
    setDarkMode(!isDark);
  }
}

class AppTheme {
  static const String fontFamily = 'Noto Sans';

  static ThemeData light() {
    final c = AppThemeColors.light;
    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: c.primary,
      onPrimary: Colors.white,
      secondary: c.secondary,
      onSecondary: Colors.white,
      error: Color(0xFFB3261E),
      onError: Colors.white,
      surface: c.surface,
      onSurface: c.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.scaffoldBackground,
      dividerColor: c.inputBorder,
      fontFamily: fontFamily,
      textTheme: _textTheme(c.onSurface),
      primaryTextTheme: _textTheme(c.onSurface),
      appBarTheme: AppBarTheme(
        backgroundColor: c.appBarBackground,
        foregroundColor: c.onSurface,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: c.cardBackground,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: _inputDecorationTheme(c),
      dropdownMenuTheme: _dropdownMenuTheme(c),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.primary,
        selectionColor: c.primary.withOpacity(0.24),
        selectionHandleColor: c.primary,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.snackBarBackground,
        contentTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        actionTextColor: c.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData dark() {
    final c = AppThemeColors.dark;
    final scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: c.primary,
      onPrimary: Color(0xFF0E2233),
      secondary: c.secondary,
      onSecondary: Color(0xFF3C1010),
      error: Color(0xFFF2B8B5),
      onError: Color(0xFF601410),
      surface: c.surface,
      onSurface: c.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.scaffoldBackground,
      dividerColor: c.inputBorder,
      fontFamily: fontFamily,
      textTheme: _textTheme(c.onSurface),
      appBarTheme: AppBarTheme(
        backgroundColor: c.appBarBackground,
        foregroundColor: c.onSurface,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: c.cardBackground,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: _inputDecorationTheme(c),
      dropdownMenuTheme: _dropdownMenuTheme(c),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.primary,
        selectionColor: c.primary.withOpacity(0.28),
        selectionHandleColor: c.primary,
      ),
      iconTheme: IconThemeData(color: c.onSurface),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.snackBarBackground,
        contentTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: c.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        actionTextColor: c.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static TextTheme _textTheme(Color textColor) {
    return TextTheme(
      displayLarge: TextStyle(fontFamily: fontFamily, fontSize: 57, fontWeight: FontWeight.w700, color: textColor),
      displayMedium: TextStyle(fontFamily: fontFamily, fontSize: 45, fontWeight: FontWeight.w700, color: textColor),
      displaySmall: TextStyle(fontFamily: fontFamily, fontSize: 36, fontWeight: FontWeight.w700, color: textColor),
      headlineLarge: TextStyle(fontFamily: fontFamily, fontSize: 32, fontWeight: FontWeight.w700, color: textColor),
      headlineMedium: TextStyle(fontFamily: fontFamily, fontSize: 28, fontWeight: FontWeight.w700, color: textColor),
      headlineSmall: TextStyle(fontFamily: fontFamily, fontSize: 24, fontWeight: FontWeight.w700, color: textColor),
      titleLarge: TextStyle(fontFamily: fontFamily, fontSize: 22, fontWeight: FontWeight.w700, color: textColor),
      titleMedium: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
      titleSmall: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
      bodyLarge: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w400, color: textColor),
      bodyMedium: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w400, color: textColor),
      bodySmall: TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w400, color: textColor),
      labelLarge: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
      labelMedium: TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
      labelSmall: TextStyle(fontFamily: fontFamily, fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
    );
  }

  static InputDecorationTheme _inputDecorationTheme(AppThemeColors c) {
    OutlineInputBorder border(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecorationTheme(
      filled: true,
      fillColor: c.inputFill,
      hoverColor: c.inputFill,
      hintStyle: TextStyle(
        fontFamily: fontFamily,
        color: c.inputHint,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      labelStyle: TextStyle(
        fontFamily: fontFamily,
        color: c.mutedText,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      floatingLabelStyle: TextStyle(
        fontFamily: fontFamily,
        color: c.primary,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      helperStyle: TextStyle(
        fontFamily: fontFamily,
        color: c.mutedText,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      errorStyle: const TextStyle(
        fontFamily: fontFamily,
        color: Color(0xFFFF9C95),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      counterStyle: TextStyle(
        fontFamily: fontFamily,
        color: c.mutedText,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      prefixStyle: TextStyle(
        fontFamily: fontFamily,
        color: c.onSurface,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      suffixStyle: TextStyle(
        fontFamily: fontFamily,
        color: c.onSurface,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      prefixIconColor: c.onSurface.withOpacity(0.82),
      suffixIconColor: c.onSurface.withOpacity(0.82),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      isDense: true,
      enabledBorder: border(c.inputBorder),
      focusedBorder: border(c.inputFocusBorder, width: 1.6),
      disabledBorder: border(c.inputBorder.withOpacity(0.65)),
      errorBorder: border(const Color(0xFFE53935)),
      focusedErrorBorder: border(const Color(0xFFE53935), width: 1.6),
      border: border(c.inputBorder),
    );
  }

  static DropdownMenuThemeData _dropdownMenuTheme(AppThemeColors c) {
    return DropdownMenuThemeData(
      textStyle: TextStyle(
        fontFamily: fontFamily,
        color: c.onSurface,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      inputDecorationTheme: _inputDecorationTheme(c),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(c.cardBackground),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        side: WidgetStatePropertyAll(BorderSide(color: c.inputBorder)),
      ),
    );
  }
}
