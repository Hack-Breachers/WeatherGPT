import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'services/location_service.dart';
import 'services/weather_cache_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'govt_view.dart';
import 'emergency_sos_dialog.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:telephony/telephony.dart';
import 'join_community_dialog.dart';
import 'donate_dialog.dart';
import 'services/language_service.dart';
import 'services/app_strings.dart';
import 'widgets/language_selector.dart';
import 'officer_login_dialogue.dart';


class MainCitizenScreen extends StatefulWidget {
  final VoidCallback? onToggleToGovt;
  const MainCitizenScreen({super.key, this.onToggleToGovt});

  @override
  State<MainCitizenScreen> createState() => _MainCitizenScreenState();
}

class _MainCitizenScreenState extends State<MainCitizenScreen> {
  // Use 10.0.2.2 if testing on Android Emulator, or your local/Ngrok URL
 String get baseUrl {
  return 'http://192.168.1.4:8000';
}

  double _currentLat = 0.0;
  double _currentLon = 0.0;
  String _locationName = "Detecting location...";
  String _userPhone = "+919876543210"; // Default or loaded from user profile
  
  bool _isLocating = false;
  bool _isOnline = false;
  DateTime? _lastLiveUpdate;
  DateTime? _lastCachedUpdate;

  static const Map<String, String> requestHeaders = {
    'Content-Type': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  };

  final TextEditingController _queryController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isLoadingChat = false;
  bool _isLoadingWeather = true;

  String _temp = "29°C";
  String _feelsLike = "Feels 33°C";
  String _humidity = "88%";
  String _rainProb = "92%";

  String _overallRisk = "UNKNOWN";
  String _riskHazard = "No active hazard";
  String _riskLevel = "UNKNOWN";
  int _maxRainProbability = 0;
  double _forecastPrecipitation = 0.0;
  int _highProbabilityHours = 0;

  String? _aiResponse;
  bool _isGrounded = true;

final List<Map<String, String>> _chatMessages = [];
bool _isChatExpanded = false;

  String _functionCall = 'regional hazards within 250 km';
int _nearbyEventCount = 0;
int _nearbyHighRiskCount = 0;
String _regionalStatus = 'Checking nearby disaster feeds...';
List<Map<String, dynamic>> _nearbyEvents = [];

bool _nearbyFeedOnline = false;
DateTime? _lastNearbyUpdate;

  @override
  void initState() {
    super.initState();
    _aiResponse = 'Detecting your location and assembling regional disaster intelligence...';
    _initializeAppLocation();

  }

  Future<String> _reverseGeocodeLocation(
    double latitude,
    double longitude,
  ) async {
  try {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
      '?lat=$latitude'
      '&lon=$longitude'
      '&format=json'
      '&zoom=10'
      '&addressdetails=1',
    );

    final response = await http.get(
      uri,
      headers: {
        'User-Agent': 'WeatherGPT/1.0',
      },
    );

    if (response.statusCode != 200) {
      return "Your Location";
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final address = data['address'] as Map<String, dynamic>? ?? {};

    final city = address['city'] ??
        address['town'] ??
        address['municipality'] ??
        address['village'] ??
        address['suburb'];

    final state = address['state'];

    if (city != null && state != null) {
      return "$city, $state";
    }

    if (city != null) {
      return city.toString();
    }

    if (state != null) {
      return state.toString();
    }

    return "Your Location";
  } catch (e) {
    debugPrint("Reverse geocoding failed: $e");
    return "Your Location";
  }
}



