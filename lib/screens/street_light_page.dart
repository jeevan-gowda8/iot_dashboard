import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../api_config.dart';
import '../api_service.dart';

class StreetLightPage extends StatefulWidget {
  const StreetLightPage({super.key});

  @override
  State<StreetLightPage> createState() => _StreetLightPageState();
}

class _StreetLightPageState extends State<StreetLightPage> {
  bool _isLightOn = false;
  bool _isPending = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchStatus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool _isOn(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.toLowerCase().trim();
      return ['on', 'true', '1', 'enabled', 'active'].contains(s);
    }
    return false;
  }

  Future<void> _fetchStatus() async {
    try {
      final rawData = await ApiService.fetchData(ApiConfig.streetStatus);

      assert(() {
        debugPrint('[StreetLight] Raw status: $rawData');
        return true;
      }());

      final effectiveStatus = _isOn(rawData);

      if (mounted && !_isPending) {
        setState(() {
          _isLightOn = effectiveStatus;
        });
      }
    } catch (e, stack) {
      assert(() {
        debugPrint('[StreetLight] Fetch error: $e\n$stack');
        return true;
      }());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch status: $e')),
        );
      }
    }
  }

  Future<void> _toggleLight(bool newValue) async {
    if (_isPending) return;

    final previousValue = _isLightOn;
    setState(() {
      _isPending = true;
      _isLightOn = newValue;
    });

    try {
      final endpoint = newValue ? ApiConfig.streetOn : ApiConfig.streetOff;
      await ApiService.postTrigger(endpoint);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: ${e.toString().substring(0, 80)}...')),
        );
        setState(() {
          _isLightOn = previousValue;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPending = false;
        });
      }
    }
  }

  List<Color> _cardGradient(ThemeData theme) {
    final glow = _isLightOn
        ? theme.colorScheme.primary
        : theme.colorScheme.secondary;
    return [
      glow.withValues(alpha: 0.30),
      theme.scaffoldBackgroundColor,
    ];
  }

  Color _glow(ThemeData theme) => _isLightOn
      ? theme.colorScheme.primary
      : theme.colorScheme.secondary;

  Color _glassColor(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.04);

  Color _borderColor(ThemeData theme) =>
      theme.brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.black.withValues(alpha: 0.08);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Street Light"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _cardGradient(theme),
            ),
            boxShadow: [
              BoxShadow(
                color: _glow(theme).withValues(alpha: 0.35),
                blurRadius: 45,
                spreadRadius: 2,
              ),
            ],
            border: Border.all(color: _borderColor(theme)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                color: _glassColor(theme),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lightbulb,
                      size: 80,
                      color: _glow(theme),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _isLightOn
                          ? "STREET LIGHT IS ON"
                          : "STREET LIGHT IS OFF",
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    Semantics(
                      container: true,
                      label: 'Street light, ${_isLightOn ? 'on' : 'off'}',
                      child: Switch.adaptive(
                        value: _isLightOn,
                        // ✅ FIXED: activeColor → activeThumbColor
                        activeThumbColor: theme.colorScheme.primary,
                        onChanged: _isPending ? null : _toggleLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}