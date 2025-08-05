import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Color Palette - Dracula for Light, Slack for Dark
const Color draculaBackground = Color(0xFF282A36);
const Color draculaCurrentLine = Color(0xFF44475A);
const Color draculaForeground = Color(0xFFF8F8F2);
const Color draculaComment = Color(0xFF6272A4);
const Color draculaPurple = Color(0xFFBD93F9);
const Color draculaGreen = Color(0xFF50FA7B);

// Slack Dark Theme Colors
const Color slackDarkBackground = Color(0xFF1A1D21);
const Color slackDarkElevated = Color(0xFF444A47);
const Color slackDarkText = Color(0xFFFFFFFF);
const Color slackCyan = Color(0xFF36C5F0);
const Color slackGreen = Color(0xFF2BAC76);
const Color slackDivider = Color(0xFF2C3E50);

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
    scaffoldBackgroundColor: const Color(0xFFF8F8F2), // Dracula foreground as light bg
    primaryColor: const Color(0xFF282A36), // Dracula background as primary
    cardColor: const Color(0xFFBD93F9), // Dracula purple for cards
    appBarTheme: AppBarTheme(
      color: const Color(0xFFF8F8F2),
      elevation: 0,
      foregroundColor: const Color(0xFF282A36),
      surfaceTintColor: const Color(0xFFF8F8F2),
      iconTheme: const IconThemeData(color: Color(0xFF282A36)),
      titleTextStyle: GoogleFonts.inter(color: const Color(0xFF282A36), fontSize: 18, fontWeight: FontWeight.w600),
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).apply(bodyColor: const Color(0xFF282A36), displayColor: const Color(0xFF282A36)),
    iconTheme: const IconThemeData(color: Color(0xFF6272A4)), // Dracula comment color
    dividerColor: const Color(0xFF44475A), // Dracula selection
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFBD93F9), // Dracula purple
      foregroundColor: const Color(0xFF282A36),
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
    scaffoldBackgroundColor: slackDarkBackground,
    primaryColor: slackCyan,
    cardColor: slackDarkElevated,
    appBarTheme: AppBarTheme(
      color: slackDarkBackground,
      elevation: 0,
      foregroundColor: slackDarkText,
      surfaceTintColor: slackDarkBackground,
      iconTheme: const IconThemeData(color: slackDarkText),
      titleTextStyle: GoogleFonts.inter(color: slackDarkText, fontSize: 18, fontWeight: FontWeight.w600),
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: slackDarkText,
      displayColor: slackDarkText,
    ),
    iconTheme: const IconThemeData(color: slackCyan),
    dividerColor: slackDivider,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: slackCyan,
        foregroundColor: slackDarkBackground,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: slackDarkText),
    ),
    dialogBackgroundColor: slackDarkElevated,
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return slackGreen;
        }
        return Colors.grey;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return slackGreen.withOpacity(0.5);
        }
        return slackDivider;
      }),
    ),
  );
}

// <-- ADDED: Moved function here for global access
bool isLightTheme(BuildContext context) {
  return Theme.of(context).brightness == Brightness.light;
}