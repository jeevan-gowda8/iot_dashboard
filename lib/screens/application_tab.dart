import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // for haptics
import 'package:google_fonts/google_fonts.dart';

import 'greenhouse_page.dart';
import 'home_automation_page.dart';
import 'street_light_page.dart';

class ApplicationTab extends StatelessWidget {
  const ApplicationTab({super.key});

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
            "APPLICATIONS",
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: theme.colorScheme.primary,
            ),
          ),

          const SizedBox(height: 30),

          _glassTile(
            context,
            icon: Icons.eco,
            title: "Greenhouse",
            subtitle: "Control fogger, drip, exhaust",
            page: const GreenhousePage(),
          ),

          const SizedBox(height: 20),

          _glassTile(
            context,
            icon: Icons.home,
            title: "Home Automation",
            subtitle: "Lights, fans and smart controls",
            page: const HomeAutomationPage(),
          ),

          const SizedBox(height: 20),

          _glassTile(
            context,
            icon: Icons.lightbulb,
            title: "Street Light System",
            subtitle: "Control street lighting",
            page: const StreetLightPage(),
          ),
        ],
      ),
    );
  }

  Widget _glassTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget page,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      container: true,
      label: '$title, $subtitle',
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: () {
          HapticFeedback.lightImpact(); // subtle haptic feedback
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                // ✅ Theme-aware background
                color: (isDark ? Colors.black : Colors.white).withValues(alpha: isDark ? 0.15 : 0.05),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.4),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 50,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}