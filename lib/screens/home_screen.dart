import 'dart:async';
import 'package:flutter/material.dart';
import '../api_config.dart';
import '../api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int bottomIndex = 0;
  late Timer timer;
  DateTime now = DateTime.now();

  Map gh = {};
  Map home = {};

  @override
  void initState() {
    super.initState();
    loadData();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => now = DateTime.now());
    });
  }

  Future<void> loadData() async {
    gh = await ApiService.fetchData(ApiConfig.greenhouseData);
    home = await ApiService.fetchData(ApiConfig.homeData);
    setState(() {});
  }

  bool isOn(dynamic v) => v.toString().toLowerCase().contains("on");

  Widget device(String title, dynamic status, String on, String off) {
    return Card(
      child: SwitchListTile(
        title: Text(title),
        value: isOn(status),
        onChanged: (val) async {
          await ApiService.fetchData(val ? on : off); // GET
          await loadData();
        },
      ),
    );
  }

  // ---------------- HOME TAB ----------------
  Widget homeTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset("assets/logo.png", height: 100),
          const SizedBox(height: 20),
          Text(
            "${now.hour}:${now.minute}:${now.second}",
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            "${now.day}-${now.month}-${now.year}",
            style: const TextStyle(fontSize: 20),
          ),
        ],
      ),
    );
  }

  // ---------------- APPLICATION TAB ----------------
  Widget applicationTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text("Greenhouse", style: TextStyle(fontSize: 18)),
        device("Fogger", gh['fogger'], ApiConfig.foggerOn, ApiConfig.foggerOff),
        device("Drip Irrigation", gh['drip_irrigation'],
            ApiConfig.dripOn, ApiConfig.dripOff),
        device("Exhaust Fan", gh['exhaust_fan'],
            ApiConfig.exhaustOn, ApiConfig.exhaustOff),
        Card(
          child: ListTile(
            title: const Text("Temperature"),
            trailing: Text("${gh['t'] ?? '--'} °C"),
          ),
        ),
        Card(
          child: ListTile(
            title: const Text("Humidity"),
            trailing: Text("${gh['h'] ?? '--'} %"),
          ),
        ),
        const SizedBox(height: 20),
        const Text("Home Automation", style: TextStyle(fontSize: 18)),
        device("Light 1", home['light1_hub'],
            ApiConfig.light1On, ApiConfig.light1Off),
        device("Light 2", home['light2_hub'],
            ApiConfig.light2On, ApiConfig.light2Off),
        device("Light 3", home['light3_hub'],
            ApiConfig.light3On, ApiConfig.light3Off),
        device("Light 4", home['light4_hub'],
            ApiConfig.light4On, ApiConfig.light4Off),
        device("Fan 1", home['fan1_hub'],
            ApiConfig.fan1On, ApiConfig.fan1Off),
        device("Fan 2", home['fan2_hub'],
            ApiConfig.fan2On, ApiConfig.fan2Off),
        const SizedBox(height: 20),
        const Text("Street Light", style: TextStyle(fontSize: 18)),
        device("Street Light", "off",
            ApiConfig.streetOn, ApiConfig.streetOff),
      ],
    );
  }

  // ---------------- SETTINGS TAB ----------------
  Widget settingsTab() {
    return const Center(
      child: Text("Settings Page (You can add more here)"),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [homeTab(), applicationTab(), settingsTab()];

    return Scaffold(
      body: tabs[bottomIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        currentIndex: bottomIndex,
        onTap: (i) => setState(() => bottomIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.apps), label: "Application"),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }
}
