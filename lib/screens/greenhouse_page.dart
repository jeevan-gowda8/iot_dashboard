import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart'; // debugPrint is available here
import '../api_config.dart';
import '../api_service.dart';

class GreenhouseDevice {
  final String id;
  final String label;
  final String onEndpoint;
  final String offEndpoint;

  const GreenhouseDevice({
    required this.id,
    required this.label,
    required this.onEndpoint,
    required this.offEndpoint,
  });
}

extension WidgetKeyed on Widget {
  Widget keyed({required Key key}) => KeyedSubtree(
        key: key,
        child: this,
      );
}

class GreenhousePage extends StatefulWidget {
  const GreenhousePage({super.key});

  @override
  State<GreenhousePage> createState() => _GreenhousePageState();
}

class _GreenhousePageState extends State<GreenhousePage> {
  Map<String, dynamic> gh = {};
  Timer? _timer;
  bool _isLoading = true;

  final Set<String> _pendingDevices = {};
  final Map<String, bool> _optimisticStatus = {};

  static const List<GreenhouseDevice> _devices = [
    GreenhouseDevice(id: 'fogger', label: 'Fogger', onEndpoint: ApiConfig.foggerOn, offEndpoint: ApiConfig.foggerOff),
    GreenhouseDevice(id: 'drip_irrigation', label: 'Drip Irrigation', onEndpoint: ApiConfig.dripOn, offEndpoint: ApiConfig.dripOff),
    GreenhouseDevice(id: 'exhaust_fan', label: 'Exhaust Fan', onEndpoint: ApiConfig.exhaustOn, offEndpoint: ApiConfig.exhaustOff),
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
      final rawData = await ApiService.fetchData(ApiConfig.greenhouseData);

      if (rawData is! Map) {
        throw Exception('API returned non-Map data');
      }

      assert(() {
        debugPrint('[Greenhouse] Loaded keys: ${rawData.keys.join(', ')}');
        return true;
      }());

      final safeData = <String, dynamic>{};
      for (final entry in rawData.entries) {
        if (entry.key is String) {
          safeData[entry.key as String] = entry.value;
        }
      }

      if (mounted) {
        setState(() {
          gh = safeData;
        });
      }
    } catch (e, stack) {
      assert(() {
        debugPrint('[Greenhouse] Load error: $e\n$stack');
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

  bool _getEffectiveStatus(String deviceId) {
    return _optimisticStatus[deviceId] ?? isOn(gh[deviceId]);
  }

  Future<void> _toggleDevice(GreenhouseDevice device) async {
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

  Widget _controlTile(GreenhouseDevice device) {
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
    if (_isLoading && gh.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Greenhouse Monitor")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Greenhouse Monitor")),
      body: RefreshIndicator(
        onRefresh: () async {
          await loadData();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text("Environment", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _metricTile("Temperature", gh['temp'], unit: "°C"),
            _metricTile("Humidity", gh['humi'], unit: "%"),
            _metricTile("CO₂", gh['co2'], unit: "ppm"),
            _metricTile("Atmospheric Pressure", gh['pressure'], unit: "hPa"),

            const SizedBox(height: 24),

            const Text("Soil Conditions", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _metricTile("Soil Temperature", gh['soil_temp'], unit: "°C"),
            _metricTile("Soil Humidity", gh['soil_humi'], unit: "%"),
            _metricTile("Moisture", gh['moisture'], unit: "%"),
            _metricTile("Soil Conductivity", gh['soil_conduct'], unit: "µS/cm"),
            _metricTile("pH", gh['pH']),

            const SizedBox(height: 24),

            const Text("Nutrient Levels", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _metricTile("Nitrogen (N)", gh['N'], unit: "mg/kg"),
            _metricTile("Phosphorus (P)", gh['P'], unit: "mg/kg"),
            _metricTile("Potassium (K)", gh['K'], unit: "mg/kg"),

            const SizedBox(height: 24),

            const Text("Water System", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _metricTile("Water Level", gh['water_level'], unit: "cm"),

            const SizedBox(height: 24),

            const Text("Controls", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._devices.map((device) => _controlTile(device).keyed(key: Key('gh-${device.id}'))),
          ],
        ),
      ),
    );
  }
}