  Future<void> _initializeAppLocation() async {
  if (!mounted) return;

  setState(() {
    _isLocating = true;
    _isLoadingWeather = true;
    _locationName = "Detecting location...";
    _isOnline = false;
  });

  try {
    final pos = await LocationService.getCurrentLocation();

    if (!mounted) return;

    setState(() {
      _currentLat = pos.latitude;
      _currentLon = pos.longitude;
    });

    debugPrint(
      "LOCATION: ${pos.latitude}, ${pos.longitude}",
    );

    final detectedLocation = await _reverseGeocodeLocation(
      pos.latitude,
      pos.longitude,
    );

    if (!mounted) return;

    setState(() {
      _locationName = detectedLocation;
      _isLocating = false;
    });

    debugPrint(
      "LOCATION NAME: $detectedLocation",
    );

    await Future.wait([
      _fetchLiveWeather(),
      _fetchNearbyDisasterOverview(),
    ]);
  } catch (e) {
    if (!mounted) return;

    setState(() {
      _isLocating = false;
      _isLoadingWeather = false;
      _isOnline = false;
      _locationName = "Location unavailable";
      _overallRisk = "UNKNOWN";
      _riskHazard = "Weather unavailable";
      _riskLevel = "UNKNOWN";
    });

    debugPrint("LOCATION ERROR: $e");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Unable to detect your location: $e",
        ),
      ),
    );
  }
}

  Future<void> _syncDeviceLocation() async {
  if (_isLocating) return;

  setState(() => _isLocating = true);

  try {
    final pos = await LocationService.getCurrentLocation();

    final detectedLocation = await _reverseGeocodeLocation(
      pos.latitude,
      pos.longitude,
    );

    if (!mounted) return;

    setState(() {
      _currentLat = pos.latitude;
      _currentLon = pos.longitude;
      _locationName = detectedLocation;
      _isLocating = false;
    });

    _fetchLiveWeather();
    _fetchNearbyDisasterOverview();
  } catch (e) {
    if (!mounted) return;

    setState(() => _isLocating = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Location error: $e')),
    );
  }
}

  void _showLocationPickerDialog() {
    final latController = TextEditingController(text: _currentLat.toString());
    final lonController = TextEditingController(text: _currentLon.toString());

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Select Weather Location",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.my_location, color: Color(0xFF38BDF8)),
                  title: const Text("Use My Current GPS", style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    _syncDeviceLocation();
                  },
                ),
                const Divider(color: Color(0xFF1E293B)),
                const Text("Quick Presets", style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 8),
                _presetTile("Kolkata, India", 22.5726, 88.3639),
                _presetTile("New York, USA", 40.7128, -74.0060),
                const Divider(color: Color(0xFF1E293B)),
                const Text("Custom Coordinates", style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: latController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Latitude",
                          labelStyle: TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: lonController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Longitude",
                          labelStyle: TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF38BDF8),
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () async {
  final lat = double.tryParse(latController.text.trim());
  final lon = double.tryParse(lonController.text.trim());

  if (lat == null || lon == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please enter valid latitude and longitude."),
      ),
    );
    return;
  }

  if (lat < -90 || lat > 90) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Latitude must be between -90 and 90."),
      ),
    );
    return;
  }

  if (lon < -180 || lon > 180) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Longitude must be between -180 and 180."),
      ),
    );
    return;
  }

  Navigator.pop(context);

  await _setManualLocation(lat, lon);
},
                    child: const Text("Fetch Custom Location Weather"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _setManualLocation(double lat, double lon) async {
  if (!mounted) return;

  setState(() {
    _currentLat = lat;
    _currentLon = lon;
    _locationName = "Resolving location...";
    _isLocating = true;
    _isLoadingWeather = true;
  });

  debugPrint("MANUAL LOCATION: $lat, $lon");

  final detectedLocation = await _reverseGeocodeLocation(
    lat,
    lon,
  );

  if (!mounted) return;

  setState(() {
    _locationName = detectedLocation;
    _isLocating = false;
  });

  debugPrint("MANUAL LOCATION NAME: $detectedLocation");

  await Future.wait([
    _fetchLiveWeather(),
    _fetchNearbyDisasterOverview(),
  ]);
}

  Widget _buildConnectionIndicator() {
  final bool live = _isOnline;

  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 4,
    ),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      color: live
          ? Colors.green.withOpacity(0.12)
          : Colors.orange.withOpacity(0.12),
      border: Border.all(
        color: live
            ? Colors.green.withOpacity(0.35)
            : Colors.orange.withOpacity(0.35),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: live
                ? Colors.greenAccent
                : Colors.orangeAccent,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          live ? "LIVE" : "OFFLINE",
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: live
                ? Colors.greenAccent
                : Colors.orangeAccent,
          ),
        ),
      ],
    ),
  );
}

  Widget _presetTile(String name, double lat, double lon) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.location_city, color: Colors.grey, size: 18),
      title: Text(name, style: const TextStyle(color: Colors.white)),
      subtitle: Text("Lat: $lat, Lon: $lon", style: const TextStyle(color: Colors.grey, fontSize: 11)),
      onTap: () {
        Navigator.pop(context);
        setState(() {
          _currentLat = lat;
          _currentLon = lon;
          _locationName = name;
        });
        _fetchLiveWeather();
        _fetchNearbyDisasterOverview();
      },
    );
  }

  Future<void> _fetchLiveWeather() async {
  try {
    final res = await http.get(
      Uri.parse(
        '$baseUrl/api/v1/weather'
        '?latitude=$_currentLat'
        '&longitude=$_currentLon',
      ),
      headers: requestHeaders,
    );

    if (res.statusCode != 200) {
      throw Exception(
        "Weather API returned ${res.statusCode}",
      );
    }

    final data =
        jsonDecode(res.body) as Map<String, dynamic>;

    if (!mounted) return;

    setState(() {
      _isOnline = true;
      _lastLiveUpdate = DateTime.now();
      _lastCachedUpdate = null;
    });

    await WeatherCacheService.saveWeather(
      weatherData: data,
      latitude: _currentLat,
      longitude: _currentLon,
      locationName: _locationName,
    );

    final risk = data['risk'] is Map
        ? Map<String, dynamic>.from(data['risk'])
        : <String, dynamic>{};

    final hazards = risk['hazards'] is List
        ? List<dynamic>.from(risk['hazards'])
        : <dynamic>[];

    String hazardType = "No active hazard";
    String hazardLevel = "LOW";

    if (hazards.isNotEmpty &&
        hazards.first is Map) {
      final firstHazard =
          Map<String, dynamic>.from(
        hazards.first,
      );

      hazardType =
          firstHazard['type']?.toString() ??
              "Unknown hazard";

      hazardLevel =
          firstHazard['level']?.toString() ??
              "UNKNOWN";
    }

    final summary =
        risk['forecast_summary'] is Map
            ? Map<String, dynamic>.from(
                risk['forecast_summary'],
              )
            : <String, dynamic>{};

    if (!mounted) return;

    setState(() {
      _temp =
          data['temp']?.toString() ?? "-";

      _humidity =
          data['humidity']?.toString() ?? "-";

      _rainProb =
          data['rain_prob']?.toString() ?? "-";

      _feelsLike =
          "Feels ${data['apparent_temperature']?.toString() ?? '-'}";

      _overallRisk =
          risk['overall_risk']?.toString() ??
              "UNKNOWN";

      _riskHazard = hazardType;
      _riskLevel = hazardLevel;

      _maxRainProbability =
          (summary['max_rain_probability']
                      as num?)
                  ?.round() ??
              0;

      _forecastPrecipitation =
          (summary['total_precipitation']
                      as num?)
                  ?.toDouble() ??
              0.0;

      _highProbabilityHours =
          (summary['high_probability_hours']
                      as num?)
                  ?.toInt() ??
              0;

      _isLoadingWeather = false;
    });

    debugPrint(
      "LIVE WEATHER: Updated successfully.",
    );
  } catch (e) {
    debugPrint(
      "LIVE WEATHER FAILED: $e",
    );

    final cachedData =
        await WeatherCacheService.loadWeather();

    if (cachedData != null && mounted) {
      _lastCachedUpdate =
          await WeatherCacheService
              .getLastUpdated();

      final cachedRisk =
          cachedData['risk'] is Map
              ? Map<String, dynamic>.from(
                  cachedData['risk'],
                )
              : <String, dynamic>{};

      final cachedHazards =
          cachedRisk['hazards'] is List
              ? List<dynamic>.from(
                  cachedRisk['hazards'],
                )
              : <dynamic>[];

      String hazardType =
          "No active hazard";

      String hazardLevel = "LOW";

      if (cachedHazards.isNotEmpty &&
          cachedHazards.first is Map) {
        final firstHazard =
            Map<String, dynamic>.from(
          cachedHazards.first,
        );

        hazardType =
            firstHazard['type']?.toString() ??
                "Unknown hazard";

        hazardLevel =
            firstHazard['level']?.toString() ??
                "UNKNOWN";
      }

      final cachedSummary =
          cachedRisk['forecast_summary'] is Map
              ? Map<String, dynamic>.from(
                  cachedRisk[
                      'forecast_summary'],
                )
              : <String, dynamic>{};

      setState(() {
        _isOnline = false;

        _temp =
            cachedData['temp']?.toString() ??
                "-";

        _humidity =
            cachedData['humidity']?.toString() ??
                "-";

        _rainProb =
            cachedData['rain_prob']?.toString() ??
                "-";

        _feelsLike =
            "Feels ${cachedData['apparent_temperature']?.toString() ?? '-'}";

        _overallRisk =
            cachedRisk['overall_risk']
                    ?.toString() ??
                "UNKNOWN";

        _riskHazard = hazardType;
        _riskLevel = hazardLevel;

        _maxRainProbability =
            (cachedSummary[
                        'max_rain_probability']
                    as num?)
                ?.round() ??
            0;

        _forecastPrecipitation =
            (cachedSummary[
                        'total_precipitation']
                    as num?)
                ?.toDouble() ??
            0.0;

        _highProbabilityHours =
            (cachedSummary[
                        'high_probability_hours']
                    as num?)
                ?.toInt() ??
            0;

        _isLoadingWeather = false;
      });

      debugPrint(
        "OFFLINE: Loaded cached weather successfully.",
      );
    } else if (mounted) {
      setState(() {
        _isOnline = false;
        _isLoadingWeather = false;

        _overallRisk = "UNKNOWN";
        _riskHazard =
            "Weather unavailable";
        _riskLevel = "UNKNOWN";

        _maxRainProbability = 0;
        _forecastPrecipitation = 0.0;
        _highProbabilityHours = 0;
      });

      debugPrint(
        "OFFLINE: No cached weather available.",
      );
    }
  }
}

  Future<void> _fetchNearbyDisasterOverview() async {
    try {
      final res = await http.get(
        Uri.parse(
          '$baseUrl/api/disaster-events/nearby'
          '?latitude=$_currentLat'
          '&longitude=$_currentLon'
          '&radius_km=250',
        ),
        headers: requestHeaders,
      );
      if (res.statusCode != 200) throw Exception('Disaster API returned ${res.statusCode}');

      final decoded = jsonDecode(res.body);
      if (decoded is! List) throw Exception('Invalid disaster response');

      final nearby = <Map<String, dynamic>>[];

      for (final item in decoded) {
        if (item is! Map) continue;

        final event = Map<String, dynamic>.from(item);
        nearby.add(event);
      }

      final highRisk = nearby.where((event) {
        final severity = event['severity']?.toString().toUpperCase();
        return severity == 'HIGH' || severity == 'CRITICAL';
      }).length;

      if (!mounted) return;
      setState(() {
        _nearbyEvents = nearby.take(3).toList();
        _nearbyEventCount = nearby.length;
        _nearbyHighRiskCount = highRisk;
        _nearbyFeedOnline = true;
        _lastNearbyUpdate = DateTime.now();
        _regionalStatus = nearby.isEmpty
        ? 'No nearby disaster events are currently loaded.'
        : '$highRisk high-priority event${highRisk == 1 ? '' : 's'} within 250 km.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _nearbyFeedOnline = false;
        _nearbyEvents = [];
        _nearbyEventCount = 0;
        _nearbyHighRiskCount = 0;
        _regionalStatus = 'Nearby disaster feed unavailable right now.';
      });
    }
  }

  String _riskTitle() {
    switch (_riskHazard) {
      case 'HEAVY_RAIN':
        return AppStrings.t(
          context,
          'heavy_rain_advisory',
        );

      case 'FORECAST_HEAVY_RAIN':
        return AppStrings.t(
          context,
          'heavy_rain_forecast',
        );

      case 'URBAN_FLOOD':
        return AppStrings.t(
          context,
          'urban_flood_risk',
        );

      case 'THUNDERSTORM':
        return AppStrings.t(
          context,
          'thunderstorm_risk',
        );

      default:
        return AppStrings.t(
          context,
          'weather_risk_advisory',
        );
    }
  }

  String _riskReason() {
    if (_riskHazard == 'No active hazard') {
      return AppStrings.t(
        context,
        'no_significant_weather_hazard',
      );
    }

    if (_riskHazard == 'Weather unavailable') {
      return AppStrings.t(
        context,
        'live_weather_unavailable',
      );
    }

    final rainText = AppStrings.format(
      context,
      'rain_data_summary',
      values: {
        'rain': _maxRainProbability.toString(),
        'precipitation':
            _forecastPrecipitation.toStringAsFixed(1),
      },
    );

    switch (_riskHazard) {
      case 'HEAVY_RAIN':
        return '${AppStrings.t(context, 'rain_probability_elevated')} $rainText';

      case 'FORECAST_HEAVY_RAIN':
        return '${AppStrings.t(context, 'upcoming_rain_probability')} $rainText';

      case 'URBAN_FLOOD':
        return '${AppStrings.t(context, 'urban_flood_risk_detected')} $rainText';

      case 'THUNDERSTORM':
        return AppStrings.t(
          context,
          'thunderstorm_conditions',
        );

      default:
        return '${AppStrings.t(context, 'elevated_weather_condition')} $rainText';
    }
  }

  String _riskProtocol() {
    switch (_riskHazard) {
      case 'HEAVY_RAIN':
      case 'FORECAST_HEAVY_RAIN':
        return AppStrings.t(
          context,
          'protocol_heavy_rain',
        );

      case 'URBAN_FLOOD':
        return AppStrings.t(
          context,
          'protocol_flood',
        );

      case 'THUNDERSTORM':
        return AppStrings.t(
          context,
          'protocol_thunderstorm',
        );

      case 'Weather unavailable':
        return AppStrings.t(
          context,
          'protocol_unavailable',
        );

      default:
        return AppStrings.t(
          context,
          'protocol_default',
        );
    }
  }

  Color _riskColor() {
    switch (_overallRisk) {
      case "CRITICAL":
      case "HIGH":
        return const Color(0xFFE11D48);
      case "MEDIUM":
        return const Color(0xFFF59E0B);
      case "LOW":
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _riskBadgeText() {
    return _overallRisk == "UNKNOWN" ? "UNAVAILABLE" : _overallRisk;
  }

  Future<void> _sendChatQuery(String query) async {
    if (query.trim().isEmpty) return;
    final userQuery = query.trim();
    setState(() {
      _chatMessages.add({
        'role': 'user',
        'content': userQuery,
      });
      _queryController.clear();
      _isChatExpanded = true;
    });
    _scrollChatToLatest();
    setState(() {
      _isLoadingChat = true;
      _aiResponse = 'Analyzing your request with the latest available weather and hazard data...';
    });
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/v1/chat'),
        headers: requestHeaders,
        body: jsonEncode({
          'query': query,
          'latitude': _currentLat,
          'longitude': _currentLon,

          // Current selected language
          'language': LanguageScope.of(context).language.code,
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _aiResponse = data['reply'] ?? data['response'];
          _chatMessages.add({
            'role': 'assistant',
            'content': _aiResponse ?? '',
          });
          _isGrounded = data['grounded'] ?? true;
          _functionCall = data['call'] ?? 'analyze_weather_risk(location="${data['location'] ?? _locationName}", window="6h")';
          _isLoadingChat = false;
        });
        _scrollChatToLatest();
      } else {
        throw Exception("Status ${res.statusCode}");
      }
    } catch (e) {
      setState(() {
        _aiResponse = "I couldn't reach the conversational service right now. Please use the live weather and risk information shown on the dashboard.";
        _isGrounded = true;
        _isLoadingChat = false;
      });
    }
  }

  void _scrollChatToLatest() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!_chatScrollController.hasClients) return;

    _chatScrollController.animateTo(
      _chatScrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  });
}

  void openSOSModal() {
  EmergencySosDialog.show(
    context,
    lat: _currentLat,
    lng: _currentLon,
  );
}
  

  void _showOfficerLogin() {
  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: "Officer Login",
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, animation, secondaryAnimation) {
      return OfficerLoginDialog(
        onLoginSuccess: () {
          widget.onToggleToGovt?.call();
        },
      );
    },
    transitionBuilder:
        (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );

      return FadeTransition(
        opacity: curvedAnimation,
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 0.92,
            end: 1.0,
          ).animate(curvedAnimation),
          child: child,
        ),
      );
    },
  );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: HamburgerDrawer(
       onOfficerLogin: _showOfficerLogin,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 18),
                  _buildLocationSelector(),
                  const SizedBox(height: 24),
                  Text(
                    AppStrings.t(context, 'greeting'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSearchInput(),
                  const SizedBox(height: 10),
                  _buildSuggestions(),
                  const SizedBox(height: 18),
                  _buildAIIntelligenceCard(),
                  const SizedBox(height: 24),
                  const Text(
                    "Current Area & Nearby Disaster Alerts",
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  _buildSevereWarningCard(),
                  const SizedBox(height: 12),
                  _buildAmberWaterloggingCard(),
                  const SizedBox(height: 16),
                  _buildTelemetryRow(),
                ],
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: InkWell(
                onTap: openSOSModal,
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.t(context, 'sos_help'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
  return Row(
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF38BDF8).withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.waves,
          color: Color(0xFF38BDF8),
          size: 18,
        ),
      ),

      const SizedBox(width: 8),

      const Expanded(
        child: Text(
          "WeatherGPT",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),

      // LIVE / OFFLINE indicator
      _buildConnectionIndicator(),

      const SizedBox(width: 6),

      InkWell(
        onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
        borderRadius: BorderRadius.circular(20),
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(
            Icons.menu,
            color: Colors.white70,
            size: 28,
          ),
        ),
      ),
    ],
  );
}

  Widget _buildLocationSelector() {
    return Center(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _showLocationPickerDialog,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isLocating ? Icons.hourglass_top : Icons.location_on,
                color: const Color(0xFF38BDF8),
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                _isLocating ? "Fetching GPS..." : _locationName,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchInput() {
  return AnimatedContainer(
    duration: const Duration(milliseconds: 250),
    curve: Curves.easeOut,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF0F172A),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: _isChatExpanded
            ? const Color(0xFF0284C7)
            : const Color(0xFF1E293B),
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Chat header
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Color(0xFF38BDF8),
                size: 17,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "WeatherGPT",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "AI weather & safety assistant",
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(
                _isChatExpanded
                    ? Icons.keyboard_arrow_down
                    : Icons.keyboard_arrow_up,
                color: const Color(0xFF64748B),
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _isChatExpanded = !_isChatExpanded;
                });
              },
            ),
          ],
        ),

        // Conversation history
        if (_isChatExpanded && _chatMessages.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            constraints: const BoxConstraints(
              maxHeight: 260,
            ),
            child: ListView.builder(
              controller: _chatScrollController,
              shrinkWrap: true,
              itemCount: _chatMessages.length,
              itemBuilder: (context, index) {
                final message = _chatMessages[index];
                final isUser = message['role'] == 'user';

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: 300,
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? const Color(0xFF0284C7)
                          : const Color(0xFF070D18),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: Radius.circular(isUser ? 12 : 3),
                        bottomRight: Radius.circular(isUser ? 3 : 12),
                      ),
                      border: isUser
                          ? null
                          : Border.all(
                              color: const Color(0xFF1E293B),
                            ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isUser) ...[
                          const Icon(
                            Icons.auto_awesome,
                            size: 13,
                            color: Color(0xFF38BDF8),
                          ),
                          const SizedBox(width: 7),
                        ],
                        Expanded(
                          child: Text(
                            message['content'] ?? '',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],

        if (_isChatExpanded && _isLoadingChat) ...[
          const SizedBox(height: 6),
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: Color(0xFF38BDF8),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Analyzing weather and hazard data...",
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 8),

        // Input area
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _queryController,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.send,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                ),
                decoration: const InputDecoration(
                  hintText: "Ask about your weather or safety...",
                  hintStyle: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                ),
                onTap: () {
                  if (!_isChatExpanded) {
                    setState(() {
                      _isChatExpanded = true;
                    });
                  }
                },
                onSubmitted: _sendChatQuery,
              ),
            ),

            // Microphone
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.mic_none,
                color: Color(0xFF64748B),
                size: 20,
              ),
              onPressed: () {},
            ),

            // Send
            Container(
              decoration: BoxDecoration(
                color: _isLoadingChat
                    ? const Color(0xFF334155)
                    : const Color(0xFF0284C7),
                borderRadius: BorderRadius.circular(9),
              ),
              child: IconButton(
                visualDensity: VisualDensity.compact,
                icon: _isLoadingChat
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.arrow_upward,
                        color: Colors.white,
                        size: 17,
                      ),
                onPressed: _isLoadingChat
                    ? null
                    : () => _sendChatQuery(_queryController.text),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

  Widget _buildSuggestions() {
    final suggestions = [AppStrings.t(context, 'rain_forecast'),AppStrings.t(context, 'thunderstorm_warnings'),AppStrings.t(context, 'emergency_shelters'),AppStrings.t(context, 'flood_alerts')];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: suggestions.map((text) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              backgroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: const BorderSide(color: Color(0xFF1E293B)),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              onPressed: () {
                _queryController.text = text;
                _sendChatQuery(text);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

String _formatUpdateTime(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.hour >= 12 ? 'PM' : 'AM';

  return '$hour:$minute $period';
}

    Widget _buildAIIntelligenceCard() {
    final bool hasEvents = _nearbyEvents.isNotEmpty;
    final bool isLive = _nearbyFeedOnline;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1E293B),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.my_location,
                  color: Color(0xFF38BDF8),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),

               Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                  AppStrings.t(context, 'regional_hazard_monitor')    ,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Live regional event feed � 250 km radius',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isLive
                      ? const Color(0xFF064E3B).withValues(alpha: 0.5)
                      : const Color(0xFF78350F).withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isLive
                        ? const Color(0xFF059669).withValues(alpha: 0.6)
                        : const Color(0xFFD97706).withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isLive
                            ? const Color(0xFF34D399)
                            : const Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isLive ? 'LIVE' : 'OFFLINE',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: isLive
                            ? const Color(0xFF34D399)
                            : const Color(0xFFFBBF24),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          const Divider(
            color: Color(0xFF1E293B),
            height: 1,
          ),

          const SizedBox(height: 14),

          if (hasEvents) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Nearby events',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${_nearbyEventCount} found',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            ..._nearbyEvents.map(
              (event) => _buildRegionalEventCard(event),
            ),
          ] else ...[
            const SizedBox(height: 8),

            const Center(
              child: Icon(
                Icons.check_circle_outline,
                color: Color(0xFF34D399),
                size: 42,
              ),
            ),

            const SizedBox(height: 10),

            const Center(
              child: Text(
                'No nearby hazards detected',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 6),

            Center(
              child: Text(
                isLive
                    ? 'Monitoring a 250 km radius around your location'
                    : 'Regional hazard feed is currently unavailable',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                  height: 1.4,
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          const Divider(
            color: Color(0xFF1E293B),
            height: 1,
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 22,
                color: Color(0xFF38BDF8),
              ),
              const SizedBox(width: 8),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coverage radius',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '250 km',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.access_time,
                size: 20,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(width: 8),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Last checked',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _lastNearbyUpdate != null
                          ? _formatUpdateTime(_lastNearbyUpdate!)
                          : 'Not checked',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

    Widget _buildRegionalEventCard(Map<String, dynamic> event) {
    final severity =
        event['severity']?.toString().toUpperCase() ?? 'UNKNOWN';

    final distance =
        (event['distance_km'] as num?)?.toDouble() ?? 0;

    final title =
        event['title']?.toString() ?? 'Unnamed event';

    final hazard =
        event['hazard_type']?.toString() ?? 'Hazard';

    final source =
        event['source']?.toString() ?? 'Regional feed';

    Color accent;

    switch (severity) {
      case 'CRITICAL':
      case 'HIGH':
        accent = const Color(0xFFF43F5E);
        break;
      case 'MEDIUM':
        accent = const Color(0xFFF59E0B);
        break;
      case 'LOW':
        accent = const Color(0xFF10B981);
        break;
      default:
        accent = const Color(0xFF64748B);
    }

    final hazardLower = hazard.toLowerCase();

    IconData icon;

    if (hazardLower.contains('thunder') ||
        hazardLower.contains('lightning')) {
      icon = Icons.thunderstorm;
    } else if (hazardLower.contains('rain') ||
        hazardLower.contains('flood') ||
        hazardLower.contains('water')) {
      icon = Icons.cloud;
    } else if (hazardLower.contains('cyclone') ||
        hazardLower.contains('storm')) {
      icon = Icons.cyclone;
    } else if (hazardLower.contains('heat')) {
      icon = Icons.wb_sunny_outlined;
    } else if (hazardLower.contains('fire')) {
      icon = Icons.local_fire_department_outlined;
    } else {
      icon = Icons.warning_amber_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF111B2E),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: const Color(0xFF1E293B),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 42,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          const SizedBox(width: 10),

          Icon(
            icon,
            color: accent,
            size: 25,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_formatHazardLabel(hazard)} � $source',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${distance.toStringAsFixed(0)} km',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFCBD5E1),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _formatSeverity(severity),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatHazardLabel(String hazard) {
    return hazard
        .replaceAll('_', ' ')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map(
          (word) =>
              '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String _formatSeverity(String severity) {
    switch (severity) {
      case 'CRITICAL':
        return 'Critical';
      case 'HIGH':
        return 'High';
      case 'MEDIUM':
        return 'Medium';
      case 'LOW':
        return 'Low';
      default:
        return 'Unknown';
    }
  }

  Widget _regionalEventRow(String title, String subtitle, String level) {
    final Color dotColor;
    switch (level) {
      case 'CRITICAL':
      case 'HIGH':
        dotColor = const Color(0xFFF43F5E);
        break;
      case 'MEDIUM':
        dotColor = const Color(0xFFF59E0B);
        break;
      case 'LOW':
      case 'CLEAR':
        dotColor = const Color(0xFF10B981);
        break;
      default:
        dotColor = const Color(0xFF64748B);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.8, color: Colors.white70)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 9.5, color: Colors.white38)),
              ],
            ),
          ),
          Text(level, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: dotColor)),
        ],
      ),
    );
  }

  Widget _buildSevereWarningCard() {
    final riskColor = _riskColor();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: riskColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: riskColor.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: riskColor, borderRadius: BorderRadius.circular(4)),
                child: Text(
                  _riskBadgeText(),
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _riskTitle(),
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_riskReason(), style: const TextStyle(fontSize: 11, color: Colors.white70, height: 1.35)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              MetricStat(val: _rainProb, label: "current rain prob."),
              MetricStat(val: "$_maxRainProbability%", label: "next 6h max"),
              MetricStat(val: _overallRisk, label: "overall risk"),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: riskColor.withOpacity(0.18), height: 1),
          const SizedBox(height: 8),
          Text(_riskProtocol(), style: const TextStyle(fontSize: 9.5, color: Colors.white60)),
        ],
      ),
    );
  }

