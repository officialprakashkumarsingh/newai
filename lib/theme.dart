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

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFFAF7F3),
    primaryColor: Colors.black,
    cardColor: const Color(0xFFD9A299),
          appBarTheme: AppBarTheme(
        color: const Color(0xFFFAF7F3),
        elevation: 0,
        foregroundColor: Colors.black,
        surfaceTintColor: const Color(0xFFFAF7F3),
      iconTheme: const IconThemeData(color: Colors.black),
      titleTextStyle: GoogleFonts.inter(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
    iconTheme: const IconThemeData(color: Colors.black54),
          dividerColor: const Color(0xFFD9A299),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFD9A299),
        foregroundColor: Colors.black,
      )),
    textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: Colors.black)),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return Colors.green;
        }
        return null; // Uses default color
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return Colors.green.withOpacity(0.5);
        }
        return null; // Uses default color
      }),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF222831),
    primaryColor: const Color(0xFFFFFAEC),
    cardColor: const Color(0xFF31363F),
    appBarTheme: AppBarTheme(
      color: const Color(0xFF222831),
      elevation: 0,
      foregroundColor: const Color(0xFFFFFAEC),
      surfaceTintColor: const Color(0xFF222831),
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