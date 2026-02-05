import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with TickerProviderStateMixin {
  DateTime now = DateTime.now();
  Timer? _timer;
  late AnimationController _timeChangeController;
  bool _justChangedHour = false;

  @override
  void initState() {
    super.initState();

    _timeChangeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      final newNow = DateTime.now();
      final wasSameMinute = now.minute == newNow.minute;
      final changedHour = now.hour != newNow.hour;

      setState(() {
        now = newNow;
      });

      if (!wasSameMinute) {
        // ✅ FIXED: Stop any ongoing animation before restarting
        if (_timeChangeController.isAnimating) {
          _timeChangeController.stop();
        }
        _timeChangeController.forward(from: 0.0);

        if (changedHour && !_justChangedHour) {
          _justChangedHour = true;
          HapticFeedback.lightImpact();
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) setState(() => _justChangedHour = false);
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timeChangeController.dispose();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String _month(int m) {
    const months = [
      '', 'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    return months[m];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textScaler = MediaQuery.textScalerOf(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Semantics(
              container: true,
              label: 'Welcome to Campus Monitor',
              child: Column(
                children: [
                  Text(
                    "WELCOME",
                    style: GoogleFonts.orbitron(
                      fontSize: textScaler.scale(34),
                      letterSpacing: 6,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "TO",
                    style: GoogleFonts.orbitron(
                      fontSize: textScaler.scale(22),
                      letterSpacing: 4,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "CAMPUS MONITOR",
                    style: GoogleFonts.orbitron(
                      fontSize: textScaler.scale(25),
                      letterSpacing: 5,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            Tooltip(
              message: 'Live campus clock',
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: SizedBox(
                  width: 300,
                  height: 300,
                  child: CustomPaint(
                    painter: NeonRingClockPainter(now, theme),
                    child: Center(
                      child: FadeTransition(
                        opacity: _timeChangeController,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _timeChangeController,
                              curve: Curves.easeOut,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "${_two(now.hour)}:${_two(now.minute)}",
                                key: const Key('live-time-display'),
                                style: GoogleFonts.poppins(
                                  fontSize: textScaler.scale(42),
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "${now.day} ${_month(now.month)} ${now.year}",
                                style: (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                  fontSize: textScaler.scale(theme.textTheme.bodyMedium?.fontSize ?? 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NeonRingClockPainter extends CustomPainter {
  final DateTime time;
  final ThemeData theme;

  NeonRingClockPainter(this.time, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.shortestSide < 100) return;

    final center = Offset(size.width / 2, size.height / 2);
    const baseRadius = 120.0;
    const innerRadius = 90.0;

    final basePaint = Paint()
      ..color = theme.dividerColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    canvas.drawCircle(center, baseRadius, basePaint);
    canvas.drawCircle(center, innerRadius, basePaint);

    final secondsFraction = time.second / 60.0;
    final secAngle = secondsFraction * 2 * pi;

    final secPaint = Paint()
      ..color = theme.colorScheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: baseRadius),
      -pi / 2,
      secAngle,
      false,
      secPaint,
    );

    final minutesFraction = (time.minute + time.second / 60.0) / 60.0;
    final minAngle = minutesFraction * 2 * pi;

    final minPaint = Paint()
      ..color = theme.colorScheme.onSurface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: innerRadius),
      -pi / 2,
      minAngle,
      false,
      minPaint,
    );
  }

  @override
  bool shouldRepaint(NeonRingClockPainter oldDelegate) {
    return oldDelegate.time.second != time.second ||
           oldDelegate.time.minute != time.minute;
  }
}