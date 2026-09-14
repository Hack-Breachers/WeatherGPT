import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'services/location_service.dart';
import 'services/mesh_engine.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class MainCitizenScreen extends StatefulWidget {
  final VoidCallback? onToggleToGovt;
  const MainCitizenScreen({super.key, this.onToggleToGovt});

  @override
  State<MainCitizenScreen> createState() => _MainCitizenScreenState();
}

class _MainCitizenScreenState extends State<MainCitizenScreen> {
  // Use 10.0.2.2 if testing on Android Emulator, or your local/Ngrok URL
  String get baseUrl {
  if (kIsWeb) {
    return 'http://127.0.0.1:8000'; // Chrome / Web
  }
  return 'http://10.0.2.2:8000';    // Android Emulator (or your LAN IP for physical device)
}

  double _currentLat = 22.5726;
  double _currentLon = 88.3639;
  String _locationName = "Kolkata, WB";
  String _userPhone = "+919876543210"; // Default or loaded from user profile
  bool _isLocating = false;

  static const Map<String, String> requestHeaders = {
    'Content-Type': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  };

  final TextEditingController _queryController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isLoadingChat = false;
  bool _isLoadingWeather = true;

  String _temp = "29°";
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
  String _functionCall = 'summarize_regional_hazards(radius_km=250)';

  int _nearbyEventCount = 0;
  int _nearbyHighRiskCount = 0;
  String _regionalStatus = 'Checking nearby disaster feeds...';
  List<Map<String, dynamic>> _nearbyEvents = [];

  @override
  void initState() {
    super.initState();
    _fetchLiveWeather();
    _fetchNearbyDisasterOverview();
    _aiResponse = 'Regional disaster intelligence is being assembled from nearby event feeds.';
  }

