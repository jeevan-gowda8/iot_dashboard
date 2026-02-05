import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsTab extends StatelessWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;

  const SettingsTab({
    super.key,
    required this.onThemeToggle,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 20),

          Text(
            "SETTINGS",
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: theme.colorScheme.primary,
            ),
          ),

          const SizedBox(height: 30),

          // 🌙 Theme Toggle
          _glassTile(
            context,
            child: Semantics(
              container: true,
              label: 'Toggle dark theme',
              child: Row(
                children: [
                  Icon(
                    isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    color: theme.colorScheme.primary,
                    size: 30,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      "Dark Theme",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Switch.adaptive(
                    value: isDarkMode,
                    onChanged: (value) => onThemeToggle(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ℹ️ App Info
          _glassTile(
            context,
            child: Semantics(
              container: true,
              label: 'View app information',
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                    size: 30,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      "App Information",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 📄 Description
          _glassTile(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Campus Monitor v1.0",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Smart monitoring system for Greenhouse, Home Automation and Street Light using Thingsay API integration.",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassTile(BuildContext context, {required Widget child}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            // ✅ Theme-aware background
            color: (isDark ? Colors.black : Colors.white).withOpacity(isDark ? 0.15 : 0.05),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.4),
              width: 1.2,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}