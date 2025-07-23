import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeColors {
  const ThemeColors({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.highlight,
    required this.background,
    required this.surface,
    required this.text,
    required this.subTitle,
    required this.divider,
    required this.info,
    required this.success,
    required this.warning,
    required this.error,
    required this.border,
    required this.button,
    required this.hover,
    required this.shadow,
    required this.overlay,
    required this.muted,
    required this.focus,
    required this.active,
    required this.inactive,
    required this.disabled,
    required this.selection,
    required this.link,
    required this.visited,
    required this.cardBg,
    required this.inputBg,
    required this.tooltipBg,
    required this.tooltipText,
    required this.headerBg,
    required this.footerBg,
    required this.navigationBg,
    required this.sidebarBg,
    required this.modalBg,
    required this.scrollbarBg,
    required this.scrollbarHover,
    required this.skeletonBase,
    required this.skeletonHighlight,
    required this.backdropOverlay,
    required this.pressedState,
    required this.focusRing,
    required this.separatorLine,
    required this.digits,
    required this.digitShadow,
    required this.digitsDescription,
    required this.glassBorderColor,
    required this.glassGradientStart,
    required this.glassGradientEnd,
    required this.dice,
    required this.glitchCyan,
    required this.glitchMagenta,
    required this.glitchYellow,
    required this.glitchMatrix,
    required this.glitchCrimson,
    required this.glitchRoyal,
    required this.glitchVoid,
    required this.glitchWhite,
    required this.pending,
    required this.matrixBackground,
    required this.matrixGreen,
    required this.matrixWhite,
  });
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color highlight;
  final Color background;
  final Color surface;
  final Color text;
  final Color subTitle;
  final Color divider;
  final Color info;
  final Color success;
  final Color warning;
  final Color error;
  final Color border;
  final Color button;
  final Color hover;
  final Color shadow;
  final Color overlay;
  final Color muted;
  final Color focus;
  final Color active;
  final Color inactive;
  final Color disabled;
  final Color selection;
  final Color link;
  final Color visited;
  final Color cardBg;
  final Color inputBg;
  final Color tooltipBg;
  final Color tooltipText;
  final Color headerBg;
  final Color footerBg;
  final Color navigationBg;
  final Color sidebarBg;
  final Color modalBg;
  final Color scrollbarBg;
  final Color scrollbarHover;
  final Color skeletonBase;
  final Color skeletonHighlight;
  final Color backdropOverlay;
  final Color pressedState;
  final Color focusRing;
  final Color separatorLine;
  final Color digits;
  final Color digitShadow;
  final Color digitsDescription;
  final Color glassBorderColor;
  final Color glassGradientStart;
  final Color glassGradientEnd;
  final Color dice;
  final Color glitchCyan;
  final Color glitchMagenta;
  final Color glitchYellow;
  final Color glitchMatrix;
  final Color glitchCrimson;
  final Color glitchRoyal;
  final Color glitchVoid;
  final Color glitchWhite;
  final Color pending;
  final Color matrixBackground;
  final Color matrixGreen;
  final Color matrixWhite;

  static ThemeColors get light => const ThemeColors(
        primary: Color(0xFF00BFFF),
        secondary: Color(0xFF6A0DAD),
        accent: Color(0xFFDC143C),
        highlight: Color(0xFFFFD700),
        background: Color(0xFFFFFFFF),
        surface: Color(0xFFF9F9F9),
        cardBg: Color(0xFFFFFFFF),
        headerBg: Color(0xFFF5F5F5),
        footerBg: Color(0xFFF5F5F5),
        navigationBg: Color(0xFFFFFFFF),
        sidebarBg: Color(0xFFF5F5F5),
        modalBg: Color(0xFFFFFFFF),
        inputBg: Color(0xFFF0F0F0),
        text: Color(0xFF1A1A1A),
        subTitle: Color(0xFF666666),
        digits: Color(0xFF000000),
        digitShadow: Color.fromARGB(255, 131, 131, 131),
        digitsDescription: Color(0xFF666666),
        tooltipText: Color(0xFFFFFFFF),
        hover: Color(0xFF00A3CC),
        active: Color(0xFF00BFFF),
        inactive: Color(0xFFBDBDBD),
        disabled: Color(0xFFE0E0E0),
        pressedState: Color(0xFF009ACD),
        focus: Color(0xFF00BFFF),
        focusRing: Color(0xFF00BFFF),
        selection: Color(0xFF00BFFF),
        info: Color(0xFF00BFFF),
        success: Color(0xFF50C878),
        warning: Color(0xFFFFD700),
        error: Color(0xFFDC143C),
        border: Color(0xFFE0E0E0),
        divider: Color(0xFFE0E0E0),
        separatorLine: Color(0xFFE0E0E0),
        button: Color(0xFF00BFFF),
        link: Color(0xFF00BFFF),
        visited: Color(0xFF6A0DAD),
        shadow: Color(0x1A000000),
        overlay: Color(0x0A000000),
        backdropOverlay: Color(0x80000000),
        muted: Color(0xFF9E9E9E),
        skeletonBase: Color(0xFFE0E0E0),
        skeletonHighlight: Color(0xFFF5F5F5),
        scrollbarBg: Color(0xFFE0E0E0),
        scrollbarHover: Color(0xFFBDBDBD),
        tooltipBg: Color(0xFF424242),
        glassBorderColor: Color(0x33FFFFFF),
        glassGradientStart: Color.fromARGB(179, 255, 255, 255),
        glassGradientEnd: Color(0x4DFFFFFF),
        dice: Color(0xFF00BFFF),
        glitchCyan: Color(0xFF00BFFF),
        glitchMagenta: Color(0xFF6A0DAD),
        glitchYellow: Color(0xFFFFD700),
        glitchMatrix: Color(0xFF50C878),
        glitchCrimson: Color(0xFFDC143C),
        glitchRoyal: Color(0xFF00BFFF),
        glitchVoid: Color(0xFF000000),
        glitchWhite: Color(0xFFFFFFFF),
        pending: Color(0xFF00A3CC),
        matrixBackground: Color.fromARGB(255, 240, 240, 240),
        matrixGreen: Color(0xFF50C878),
        matrixWhite: Color.fromARGB(255, 0, 0, 0),
      );

  static ThemeColors get dark => const ThemeColors(
        primary: Color(0xFF00BFFF),
        secondary: Color(0xFF6A0DAD),
        accent: Color(0xFFDC143C),
        highlight: Color(0xFFFFD700),
        background: Color(0xFF121212),
        surface: Color(0xFF1E1E1E),
        cardBg: Color(0xFF2A2A2A),
        headerBg: Color(0xFF1E1E1E),
        footerBg: Color(0xFF1E1E1E),
        navigationBg: Color(0xFF1E1E1E),
        sidebarBg: Color(0xFF1E1E1E),
        modalBg: Color(0xFF2A2A2A),
        inputBg: Color(0xFF2A2A2A),
        text: Color(0xFFFFFFFF),
        subTitle: Color(0xFFB3B3B3),
        digits: Color(0xFFFFFFFF),
        digitShadow: Color.fromARGB(255, 131, 131, 131),
        digitsDescription: Color(0xFFB3B3B3),
        tooltipText: Color(0xFFFFFFFF),
        hover: Color(0xFF33CCFF),
        active: Color(0xFF00BFFF),
        inactive: Color(0xFF757575),
        disabled: Color(0xFF424242),
        pressedState: Color(0xFF009ACD),
        focus: Color(0xFF00BFFF),
        focusRing: Color(0xFF00BFFF),
        selection: Color(0xFF00BFFF),
        info: Color(0xFF00BFFF),
        success: Color(0xFF50C878),
        warning: Color(0xFFFFD700),
        error: Color(0xFFDC143C),
        border: Color(0xFF424242),
        divider: Color(0xFF424242),
        separatorLine: Color(0xFF424242),
        button: Color(0xFF00BFFF),
        link: Color(0xFF00BFFF),
        visited: Color(0xFF6A0DAD),
        shadow: Color(0x3F000000),
        overlay: Color(0x0AFFFFFF),
        backdropOverlay: Color(0xB3000000),
        muted: Color(0xFF757575),
        skeletonBase: Color(0xFF424242),
        skeletonHighlight: Color(0xFF616161),
        scrollbarBg: Color(0xFF424242),
        scrollbarHover: Color(0xFF616161),
        tooltipBg: Color(0xFF424242),
        glassBorderColor: Color(0x33FFFFFF),
        glassGradientStart: Color(0x4DFFFFFF),
        glassGradientEnd: Color(0x1AFFFFFF),
        dice: Color(0xFF00BFFF),
        glitchCyan: Color(0xFF00BFFF),
        glitchMagenta: Color(0xFF6A0DAD),
        glitchYellow: Color(0xFFFFD700),
        glitchMatrix: Color(0xFF50C878),
        glitchCrimson: Color(0xFFDC143C),
        glitchRoyal: Color(0xFF00BFFF),
        glitchVoid: Color(0xFF000000),
        glitchWhite: Color(0xFFFFFFFF),
        pending: Color(0xFF33CCFF),
        matrixBackground: Color.fromARGB(255, 0, 0, 0),
        matrixGreen: Color(0xFF50C878),
        matrixWhite: Color.fromARGB(255, 255, 255, 255),
      );
}

