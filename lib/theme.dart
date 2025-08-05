import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Light theme - Google-inspired clean design
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF1F3F4), // Very light gray with a hint of blue
    primaryColor: const Color(0xFF202124), // Almost black text (Primary Headline Text)
    cardColor: const Color(0xFFFFFFFF), // Pure white for cards and tiles
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF1F3F4), // Matches the background (Top Bar)
      foregroundColor: Color(0xFF202124), // Primary headline text
      surfaceTintColor: Color(0xFFF1F3F4), // Matches the background
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Color(0xFF202124), // Primary headline text
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      // systemOverlayStyle managed dynamically in main.dart based on theme
    ),
    iconTheme: const IconThemeData(color: Color(0xFF202124)), // Primary text color for icons
    textTheme: GoogleFonts.interTextTheme().apply(
      bodyColor: const Color(0xFF202124), // Primary headline text
      displayColor: const Color(0xFF202124), // Primary headline text
    ),
    dividerColor: const Color(0xFFE8EAED), // Subtle gray-blue shade (Search Bar Background)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE8EAED), // Subtle gray-blue shade
        foregroundColor: const Color(0xFF202124), // Primary text on buttons
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF202124), // Primary text color
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(Colors.black),
      trackColor: WidgetStateProperty.all(Colors.grey.shade300),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF202124), // Main Background - Very dark gray
    primaryColor: const Color(0xFFFFFFFF), // Primary Text - Pure white
    cardColor: const Color(0xFF2C2C2E), // Card Background - Dark gray with bluish tint
    appBarTheme: AppBarTheme(
      color: const Color(0xFF202124), // Main Background to match scaffold
      elevation: 0,
      foregroundColor: const Color(0xFFFFFFFF), // Primary Text - Pure white
      surfaceTintColor: const Color(0xFF202124), // Main Background to match scaffold
      iconTheme: const IconThemeData(color: Color(0xFFFFFFFF)), // Primary Text - Pure white
      titleTextStyle: GoogleFonts.inter(color: const Color(0xFFFFFFFF), fontSize: 18, fontWeight: FontWeight.w600), // Primary Text
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: const Color(0xFFFFFFFF), // Primary Text - Pure white
      displayColor: const Color(0xFFFFFFFF), // Primary Text - Pure white
    ),
    iconTheme: const IconThemeData(color: Color(0xFFFFFFFF)), // Primary Text - Pure white
    dividerColor: const Color(0xFF333438), // Secondary Background - Dark gray with bluish tint
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2C2C2E), // Card Background
        foregroundColor: const Color(0xFFFFFFFF), // Primary Text - Pure white
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: const Color(0xFFFFFFFF)), // Primary Text - Pure white
    ),
    dialogBackgroundColor: const Color(0xFF2C2C2E), // Card Background
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return draculaGreen;
        }
        return const Color(0xFFB0B0B0); // Secondary Text - Light gray
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return draculaGreen.withOpacity(0.5);
        }
        return const Color(0xFF333438); // Secondary Background
      }),
    ),
  );
}

// <-- ADDED: Moved function here for global access
bool isLightTheme(BuildContext context) {
  return Theme.of(context).brightness == Brightness.light;
}

// Google-inspired color scheme helper functions
Color getSecondaryTextColor(BuildContext context) {
  return isLightTheme(context) 
      ? const Color(0xFF5F6368) // Medium gray for secondary text in light mode
      : const Color(0xFFB0B0B0); // Secondary Text - Light gray for dark mode
}