import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class WeatherGPTService {
  // Your PC's Wi-Fi IP address
  static const String baseUrl = "http://192.168.1.4:8000";

  // ===========================================================================
  // 1. GEOLOCATOR: Get Current Device GPS Position
  // ===========================================================================
  static Future<Position> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled on the phone
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled on your phone.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied in phone settings.');
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  // ===========================================================================
  // 2. WEATHER DATA: Fetch Metrics & Risk by Coordinates
  // ===========================================================================
  static Future<Map<String, dynamic>?> fetchCurrentWeather({
    double? latitude,
    double? longitude,
  }) async {
    try {
      double targetLat;
      double targetLon;

      // If coordinates are manually passed (e.g., New York), use them directly.
      // Only invoke GPS if coordinates are null.
      if (latitude != null && longitude != null) {
        targetLat = latitude;
        targetLon = longitude;
      } else {
        final pos = await determinePosition();
        targetLat = pos.latitude;
        targetLon = pos.longitude;
      }

      final url = Uri.parse('$baseUrl/api/v1/weather?lat=$targetLat&lon=$targetLon');
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print("Weather API error status: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error fetching weather: $e");
      return null;
    }
  }

  // ===========================================================================
  // 3. AI CHAT / SEARCH: Works with City Name OR Live GPS
  // ===========================================================================
  static Future<Map<String, dynamic>> askWeatherGPT({
    required String query,
    String? city,
    Position? position,
  }) async {
    // If no city is typed and no position is provided, attempt auto-detecting GPS
    if ((city == null || city.trim().isEmpty) && position == null) {
      try {
        position = await determinePosition();
      } catch (_) {
        // Fallback default coordinates if GPS is rejected
      }
    }

    final payload = <String, dynamic>{
      'query': query,
      if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
      if (position != null) 'latitude': position.latitude,
      if (position != null) 'longitude': position.longitude,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/chat'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 45));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Chat failed (${response.statusCode}): ${response.body}');
    }
  }

  // ===========================================================================
  // 4. SOS & EMERGENCY: Send Coordinates & Launch Dialers
  // ===========================================================================
  static Future<void> sendSOS({
    required String phone,
    String category = "STRANDED",
    int severity = 4,
  }) async {
    final pos = await determinePosition();

    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/sos'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'phone': phone,
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'category': category,
        'severity': severity,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('SOS submission failed: ${response.body}');
    }
  }

  // URL Launcher utility for calling emergency lines
  static Future<void> dialHelpline(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw Exception('Could not launch dialer for $phoneNumber');
    }
  }
}