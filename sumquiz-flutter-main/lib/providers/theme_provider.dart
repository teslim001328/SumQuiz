import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  double _fontScale = 1.0;

  ThemeMode get themeMode => _themeMode;
  double get fontScale => _fontScale;

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setSystemTheme() {
    _themeMode = ThemeMode.system;
    notifyListeners();
  }

  void setFontScale(double scale) {
    _fontScale = scale;
    notifyListeners();
  }

  ThemeData _applyFontScaling(ThemeData theme) {
    return theme.copyWith(
      textTheme: theme.textTheme.copyWith(
        headlineSmall: theme.textTheme.headlineSmall?.copyWith(fontSize: 24.0 * _fontScale),
        headlineMedium: theme.textTheme.headlineMedium?.copyWith(fontSize: 28.0 * _fontScale),
        titleLarge: theme.textTheme.titleLarge?.copyWith(fontSize: 22.0 * _fontScale),
        bodyMedium: theme.textTheme.bodyMedium?.copyWith(fontSize: 14.0 * _fontScale),
        bodySmall: theme.textTheme.bodySmall?.copyWith(fontSize: 12.0 * _fontScale),
      ),
      appBarTheme: theme.appBarTheme.copyWith(
        titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
          fontSize: 20.0 * _fontScale,
        ),
      ),
    );
  }

  ThemeData getTheme() {
    final theme = _themeMode == ThemeMode.light ? lightTheme : darkTheme;
    return _applyFontScaling(theme);
  }

  static final ThemeData lightTheme = ThemeData.light().copyWith(
    primaryColor: Colors.white,
    scaffoldBackgroundColor: Colors.white,
    cardColor: Colors.grey[200],
    colorScheme: const ColorScheme.light(
      primary: Colors.black,
      secondary: Colors.black,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: Colors.black,
    ),
    textTheme: ThemeData.light().textTheme.copyWith(
          headlineSmall: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          headlineMedium: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          titleLarge: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          bodyMedium: const TextStyle(color: Colors.black54),
          bodySmall: const TextStyle(color: Colors.black54),
        ),
    iconTheme: const IconThemeData(color: Colors.black),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData.dark().copyWith(
    primaryColor: Colors.black,
    scaffoldBackgroundColor: Colors.black,
    cardColor: Colors.grey[900],
    colorScheme: const ColorScheme.dark(
      primary: Colors.white,
      secondary: Colors.white,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      surface: Colors.black,
      onSurface: Colors.white,
    ),
    textTheme: ThemeData.dark().textTheme.copyWith(
          headlineSmall: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          headlineMedium: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          titleLarge: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          bodyMedium: const TextStyle(color: Colors.white70),
          bodySmall: const TextStyle(color: Colors.white70),
        ),
    iconTheme: const IconThemeData(color: Colors.white),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
