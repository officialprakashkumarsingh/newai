import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Color Palette
const Color draculaBackground = Color(0xFF282A36);
const Color draculaCurrentLine = Color(0xFF44475A);
const Color draculaForeground = Color(0xFFF8F8F2);
const Color draculaComment = Color(0xFF6272A4);
const Color draculaPurple = Color(0xFFBD93F9);
const Color draculaGreen = Color(0xFF50FA7B);

class ThemeNotifier extends ChangeNotifier {
  final String key = "theme";
  SharedPreferences? _prefs;
  late ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  ThemeNotifier() {
    _themeMode = ThemeMode.system;
    _loadFromPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _loadFromPrefs() async {
    await _initPrefs();
    // Always use system theme mode
    _themeMode = ThemeMode.system;
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    await _initPrefs();
    // No need to save system theme preference
  }

  void setTheme(ThemeMode themeMode) {
    if (_themeMode == themeMode) return;
    _themeMode = themeMode;
    _saveToPrefs();
    notifyListeners();
  }

  // Light theme - Perplexity-inspired modern design
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFFAFAFA), // Very light gray, modern and clean
    primaryColor: const Color(0xFF1A1A1A), // Dark text color
    cardColor: const Color(0xFFF5F5F5), // Clean light gray for cards/buttons
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFAFAFA), // Match scaffold background
      foregroundColor: Color(0xFF1A1A1A), // Dark text
      surfaceTintColor: Color(0xFFFAFAFA), // Match scaffold background
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Color(0xFF1A1A1A),
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
    textTheme: GoogleFonts.interTextTheme().apply(
      bodyColor: const Color(0xFF1A1A1A),
      displayColor: const Color(0xFF1A1A1A),
    ),
    dividerColor: const Color(0xFFE8E8E8), // Subtle light gray divider
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFF5F5F5), // Clean light gray buttons
        foregroundColor: const Color(0xFF1A1A1A), // Dark text on buttons
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.black,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(Colors.black),
      trackColor: WidgetStateProperty.all(Colors.grey.shade300),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF000000), // AMOLED black
    primaryColor: const Color(0xFFFFFAEC),
    cardColor: const Color(0xFF31363F),
    appBarTheme: AppBarTheme(
      color: const Color(0xFF000000), // AMOLED black to match scaffold
      elevation: 0,
      foregroundColor: const Color(0xFFFFFAEC),
      surfaceTintColor: const Color(0xFF000000), // AMOLED black to match scaffold
      iconTheme: const IconThemeData(color: Color(0xFFFFFAEC)),
      titleTextStyle: GoogleFonts.inter(color: const Color(0xFFFFFAEC), fontSize: 18, fontWeight: FontWeight.w600),
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: const Color(0xFFFFFAEC),
      displayColor: const Color(0xFFFFFAEC),
    ),
    iconTheme: const IconThemeData(color: Color(0xFFFFFAEC)),
    dividerColor: const Color(0xFF31363F),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF31363F),
        foregroundColor: const Color(0xFFFFFAEC),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: const Color(0xFFFFFAEC)),
    ),
    dialogBackgroundColor: const Color(0xFF31363F),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return draculaGreen;
        }
        return const Color(0xFFFFFAEC);
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return draculaGreen.withOpacity(0.5);
        }
        return const Color(0xFF31363F);
      }),
    ),
  );
}

// <-- ADDED: Moved function here for global access
bool isLightTheme(BuildContext context) {
  return Theme.of(context).brightness == Brightness.light;
}