import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light; // Default to light mode as per new design
  double _fontScale = 1.0;

  // --- Color Palette ---
  static const Color primaryDeepBlue = Color(0xFF1E3A8A);
  static const Color secondaryTeal = Color(0xFF0D9488);
  static const Color accentSoftOrange = Color(0xFFF59E0B);
  static const Color backgroundOffWhite = Color(0xFFF8FAFC);
  static const Color cardsLightGray = Color(0xFFF1F5F9);
  static const Color textDarkGray = Color(0xFF1E293B);
  static const Color textLightGray = Color(0xFF64748B);

  // --- Dark Theme Colors ---
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkCards = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);


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

  ThemeData getTheme() {
    final theme = _themeMode == ThemeMode.light ? lightTheme : darkTheme;
    return _applyFontScaling(theme);
  }

  ThemeData _applyFontScaling(ThemeData theme) {
    // This function can be expanded if more specific scaling is needed
    return theme.copyWith(
      textTheme: GoogleFonts.latoTextTheme(theme.textTheme).copyWith(
         displayLarge: theme.textTheme.displayLarge?.copyWith(fontSize: 57 * _fontScale),
         displayMedium: theme.textTheme.displayMedium?.copyWith(fontSize: 45 * _fontScale),
         displaySmall: theme.textTheme.displaySmall?.copyWith(fontSize: 36 * _fontScale),
         headlineLarge: theme.textTheme.headlineLarge?.copyWith(fontSize: 32 * _fontScale),
         headlineMedium: theme.textTheme.headlineMedium?.copyWith(fontSize: 28 * _fontScale),
         headlineSmall: theme.textTheme.headlineSmall?.copyWith(fontSize: 24 * _fontScale),
         titleLarge: theme.textTheme.titleLarge?.copyWith(fontSize: 22 * _fontScale),
         titleMedium: theme.textTheme.titleMedium?.copyWith(fontSize: 16 * _fontScale),
         titleSmall: theme.textTheme.titleSmall?.copyWith(fontSize: 14 * _fontScale),
         bodyLarge: theme.textTheme.bodyLarge?.copyWith(fontSize: 16 * _fontScale),
         bodyMedium: theme.textTheme.bodyMedium?.copyWith(fontSize: 14 * _fontScale),
         bodySmall: theme.textTheme.bodySmall?.copyWith(fontSize: 12 * _fontScale),
         labelLarge: theme.textTheme.labelLarge?.copyWith(fontSize: 14 * _fontScale),
         labelMedium: theme.textTheme.labelMedium?.copyWith(fontSize: 12 * _fontScale),
         labelSmall: theme.textTheme.labelSmall?.copyWith(fontSize: 11 * _fontScale),
      ),
    );
  }

  static final ThemeData lightTheme = _buildTheme(
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: primaryDeepBlue,
      onPrimary: Colors.white,
      secondary: secondaryTeal,
      onSecondary: Colors.white,
      tertiary: accentSoftOrange,
      onTertiary: textDarkGray,
      error: Colors.redAccent,
      onError: Colors.white,
      surface: cardsLightGray, // Used for cards
      onSurface: textDarkGray,
    ),
    scaffoldBackgroundColor: backgroundOffWhite,
    cardColor: cardsLightGray,
    primaryTextColor: textDarkGray,
    secondaryTextColor: textLightGray,
  );

  static final ThemeData darkTheme = _buildTheme(
     colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: primaryDeepBlue,
      onPrimary: Colors.white,
      secondary: secondaryTeal,
      onSecondary: Colors.white,
      tertiary: accentSoftOrange,
      onTertiary: textDarkGray,
      error: Colors.redAccent,
      onError: Colors.white,
      surface: darkCards,
      onSurface: darkTextPrimary,
    ),
    scaffoldBackgroundColor: darkBackground,
    cardColor: darkCards,
    primaryTextColor: darkTextPrimary,
    secondaryTextColor: darkTextSecondary,
  );


  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Color scaffoldBackgroundColor,
    required Color cardColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    }) {

    final baseTheme = ThemeData.from(colorScheme: colorScheme, useMaterial3: true);
    final poppinsTextTheme = GoogleFonts.poppinsTextTheme(baseTheme.textTheme);
    final latoTextTheme = GoogleFonts.latoTextTheme(baseTheme.textTheme);

    final textTheme = latoTextTheme.copyWith(
      // Headings with Poppins
      displayLarge: poppinsTextTheme.displayLarge?.copyWith(color: primaryTextColor, fontWeight: FontWeight.bold),
      displayMedium: poppinsTextTheme.displayMedium?.copyWith(color: primaryTextColor, fontWeight: FontWeight.bold),
      displaySmall: poppinsTextTheme.displaySmall?.copyWith(color: primaryTextColor, fontWeight: FontWeight.bold),
      headlineLarge: poppinsTextTheme.headlineLarge?.copyWith(color: primaryTextColor, fontWeight: FontWeight.bold),
      headlineMedium: poppinsTextTheme.headlineMedium?.copyWith(color: primaryTextColor, fontWeight: FontWeight.bold),
      headlineSmall: poppinsTextTheme.headlineSmall?.copyWith(color: primaryTextColor, fontWeight: FontWeight.w600),
      titleLarge: poppinsTextTheme.titleLarge?.copyWith(color: primaryTextColor, fontWeight: FontWeight.w600),

      // Body text with Lato
      titleMedium: latoTextTheme.titleMedium?.copyWith(color: primaryTextColor),
      titleSmall: latoTextTheme.titleSmall?.copyWith(color: secondaryTextColor),
      bodyLarge: latoTextTheme.bodyLarge?.copyWith(color: primaryTextColor),
      bodyMedium: latoTextTheme.bodyMedium?.copyWith(color: secondaryTextColor),
      bodySmall: latoTextTheme.bodySmall?.copyWith(color: secondaryTextColor),
      labelLarge: latoTextTheme.labelLarge?.copyWith(color: primaryTextColor, fontWeight: FontWeight.w600),
      labelMedium: latoTextTheme.labelMedium?.copyWith(color: secondaryTextColor),
      labelSmall: latoTextTheme.labelSmall?.copyWith(color: secondaryTextColor),
    );


    return baseTheme.copyWith(
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      textTheme: textTheme,
      cardColor: cardColor,
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.brightness == Brightness.light ? Colors.grey.shade200 : Colors.grey.shade800, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: primaryTextColor,
        titleTextStyle: textTheme.headlineSmall,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryTextColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: textTheme.labelLarge,
        ),
      ),
       textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: textTheme.bodyMedium,
      ),
      iconTheme: IconThemeData(color: secondaryTextColor, size: 24.0),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.secondary,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.primary.withAlpha(25),
        labelStyle: textTheme.bodySmall?.copyWith(color: colorScheme.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
      ),
    );
  }
}