bool _hasVerifiedRainHazard() {
  return _riskHazard == "HEAVY_RAIN" ||
      _riskHazard == "FORECAST_HEAVY_RAIN" ||
      _riskHazard == "URBAN_FLOOD";
}

  Widget _buildAmberWaterloggingCard() {
  final bool showForecastWarning = _hasVerifiedRainHazard();
 final String advisoryTitle = showForecastWarning
    ? AppStrings.t(
        context,
        'rain_advisory_elevated',
      )
    : AppStrings.t(
        context,
        'rain_monitoring_no_hazard',
      );

  final Color advisoryColor = showForecastWarning
      ? const Color(0xFFF59E0B)
      : const Color(0xFF38BDF8);

  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF1B1407),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: const Color(0xFFD97706).withOpacity(0.35),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              showForecastWarning
                  ? Icons.warning_amber_rounded
                  : Icons.info_outline,
              color: advisoryColor,
              size: 16,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                advisoryTitle,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: advisoryColor,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (_maxRainProbability / 100).clamp(0.0, 1.0),
            minHeight: 4,
            backgroundColor: const Color(0xFF2E220C),
            valueColor: AlwaysStoppedAnimation<Color>(
              advisoryColor,
            ),
          ),
        ),

        const SizedBox(height: 6),

        Text(
          "Next 6 h: $_maxRainProbability% maximum rain probability � "
          "${_forecastPrecipitation.toStringAsFixed(1)} mm forecast precipitation.",
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white60,
          ),
        ),
      ],
    ),
  );
}

  Widget _buildTelemetryRow() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: _buildTelemetryTile(
              _temp,
              _feelsLike,
              Icons.thermostat,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTelemetryTile(
              _humidity,
              "Humidity",
              Icons.water_drop_outlined,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTelemetryTile(
              _rainProb,
              "Rain probability",
              Icons.grain,
            ),
          ),
        ],
      ),

      if (_lastCachedUpdate != null) ...[
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              Icons.history,
              size: 13,
              color: Colors.orangeAccent,
            ),
            const SizedBox(width: 5),
            Text(
              "Last updated: ${_formatUpdateTime(_lastCachedUpdate!)}",
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ],
    ],
  );
}

  Widget _buildTelemetryTile(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF38BDF8), size: 18),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}

