import 'package:flutter/material.dart';
import 'screens/main_nav.dart'; // Adjust path if needed

void main() {
  runApp(const CampusMonitorApp());
}

class CampusMonitorApp extends StatefulWidget {
  const CampusMonitorApp({super.key});

  @override
  CampusMonitorAppState createState() => CampusMonitorAppState();
}

class CampusMonitorAppState extends State<CampusMonitorApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  /// Toggles between light and dark theme.
  void toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _themeMode == ThemeMode.dark;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Campus Monitor",
      themeMode: _themeMode,

      // Light theme
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFACBAC4),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),

      // Dark theme
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFACBAC4),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),

      // ✅ Pass theme state to navigation
      home: MainNavigation(
        isDarkMode: isDarkMode,
        onThemeToggle: () => toggleTheme(!isDarkMode),
      ),
    );
  }
}