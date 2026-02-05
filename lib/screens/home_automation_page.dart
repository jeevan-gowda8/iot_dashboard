import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../api_config.dart';
import '../api_service.dart';

// 🔧 Device configuration model
class AutomationDevice {
  final String id;
  final String label;
  final String onEndpoint;
  final String offEndpoint;

  const AutomationDevice({
    required this.id,
    required this.label,
    required this.onEndpoint,
    required this.offEndpoint,
  });
}

// 🧩 Extension for keyed widgets (performance)
extension WidgetKeyed on Widget {
  Widget keyed({required Key key}) => KeyedSubtree(
        key: key,
        child: this,
      );
}

class HomeAutomationPage extends StatefulWidget {
  const HomeAutomationPage({super.key});

  @override
  State<HomeAutomationPage> createState() => _HomeAutomationPageState();
}

class _HomeAutomationPageState extends State<HomeAutomationPage> {
  Map<String, dynamic> home = {};
  Timer? _timer;
  bool _isLoading = true;

  // Track pending operations per device
  final Set<String> _pendingDevices = {};

  // Optimistic state that survives periodic refreshes
  final Map<String, bool> _optimisticStatus = {};

  // Device definitions
  static const List<AutomationDevice> _lights = [
    AutomationDevice(id: 'light1_hub', label: 'Light 1 Hub', onEndpoint: ApiConfig.light1On, offEndpoint: ApiConfig.light1Off),
    AutomationDevice(id: 'light2_hub', label: 'Light 2 Hub', onEndpoint: ApiConfig.light2On, offEndpoint: ApiConfig.light2Off),
    AutomationDevice(id: 'light3_hub', label: 'Light 3 Hub', onEndpoint: ApiConfig.light3On, offEndpoint: ApiConfig.light3Off),
    AutomationDevice(id: 'light4_hub', label: 'Light 4 Hub', onEndpoint: ApiConfig.light4On, offEndpoint: ApiConfig.light4Off),
  ];

  static const List<AutomationDevice> _fans = [
    AutomationDevice(id: 'fan1_hub', label: 'Fan 1 Hub', onEndpoint: ApiConfig.fan1On, offEndpoint: ApiConfig.fan1Off),
    AutomationDevice(id: 'fan2_hub', label: 'Fan 2 Hub', onEndpoint: ApiConfig.fan2On, offEndpoint: ApiConfig.fan2Off),
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => loadData());
  }

  Future<void> _loadInitialData() async {
    await loadData();
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> loadData() async {
    try {
      final rawData = await ApiService.fetchData(ApiConfig.homeData);

      if (rawData is! Map) {
        throw Exception('API returned non-Map data');
      }

      // ✅ FIXED: use debugPrint instead of print
      assert(() {
        debugPrint('[HomeAutomation] Loaded data keys: ${rawData.keys.join(', ')}');
        return true;
      }());

      // Safely extract string-keyed data
      final safeData = <String, dynamic>{};
      for (final entry in rawData.entries) {
        if (entry.key is String) {
          safeData[entry.key as String] = entry.value;
        }
      }

      if (mounted) {
        setState(() {
          home = safeData;
        });
      }
    } catch (e, stack) {
      // ✅ FIXED: use debugPrint instead of print
      assert(() {
        debugPrint('[HomeAutomation] Load error: $e\n$stack');
        return true;
      }());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load  $e')),
        );
      }
    }
  }

  bool isOn(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.toLowerCase().trim();
      return ['on', 'true', '1', 'enabled', 'active'].contains(s);
    }
    return false;
  }

  String? _getDeviceStatus(List<dynamic>? devices, String deviceId) {
    if (devices == null) return null;
    final device = devices
        .whereType<Map<dynamic, dynamic>>()
        .map((d) => d.map((k, v) => MapEntry(k.toString(), v)))
        .firstWhere(
          (d) => d['device_id'] == deviceId,
          orElse: () => {},
        );
    return device['status'] as String?;
  }

  bool _getEffectiveStatus(String deviceId) {
    return _optimisticStatus[deviceId] ?? _fetchStatusFromApi(deviceId);
  }

  bool _fetchStatusFromApi(String deviceId) {
    final lights = (home['lights'] as List<dynamic>?) ?? [];
    final fans = (home['fans'] as List<dynamic>?) ?? [];
    final allDevices = [...lights, ...fans];
    final statusStr = _getDeviceStatus(allDevices, deviceId);
    return isOn(statusStr);
  }

  Future<void> _toggleDevice(AutomationDevice device) async {
    final deviceId = device.id;
    final currentValue = _getEffectiveStatus(deviceId);
    final newValue = !currentValue;

    setState(() {
      _pendingDevices.add(deviceId);
      _optimisticStatus[deviceId] = newValue;
    });

    try {
      final endpoint = newValue ? device.onEndpoint : device.offEndpoint;
      await ApiService.postTrigger(endpoint);
      // Keep optimistic state — now confirmed
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: ${e.toString().substring(0, 80)}...')),
        );
        setState(() {
          _optimisticStatus[deviceId] = currentValue;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _pendingDevices.remove(deviceId);
        });
      }
    }
  }

  Widget _glassCard({required Widget child}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: (isDark ? Colors.black54 : Colors.white)
            .withValues(alpha: isDark ? 0.65 : 0.75),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _controlTile(AutomationDevice device) {
    final isPending = _pendingDevices.contains(device.id);
    final effectiveValue = _getEffectiveStatus(device.id);

    return _glassCard(
      child: Semantics(
        container: true,
        label: '${device.label}, ${effectiveValue ? 'on' : 'off'}',
        child: SwitchListTile.adaptive(
          title: Text(device.label, style: Theme.of(context).textTheme.titleMedium),
          value: effectiveValue,
          onChanged: isPending ? null : (value) => _toggleDevice(device),
          contentPadding: EdgeInsets.zero,
          dense: true,
          secondary: isPending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
        ),
      ),
    );
  }

  Widget _metricTile(String label, dynamic value, {String? unit}) {
    String displayValue;
    if (value == null || value == '' || value == 'null') {
      displayValue = '--';
    } else if (value is num) {
      displayValue = (value is double && value % 1 != 0)
          ? value.toStringAsFixed(1)
          : value.toString();
    } else {
      displayValue = value.toString();
    }

    return _glassCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text.rich(
            TextSpan(
              text: displayValue,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              children: unit != null
                  ? [
                      TextSpan(
                        text: ' $unit',
                        style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
                      )
                    ]
                  : [],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && home.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Home Automation")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Home Automation")),
      body: RefreshIndicator(
        onRefresh: () async {
          await loadData();
          // Do NOT clear optimistic state — preserve user intent
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // === System Info ===
            const Text("System Status", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _metricTile("Location", home['centre']),
            _metricTile("Last Updated", home['last_updated']),
            _metricTile("Battery", home['battery'], unit: "V"),
            _metricTile("Door Status", home['door_status']),
            _metricTile("Temperature", home['temperature'], unit: "°C"),
            _metricTile("Humidity", home['humidity'], unit: "%"),
            _metricTile("CO₂", home['co2'], unit: "ppm"),
            _metricTile("Pressure", home['pressure'], unit: "hPa"),

            const SizedBox(height: 24),

            // === Lights ===
            const Text("Lights", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._lights.map((device) => _controlTile(device).keyed(key: Key('light-${device.id}'))),

            const SizedBox(height: 24),

            // === Fans ===
            const Text("Fans", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._fans.map((device) => _controlTile(device).keyed(key: Key('fan-${device.id}'))),
          ],
        ),
      ),
    );
  }
}