class MetricStat extends StatelessWidget {
  final String val;
  final String label;
  const MetricStat({super.key, required this.val, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9.5, color: Colors.white60)),
      ],
    );
  }
}



class HamburgerDrawer extends StatefulWidget {
  final VoidCallback onOfficerLogin;

  const HamburgerDrawer({
    super.key,
    required this.onOfficerLogin,
  });

  @override
  State<HamburgerDrawer> createState() => _HamburgerDrawerState();
}

class _HamburgerDrawerState extends State<HamburgerDrawer> {
  bool _offlineSim = false;

  @override
Widget build(BuildContext context) {
  return Drawer(
    backgroundColor: const Color(0xFF0F172A),
    child: SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 20,
        ),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "WeatherGPT",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close,
                  color: Colors.grey,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Officer Login
          ListTile(
            dense: true,
            leading: const Icon(
              Icons.admin_panel_settings,
              color: Color(0xFF38BDF8),
              size: 20,
            ),
            title: const Text(
              "Officer Login",
              style: TextStyle(
                fontSize: 13,
                color: Colors.white,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            tileColor: const Color(0xFF1F293B).withOpacity(0.5),
            onTap: () {
              Navigator.pop(context);
              widget.onOfficerLogin();
            },
          ),

          const SizedBox(height: 8),

          // Donate Now
          ListTile(
            dense: true,
            leading: const Icon(
              Icons.favorite_border,
              color: Color(0xFF38BDF8),
              size: 20,
            ),
            title: const Text(
              "Donate Now",
              style: TextStyle(
                fontSize: 13,
                color: Colors.white,
              ),
            ),
            tileColor: const Color(0xFF1E293B).withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            onTap: () {
              Navigator.pop(context);

              showDialog(
                context: context,
                barrierColor: Colors.black87,
                builder: (context) => const DonateReliefDialog(),
              );
            },
          ),

          const SizedBox(height: 8),

          // Join Rescue Community
          ListTile(
            dense: true,
            leading: const Icon(
              Icons.people_outline,
              color: Color(0xFF38BDF8),
              size: 20,
            ),
            title: const Text(
              "Join Rescue Community",
              style: TextStyle(
                fontSize: 13,
                color: Colors.white,
              ),
            ),
            tileColor: const Color(0xFF1E293B).withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            onTap: () {
              Navigator.pop(context);

              showDialog(
                context: context,
                barrierColor: Colors.black87,
                builder: (context) =>
                    const JoinRescueCommunityDialog(),
              );
            },
          ),

          const SizedBox(height: 20),

          const Divider(
            color: Color(0xFF334155),
          ),

          const SizedBox(height: 10),

          // Real multilingual selector
          const LanguageSelector(),

          const SizedBox(height: 24),

          // Offline Mode Simulator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.wifi_off,
                    size: 16,
                    color: Colors.grey,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Offline Mode Simulator",
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Switch(
                value: _offlineSim,
                activeThumbColor: const Color(0xFF38BDF8),
                onChanged: (val) {
                  setState(() => _offlineSim = val);

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        val
                            ? "Offline simulator active"
                            : "Online mode restored",
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ),
  );
} 
}