class AppThemeColors {
  static late ThemeColors current;
  static void initialize(bool isDark) {
    current = isDark ? ThemeColors.dark : ThemeColors.light;
  }
}

class AppTheme {
  static final ThemeData lightTheme = _buildTheme(
    brightness: Brightness.light,
    scheme: ColorScheme.fromSeed(seedColor: ThemeColors.light.primary),
  );
  static final ThemeData darkTheme = _buildTheme(
    brightness: Brightness.dark,
    scheme: ColorScheme.fromSeed(
      seedColor: ThemeColors.dark.primary,
      brightness: Brightness.dark,
    ),
  );
  static ThemeData _buildTheme({
    required Brightness brightness,
    required ColorScheme scheme,
  }) =>
      ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        brightness: brightness,
      );
}

enum ThemePreference { light, dark, system }

class ThemeProvider extends ChangeNotifier with WidgetsBindingObserver {
  ThemeProvider() {
    _init();
  }
  static const _themePreferenceKey = 'themePreference';
  static const _themeModifiedKey = 'themeModified';
  static const _initTimeout = Duration(seconds: 5);
  late final SharedPreferences _prefs;
  ThemePreference _themePreference = ThemePreference.system;
  bool _userModified = false;
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  ThemePreference get themePreference => _themePreference;
  ThemeData get theme {
    final isDark = isDarkMode;
    AppThemeColors.initialize(isDark);
    return isDark ? AppTheme.darkTheme : AppTheme.lightTheme;
  }

