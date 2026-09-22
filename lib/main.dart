import 'package:flutter/material.dart';
import 'citizen_view.dart';
import 'govt_view.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const WeatherGPTApp());
}

class WeatherGPTApp extends StatelessWidget {
  const WeatherGPTApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WeatherGPT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF070D18),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38BDF8),
          surface: Color(0xFF0F172A),
        ),
        fontFamily: 'Roboto',
      ),
      home: const AppViewNavigator(),
    );
  }
}

class AppViewNavigator extends StatefulWidget {
  const AppViewNavigator({super.key});

  @override
  State<AppViewNavigator> createState() => _AppViewNavigatorState();
}

class _AppViewNavigatorState extends State<AppViewNavigator> {
  bool _isGovtView = false;

  // WeatherGPT native background mesh relay bridge.
  static const MethodChannel _meshRelayChannel =
      MethodChannel('weathergpt/mesh_relay');

  Future<void> _startMeshRelay() async {
    try {
      await _meshRelayChannel.invokeMethod('startRelay');
      debugPrint('WeatherGPT mesh relay started');
    } catch (e) {
      debugPrint('Failed to start mesh relay: $e');
    }
  }
  

  @override
void initState() {
  super.initState();

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    debugPrint('WeatherGPT: requesting native mesh relay');
    await _startMeshRelay();
    debugPrint('WeatherGPT: native mesh relay request completed');
  });
}

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _isGovtView
          ? GovtCommandScreen(
              key: const ValueKey('GovtView'),
              onToggleToCitizen: () => setState(() => _isGovtView = false),
            )
          : MainCitizenScreen(
              key: const ValueKey('CitizenView'),
              onToggleToGovt: () => setState(() => _isGovtView = true),
            ),
    );
  }
}