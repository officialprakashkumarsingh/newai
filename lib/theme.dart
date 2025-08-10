import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:google_fonts/google_fonts.dart'; // Removed
import 'package:shared_preferences/shared_preferences.dart';

// Color Palette
const Color draculaBackground = Color(0xFF282A36);
const Color draculaCurrentLine = Color(0xFF44475A);
const Color draculaForeground = Color(0xFFF8F8F2);
const Color draculaComment = Color(0xFF6272A4);

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
    // Override Material purple defaults with Google blue
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF4285F4), // Google blue for primary elements
      secondary: Color(0xFF1A73E8), // Darker blue for accents
      surface: Color(0xFFFFFFFF), // White surfaces
      background: Color(0xFFF1F3F4), // Light gray background
      error: Color(0xFFD93025), // Google red for errors
      onPrimary: Color(0xFFFFFFFF), // White text on primary
      onSecondary: Color(0xFFFFFFFF), // White text on secondary
      onSurface: Color(0xFF202124), // Dark text on surfaces
      onBackground: Color(0xFF202124), // Dark text on background
      onError: Color(0xFFFFFFFF), // White text on error
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF1F3F4), // Matches the background (Top Bar)
      foregroundColor: Color(0xFF202124), // Primary headline text
      surfaceTintColor: Color(0xFFF1F3F4), // Matches the background
      elevation: 0,
      titleTextStyle: const TextStyle(
        color: Color(0xFF202124), // Primary headline text
        fontSize: 20,
        fontWeight: FontWeight.w600,
        fontFamily: 'monospace', // Use monospace as fallback
      ),
      // systemOverlayStyle managed dynamically in main.dart based on theme
    ),
    iconTheme: const IconThemeData(color: Color(0xFF202124)), // Primary text color for icons
    textTheme: ThemeData.light().textTheme.apply(
      bodyColor: const Color(0xFF202124), // Primary headline text
      displayColor: const Color(0xFF202124), // Primary headline text
    ),
    dividerColor: const Color(0xFFE8EAED), // Subtle gray-blue shade (Search Bar Background)
    // Text selection theme - override purple selection with Google blue
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Color(0xFF4285F4), // Google blue cursor
      selectionColor: Color(0x404285F4), // Light blue selection highlight
      selectionHandleColor: Color(0xFF4285F4), // Blue selection handles
    ),
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
    // Override Material purple defaults with Google blue
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF1A73E8), // Google blue for primary elements
      secondary: Color(0xFF4285F4), // Lighter blue for accents
      surface: Color(0xFF2C2C2E), // Dark surfaces
      background: Color(0xFF202124), // Dark background
      error: Color(0xFFEA4335), // Google red for errors
      onPrimary: Color(0xFFFFFFFF), // White text on primary
      onSecondary: Color(0xFFFFFFFF), // White text on secondary
      onSurface: Color(0xFFFFFFFF), // White text on surfaces
      onBackground: Color(0xFFFFFFFF), // White text on background
      onError: Color(0xFFFFFFFF), // White text on error
    ),
    appBarTheme: AppBarTheme(
      color: const Color(0xFF202124), // Main Background to match scaffold
      elevation: 0,
      foregroundColor: const Color(0xFFFFFFFF), // Primary Text - Pure white
      surfaceTintColor: const Color(0xFF202124), // Main Background to match scaffold
      iconTheme: const IconThemeData(color: Color(0xFFFFFFFF)), // Primary Text - Pure white
      titleTextStyle: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'monospace'), // AhamAI logo font
    ),
    textTheme: ThemeData.dark().textTheme.apply(
      bodyColor: const Color(0xFFFFFFFF), // Primary Text - Pure white
      displayColor: const Color(0xFFFFFFFF), // Primary Text - Pure white
    ),
    iconTheme: const IconThemeData(color: Color(0xFFFFFFFF)), // Primary Text - Pure white
    dividerColor: const Color(0xFF333438), // Secondary Background - Dark gray with bluish tint
    // Text selection theme - override purple selection with Google blue
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Color(0xFF1A73E8), // Google blue cursor (darker for dark theme)
      selectionColor: Color(0x401A73E8), // Light blue selection highlight
      selectionHandleColor: Color(0xFF1A73E8), // Blue selection handles
    ),
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