  bool get isDarkMode {
    if (!_userModified) {
      return PlatformDispatcher.instance.platformBrightness == Brightness.dark;
    }
    return switch (_themePreference) {
      ThemePreference.light => false,
      ThemePreference.dark => true,
      ThemePreference.system => PlatformDispatcher.instance.platformBrightness == Brightness.dark,
    };
  }

  ThemeMode get themeMode {
    if (!_userModified) return ThemeMode.system;
    return switch (_themePreference) {
      ThemePreference.light => ThemeMode.light,
      ThemePreference.dark => ThemeMode.dark,
      ThemePreference.system => ThemeMode.system,
    };
  }

  Future<void> _init() async {
    try {
      WidgetsBinding.instance.addObserver(this);
      _prefs = await SharedPreferences.getInstance().timeout(_initTimeout);
      await _loadThemeFromPrefs();
      _isInitialized = true;
      notifyListeners();
    } catch (e, stackTrace) {
      _isInitialized = false;
      debugPrint('Error initializing theme: $e\n$stackTrace');
      _themePreference = ThemePreference.system;
    }
  }

  @override
  void didChangePlatformBrightness() {
    if (!_userModified || _themePreference == ThemePreference.system) {
      notifyListeners();
    }
  }

  Future<void> _loadThemeFromPrefs() async {
    try {
      final modifiedResult = _prefs.getBool(_themeModifiedKey);
      _userModified = modifiedResult ?? false;
      if (_userModified) {
        final themeString = _prefs.getString(_themePreferenceKey);
        if (themeString != null) {
          _themePreference = ThemePreference.values.firstWhere(
            (e) => e.toString() == themeString,
            orElse: () => ThemePreference.system,
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Failed to load theme preferences: $e\n$stackTrace');
      _userModified = false;
      _themePreference = ThemePreference.system;
    }
  }

  Future<void> setThemePreference(ThemePreference preference) async {
    if (_themePreference == preference) return;
    try {
      _themePreference = preference;
      _userModified = true;
      await _prefs.setBool(_themeModifiedKey, true);
      await _prefs.setString(_themePreferenceKey, preference.toString());
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to save theme preference: $e');
    }
  }

  Future<void> resetToSystemTheme() async {
    try {
      _userModified = false;
      _themePreference = ThemePreference.system;
      await _prefs.setBool(_themeModifiedKey, false);
      await _prefs.remove(_themePreferenceKey);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to reset theme: $e');
    }
  }

  Future<void> toggleTheme() async {
    await setThemePreference(
      _themePreference == ThemePreference.dark ? ThemePreference.light : ThemePreference.dark,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

class AppConfiguration {
  AppConfiguration._();
  static late AppConfiguration _instance;
  static AppConfiguration get current => _instance;
  static Future<void> initialize() async {
    _instance = AppConfiguration._();
  }
}