  Future<void> _syncDeviceLocation() async {
    setState(() => _isLocating = true);
    try {
      final pos = await LocationService.getCurrentLocation();
      setState(() {
        _currentLat = pos.latitude;
        _currentLon = pos.longitude;
        _locationName = "${pos.latitude.toStringAsFixed(2)}, ${pos.longitude.toStringAsFixed(2)}";
        _isLocating = false;
      });
      _fetchLiveWeather();
    } catch (e) {
      setState(() => _isLocating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location error: $e')),
        );
      }
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
                _presetTile("New York, USA", 40.7128, -74.0060),
                _presetTile("Miami, Florida", 25.7617, -80.1918),
                _presetTile("Los Angeles, California", 34.0522, -118.2437),
                _presetTile("Kolkata, India", 22.5726, 88.3639),
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
                    onPressed: () {
                      final lat = double.tryParse(latController.text.trim());
                      final lon = double.tryParse(lonController.text.trim());
                      if (lat != null && lon != null) {
                        Navigator.pop(context);
                        setState(() {
                          _currentLat = lat;
                          _currentLon = lon;
                          _locationName = "${lat.toStringAsFixed(2)}, ${lon.toStringAsFixed(2)}";
                        });
                        _fetchLiveWeather();
                      }
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
      },
    );
  }

  Future<void> _fetchLiveWeather() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/v1/weather?lat=$_currentLat&lon=$_currentLon'),
        headers: requestHeaders,
      );
      if (res.statusCode != 200) throw Exception("Weather API returned ${res.statusCode}");

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final risk = data['risk'] is Map ? Map<String, dynamic>.from(data['risk']) : <String, dynamic>{};
      final hazards = risk['hazards'] is List ? List<dynamic>.from(risk['hazards']) : <dynamic>[];

      String hazardType = "No active hazard";
      String hazardLevel = "LOW";
      if (hazards.isNotEmpty && hazards.first is Map) {
        final firstHazard = Map<String, dynamic>.from(hazards.first);
        hazardType = firstHazard['type']?.toString() ?? "Unknown hazard";
        hazardLevel = firstHazard['level']?.toString() ?? "UNKNOWN";
      }

      final summary = risk['forecast_summary'] is Map ? Map<String, dynamic>.from(risk['forecast_summary']) : <String, dynamic>{};

      setState(() {
        _temp = data['temp']?.toString() ?? "-";
        _humidity = data['humidity']?.toString() ?? "-";
        _rainProb = data['rain_prob']?.toString() ?? "-";
        _feelsLike = "Feels ${data['apparent_temperature']?.toString() ?? '-'}";
        _overallRisk = risk['overall_risk']?.toString() ?? "UNKNOWN";
        _riskHazard = hazardType;
        _riskLevel = hazardLevel;
        _maxRainProbability = (summary['max_rain_probability'] as num?)?.round() ?? 0;
        _forecastPrecipitation = (summary['total_precipitation'] as num?)?.toDouble() ?? 0.0;
        _highProbabilityHours = (summary['high_probability_hours'] as num?)?.toInt() ?? 0;
        _isLoadingWeather = false;
      });
    } catch (_) {
      setState(() {
        _isLoadingWeather = false;
        _overallRisk = "UNKNOWN";
        _riskHazard = "Weather unavailable";
        _riskLevel = "UNKNOWN";
        _maxRainProbability = 0;
        _forecastPrecipitation = 0.0;
        _highProbabilityHours = 0;
      });
    }
  }

  double distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180.0;
    final dLon = (lon2 - lon1) * math.pi / 180.0;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180.0) * math.cos(lat2 * math.pi / 180.0) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  Future<void> _fetchNearbyDisasterOverview() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/disaster-events/'),
        headers: requestHeaders,
      );
      if (res.statusCode != 200) throw Exception('Disaster API returned ${res.statusCode}');

      final decoded = jsonDecode(res.body);
      if (decoded is! List) throw Exception('Invalid disaster response');

      final nearby = <Map<String, dynamic>>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final event = Map<String, dynamic>.from(item);
        final lat = (event['latitude'] as num?)?.toDouble();
        final lon = (event['longitude'] as num?)?.toDouble();
        if (lat == null || lon == null) continue;
        final distance = distanceKm(22.5726, 88.3639, lat, lon);
        if (distance <= 250) {
          event['distance_km'] = distance;
          nearby.add(event);
        }
      }

      nearby.sort((a, b) {
        const priority = {'CRITICAL': 4, 'HIGH': 3, 'MEDIUM': 2, 'LOW': 1};
        final ar = priority[a['severity']?.toString().toUpperCase()] ?? 0;
        final br = priority[b['severity']?.toString().toUpperCase()] ?? 0;
        if (ar != br) return br.compareTo(ar);
        return ((a['distance_km'] as num?)?.toDouble() ?? 9999).compareTo((b['distance_km'] as num?)?.toDouble() ?? 9999);
      });

      final highRisk = nearby.where((event) {
        final severity = event['severity']?.toString().toUpperCase();
        return severity == 'HIGH' || severity == 'CRITICAL';
      }).length;

      if (!mounted) return;
      setState(() {
        _nearbyEvents = nearby.take(3).toList();
        _nearbyEventCount = nearby.length;
        _nearbyHighRiskCount = highRisk;
        _regionalStatus = nearby.isEmpty
            ? 'No nearby disaster events are currently loaded.'
            : '$highRisk high-priority event${highRisk == 1 ? '' : 's'} within 250 km.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _nearbyEvents = [];
        _nearbyEventCount = 0;
        _nearbyHighRiskCount = 0;
        _regionalStatus = 'Nearby disaster feed unavailable right now.';
      });
    }
  }

  String _riskTitle() {
    switch (_riskHazard) {
      case "HEAVY_RAIN":
        return "Heavy Rain Advisory";
      case "FORECAST_HEAVY_RAIN":
        return "Heavy Rain Forecast";
      case "URBAN_FLOOD":
        return "Urban Flood Risk";
      case "THUNDERSTORM":
        return "Thunderstorm Risk";
      default:
        return "Weather Risk Advisory";
    }
  }

  String _riskReason() {
    if (_riskHazard == "No active hazard") {
      return "No significant weather hazard has been detected by the current risk engine.";
    }
    if (_riskHazard == "Weather unavailable") {
      return "Live weather data is currently unavailable.";
    }
    final rainText = "Next 6 h: $_maxRainProbability% maximum rain probability, ${_forecastPrecipitation.toStringAsFixed(1)} mm forecast precipitation.";
    switch (_riskHazard) {
      case "HEAVY_RAIN":
        return "Rain probability is elevated. $rainText";
      case "FORECAST_HEAVY_RAIN":
        return "Multiple upcoming hours show elevated rainfall probability. $rainText";
      case "URBAN_FLOOD":
        return "Forecast rainfall accumulation indicates elevated urban flood risk. $rainText";
      case "THUNDERSTORM":
        return "Thunderstorm conditions are indicated in the forecast.";
      default:
        return "The weather risk engine has detected an elevated condition. $rainText";
    }
  }

  String _riskProtocol() {
    switch (_riskHazard) {
      case "HEAVY_RAIN":
      case "FORECAST_HEAVY_RAIN":
        return "Protocol: carry rain protection, avoid waterlogged roads and monitor official alerts.";
      case "URBAN_FLOOD":
        return "Protocol: avoid underpasses and flooded roads; move to safer elevated areas if water rises.";
      case "THUNDERSTORM":
        return "Protocol: stay indoors, avoid open areas and do not shelter under isolated trees.";
      case "Weather unavailable":
        return "Protocol: check your connection and rely on official emergency information if conditions are unsafe.";
      default:
        return "Protocol: continue monitoring weather conditions and official alerts.";
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
          'city': query,
          'latitude': _currentLat,
          'longitude': _currentLon,
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _aiResponse = data['reply'] ?? data['response'];
          _isGrounded = data['grounded'] ?? true;
          _functionCall = data['call'] ?? 'analyze_weather_risk(location="${data['location'] ?? _locationName}", window="6h")';
          _isLoadingChat = false;
        });
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

  void openSOSModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EmergencySOSDialog(
        baseUrl: baseUrl,
        lat: _currentLat,
        lon: _currentLon,
        phone: _userPhone,
      ),
    );
  }
  

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: const HamburgerDrawer(),
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
                  const Text(
                    "Hi there! How can I help you today?",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
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
                    children: const [
                      Icon(Icons.shield_outlined, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "SOS / HELP",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.8),
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
          child: const Icon(Icons.waves, color: Color(0xFF38BDF8), size: 18),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            "WeatherGPT",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  "Citizen",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              InkWell(
                onTap: widget.onToggleToGovt,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: Text(
                    "Govt",
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 2),
        InkWell(
          onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
          borderRadius: BorderRadius.circular(20),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.menu, color: Colors.white70, size: 22),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _queryController,
              style: const TextStyle(fontSize: 13, color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Text something (e.g., 'Will it flood in Salt Lake tonight?')",
                hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                border: InputBorder.none,
              ),
              onSubmitted: _sendChatQuery,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.mic_none, color: Color(0xFF64748B), size: 20),
            onPressed: () {},
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: _isLoadingChat
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.navigation, color: Colors.white, size: 15),
              onPressed: () => _sendChatQuery(_queryController.text),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    final suggestions = ["Rain forecast", "Flood alerts", "Farmer crop advisory", "Emergency shelters"];
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

  Widget _buildAIIntelligenceCard() {
    final bool hasEvents = _nearbyEvents.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Text('WeatherGPT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF38BDF8))),
                  Text(' · live analysis', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _isGrounded ? const Color(0xFF064E3B).withOpacity(0.5) : const Color(0xFF78350F).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isGrounded ? const Color(0xFF059669).withOpacity(0.6) : const Color(0xFFD97706).withOpacity(0.6),
                  ),
                ),
                child: Text(
                  _isGrounded ? 'Grounded' : 'Live Feed',
                  style: TextStyle(
                    color: _isGrounded ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_functionCall, style: const TextStyle(fontFamily: 'monospace', fontSize: 10.5, color: Color(0xFF64748B))),
          const SizedBox(height: 10),
          Text(
            _isLoadingChat
                ? 'Analyzing the latest available regional information...'
                : (_aiResponse ?? (hasEvents ? 'Regional situation: $_nearbyEventCount nearby disaster events detected.' : _regionalStatus)),
            style: const TextStyle(fontSize: 12.5, color: Colors.white, height: 1.4),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF070D18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.location_searching, size: 14, color: Color(0xFF38BDF8)),
                    SizedBox(width: 6),
                    Text('Nearby situation 250 km', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.white70)),
                  ],
                ),
                const SizedBox(height: 10),
                if (hasEvents)
                  ..._nearbyEvents.map((event) {
                    final severity = event['severity']?.toString().toUpperCase() ?? 'UNKNOWN';
                    final distance = (event['distance_km'] as num?)?.toDouble() ?? 0;
                    final title = event['title']?.toString() ?? 'Unnamed event';
                    final hazard = event['hazard_type']?.toString() ?? 'Hazard';
                    return _regionalEventRow(title, '$hazard ${distance.toStringAsFixed(0)} km', severity);
                  })
                else ...[
                  _regionalEventRow('Disaster events', '0 currently loaded', 'CLEAR'),
                  const SizedBox(height: 3),
                  Text(_regionalStatus, style: const TextStyle(fontSize: 10.5, color: Colors.white54)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
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
              MetricStat(val: _rainProb, label: "current rain"),
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

  Widget _buildAmberWaterloggingCard() {
    final bool showForecastWarning = _forecastPrecipitation > 0 || _maxRainProbability >= 60;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1407),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD97706).withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                showForecastWarning ? Icons.warning_amber_rounded : Icons.info_outline,
                color: showForecastWarning ? const Color(0xFFF59E0B) : const Color(0xFF38BDF8),
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  showForecastWarning ? "Forecast monitoring: elevated rain probability" : "Forecast monitoring: no significant accumulation",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: showForecastWarning ? const Color(0xFFF59E0B) : const Color(0xFF38BDF8),
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
                showForecastWarning ? const Color(0xFFF59E0B) : const Color(0xFF38BDF8),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Next 6 h: $_maxRainProbability% maximum rain probability. ${_forecastPrecipitation.toStringAsFixed(1)} mm precipitation.",
            style: const TextStyle(fontSize: 10, color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryRow() {
    return Row(
      children: [
        Expanded(child: _buildTelemetryTile(_temp, _feelsLike, Icons.thermostat)),
        const SizedBox(width: 8),
        Expanded(child: _buildTelemetryTile(_humidity, "Humidity", Icons.water_drop_outlined)),
        const SizedBox(width: 8),
        Expanded(child: _buildTelemetryTile(_rainProb, "Rain probability", Icons.grain)),
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

class EmergencySOSDialog extends StatefulWidget {
  final String baseUrl;
  final double lat;
  final double lon;
  final String phone;

  const EmergencySOSDialog({
    super.key,
    required this.baseUrl,
    required this.lat,
    required this.lon,
    required this.phone,
  });

  @override
  State<EmergencySOSDialog> createState() => _EmergencySOSDialogState();
}

class _EmergencySOSDialogState extends State<EmergencySOSDialog> {
  bool _isSentOnline = false;
  bool _isMeshActive = false;
  bool _isTransmitting = false;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.phone);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    MeshEngine().stopMesh();
    super.dispose();
  }

  Future<void> _toggleEmergencyBroadcast() async {
    if (_isMeshActive) {
      // User tapped STOP -> Halt native BLE radios
      setState(() {
        _isMeshActive = false;
        _isSentOnline = false;
        _isTransmitting = false;
      });
      await MeshEngine().stopMesh();
      return;
    }

    // User tapped TRANSMIT -> Activate Beacon
    setState(() {
      _isMeshActive = true;
      _isTransmitting = true;
    });

    // 1. Attempt online cloud sync first (FastAPI backend)
    try {
      final res = await http.post(
        Uri.parse('${widget.baseUrl}/api/v1/sos'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'phone': _phoneController.text.trim(),
          'latitude': widget.lat,
          'longitude': widget.lon,
          'category': 'STRANDED',
          'severity': 4,
        }),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200 && mounted) {
        setState(() {
          _isSentOnline = true;
          _isTransmitting = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isTransmitting = false);
    }

    // 2. Engage local hardware BLE Mesh Cluster
    await MeshEngine().startMesh(
      userName: "Citizen_${_phoneController.text.trim()}",
      onPacketReceived: (packet) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Relayed SOS from ${packet.phone} (Hop ${packet.hops})"),
              backgroundColor: const Color(0xFF0284C7),
            ),
          );
        }
      },
    );

    // 3. Transmit packet over physical BLE radio
    await MeshEngine().sendSosDistressBeacon(
      phone: _phoneController.text.trim(),
      lat: widget.lat,
      lon: widget.lon,
    );
  }

  Future<void> _triggerOfflineSMS() async {
    final String latStr = widget.lat.toStringAsFixed(4);
    final String lonStr = widget.lon.toStringAsFixed(4);
    final Uri uri = Uri.parse(
        'sms:112?body=WXGPT|SOS|LAT:$latStr|LON:$lonStr|SEV:4|CODE:7MJUG1XT+5F');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _makeCall(String number) async {
    final Uri uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF0B1120),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Modal Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.crisis_alert, color: Color(0xFFE11D48), size: 22),
                  SizedBox(width: 8),
                  Text(
                    "Emergency Distress & Helplines",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            "Passive directory. Distress beacons are only broadcast when explicitly engaged.",
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 14),

          // 1. Deliberate Distress Activation Bar
          _buildMeshActivationButton(),
          const SizedBox(height: 12),

          // 2. Dynamic Radio / Network Status Banner
          BleMeshVisualizer(isBroadcasting: _isMeshActive),
          const SizedBox(height: 14),

          // 3. Offline GPS Packet Engine
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Offline GPS Packet Engine",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF38BDF8),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                        const Text(
                        "Open Location Code:\n7MJUG1XT+5F",
                        style: TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                        Text(
                        "Coordinates:\n${widget.lat.toStringAsFixed(4)}, ${widget.lon.toStringAsFixed(4)}",
                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                    ],
                    ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    minimumSize: const Size(double.infinity, 38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.sms, size: 16),
                  label: const Text(
                    "Dispatch Encoded SMS Payload (112)",
                    style: TextStyle(fontSize: 12),
                  ),
                  onPressed: _triggerOfflineSMS,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Emergency Speed Dial Directory
          const Text(
            "Emergency Speed Dial",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _dialerButton("112", "National", () => _makeCall("112")),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _dialerButton("101", "Fire", () => _makeCall("101")),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _dialerButton("1070", "Disaster", () => _makeCall("1070")),
              ),
            ],
          ),
        ],
      ),
    );
  }

 

  Widget _buildMeshActivationButton() {
    return InkWell(
      onTap: _toggleEmergencyBroadcast,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: _isMeshActive ? const Color(0xFF4C0519) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isMeshActive ? const Color(0xFFEF4444) : const Color(0xFF334155),
            width: 1.5,
          ),
          boxShadow: _isMeshActive
              ? [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withOpacity(0.35),
                    blurRadius: 12,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              _isMeshActive ? Icons.sensors : Icons.sensors_off,
              color: _isMeshActive ? const Color(0xFFFECDD3) : const Color(0xFF64748B),
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isMeshActive
                        ? "BROADCASTING DISTRESS BEACON"
                        : "ACTIVATE EMERGENCY BEACON",
                    style: TextStyle(
                      color: _isMeshActive ? Colors.white : const Color(0xFFCBD5E1),
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isMeshActive
                        ? "Pinging nearby handsets via peer-to-peer BLE relay"
                        : "Tap only if you are in immediate danger & require rescue",
                    style: TextStyle(
                      color: _isMeshActive ? Colors.white70 : const Color(0xFF64748B),
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _isMeshActive ? const Color(0xFFE11D48) : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _isMeshActive ? "STOP" : "TRANSMIT",
                style: TextStyle(
                  color: _isMeshActive ? Colors.white : const Color(0xFF38BDF8),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBroadcastStatusBanner() {
    if (!_isMeshActive) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Row(
          children: const [
            Icon(Icons.shield_outlined, size: 16, color: Color(0xFF64748B)),
            SizedBox(width: 8),
            Text(
              "Radio standby: 0 active distress packets transmitting",
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    final bool online = _isSentOnline;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: online
            ? const Color(0xFF064E3B).withOpacity(0.35)
            : const Color(0xFF78350F).withOpacity(0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: online ? const Color(0xFF059669) : const Color(0xFFD97706),
        ),
      ),
      child: Row(
        children: [
          if (_isTransmitting)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amberAccent),
            )
          else
            Icon(
              online ? Icons.check_circle : Icons.sync_problem,
              size: 16,
              color: online ? Colors.greenAccent : Colors.amberAccent,
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              online
                  ? "Control Room synced · BLE Peer relay beacon active (Hop 0/4)"
                  : "Cellular offline · Re-routing distress packet through local BLE mesh",
              style: TextStyle(
                fontSize: 11,
                color: online ? Colors.greenAccent : Colors.amberAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialerButton(String num, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Column(
          children: [
            Text(
              num,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 9.5, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class HamburgerDrawer extends StatefulWidget {
  const HamburgerDrawer({super.key});

  @override
  State<HamburgerDrawer> createState() => _HamburgerDrawerState();
}

class _HamburgerDrawerState extends State<HamburgerDrawer> {
  bool _offlineSim = false;
  String _selectedLang = "English";

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF0F172A),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("WeatherGPT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              dense: true,
              leading: const Icon(Icons.favorite_border, color: Color(0xFF38BDF8), size: 20),
              title: const Text("Donate Now", style: TextStyle(fontSize: 13, color: Colors.white)),
              tileColor: const Color(0xFF1E293B).withOpacity(0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
            ListTile(
              dense: true,
              leading: const Icon(Icons.people_outline, color: Color(0xFF38BDF8), size: 20),
              title: const Text("Join Rescue Community", style: TextStyle(fontSize: 13, color: Colors.white)),
              tileColor: const Color(0xFF1E293B).withOpacity(0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 20),
            const Divider(color: Color(0xFF334155)),
            const SizedBox(height: 10),
            Row(
              children: const [
                Icon(Icons.language, size: 14, color: Colors.grey),
                SizedBox(width: 6),
                Text("Language", style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _langChip("English"),
                const SizedBox(width: 6),
                _langChip("हिंदी"),
                const SizedBox(width: 6),
                _langChip("বাংলা"),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.wifi_off, size: 16, color: Colors.grey),
                    SizedBox(width: 8),
                    Text("Offline Mode Simulator", style: TextStyle(fontSize: 12.5, color: Colors.white)),
                  ],
                ),
                Switch(
                  value: _offlineSim,
                  activeThumbColor: const Color(0xFF38BDF8),
                  onChanged: (val) {
                    setState(() => _offlineSim = val);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(val ? "Offline simulator active" : "Online mode restored")),
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

  Widget _langChip(String label) {
    final bool isSelected = _selectedLang == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedLang = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.grey),
        ),
      ),
    );
  }
}







class BleMeshVisualizer extends StatefulWidget {
  final bool isBroadcasting;

  const BleMeshVisualizer({super.key, required this.isBroadcasting});

  @override
  State<BleMeshVisualizer> createState() => _BleMeshVisualizerState();
}

class _BleMeshVisualizerState extends State<BleMeshVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _hopTimer;
  int _activeHop = 0;

  final List<Map<String, dynamic>> _nodes = [
    {"title": "Citizen Node", "sub": "This Device", "icon": Icons.phone_android},
    {"title": "Relay Peer 1", "sub": "Nearby Phone", "icon": Icons.phone_android},
    {"title": "Relay Peer 2", "sub": "Moving Vehicle", "icon": Icons.directions_boat},
    {"title": "Relay Peer 3", "sub": "Relief Post", "icon": Icons.router},
    {"title": "Gateway HQ", "sub": "Control Tower", "icon": Icons.cell_tower},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    if (widget.isBroadcasting) {
      _startHopSimulation();
    }
  }

  @override
  void didUpdateWidget(covariant BleMeshVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isBroadcasting && !oldWidget.isBroadcasting) {
      _startHopSimulation();
    } else if (!widget.isBroadcasting && oldWidget.isBroadcasting) {
      _stopHopSimulation();
    }
  }

  void _startHopSimulation() {
    _pulseController.repeat(reverse: true);
    _activeHop = 0;
    _hopTimer?.cancel();
    _hopTimer = Timer.periodic(const Duration(milliseconds: 1600), (timer) {
      if (!mounted) return;
      setState(() {
        if (_activeHop < _nodes.length - 1) {
          _activeHop++;
        } else {
          _activeHop = 0;
        }
      });
    });
  }

  void _stopHopSimulation() {
    _pulseController.stop();
    _hopTimer?.cancel();
    setState(() {
      _activeHop = 0;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _hopTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool active = widget.isBroadcasting;
    final bool reachedGateway = active && _activeHop == (_nodes.length - 1);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? const Color(0xFF0284C7).withOpacity(0.6) : const Color(0xFF1E293B),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    active ? Icons.sensors : Icons.sensors_off,
                    size: 15,
                    color: active ? const Color(0xFF38BDF8) : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "BLE Mesh Relay Visualizer",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: active
                      ? (reachedGateway ? const Color(0xFF064E3B) : const Color(0xFF0C4A6E))
                      : const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: active
                        ? (reachedGateway ? const Color(0xFF10B981) : const Color(0xFF38BDF8))
                        : const Color(0xFF334155),
                  ),
                ),
                child: Text(
                  active
                      ? (reachedGateway ? "✓ Gateway Reached" : "v Hop $_activeHop/${_nodes.length - 1}")
                      : "Mesh Standby",
                  style: TextStyle(
                    fontSize: 9.5,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: active
                        ? (reachedGateway ? const Color(0xFF34D399) : const Color(0xFF38BDF8))
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(_nodes.length * 2 - 1, (index) {
                if (index.isOdd) {
                  final int stepIndex = index ~/ 2;
                  final bool isArrowActive = active && _activeHop > stepIndex;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: isArrowActive ? const Color(0xFF38BDF8) : const Color(0xFF334155),
                    ),
                  );
                }

                final int nodeIndex = index ~/ 2;
                final node = _nodes[nodeIndex];
                final bool isNodeActive = active && (_activeHop >= nodeIndex);
                final bool isCurrentHop = active && (_activeHop == nodeIndex);
                final bool isGateway = nodeIndex == _nodes.length - 1;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 82,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  decoration: BoxDecoration(
                    color: isNodeActive
                        ? (isGateway
                            ? const Color(0xFF064E3B).withOpacity(0.4)
                            : const Color(0xFF0369A1).withOpacity(0.25))
                        : const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isNodeActive
                          ? (isGateway ? const Color(0xFF10B981) : const Color(0xFF38BDF8))
                          : const Color(0xFF1E293B),
                      width: isCurrentHop ? 1.6 : 1.0,
                    ),
                    boxShadow: isCurrentHop
                        ? [
                            BoxShadow(
                              color: (isGateway ? const Color(0xFF10B981) : const Color(0xFF38BDF8))
                                  .withOpacity(0.35),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        node["icon"] as IconData,
                        size: 18,
                        color: isNodeActive
                            ? (isGateway ? const Color(0xFF34D399) : const Color(0xFF38BDF8))
                            : const Color(0xFF475569),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        node["title"] as String,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: isNodeActive ? Colors.white : const Color(0xFF64748B),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        node["sub"] as String,
                        style: TextStyle(
                          fontSize: 7.8,
                          color: isNodeActive ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            active
                ? "Propagating SOS beacon peer-to-peer. Packet hops across mobile devices until an active gateway is reached."
                : "Relayed via nearby nodes. If infrastructure is lost, WeatherGPT receivers forward packets without internet.",
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF64748B),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}