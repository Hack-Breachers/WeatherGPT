import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class WeatherCacheService {
  static const String _weatherKey = 'latest_weather_cache';
  static const String _timestampKey = 'latest_weather_cache_timestamp';
  static const String _latitudeKey = 'latest_weather_cache_latitude';
  static const String _longitudeKey = 'latest_weather_cache_longitude';
  static const String _locationKey = 'latest_weather_cache_location';

  /// Saves the latest successful live weather response.
  static Future<void> saveWeather({
    required Map<String, dynamic> weatherData,
    required double latitude,
    required double longitude,
    required String locationName,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _weatherKey,
      jsonEncode(weatherData),
    );

    await prefs.setString(
      _timestampKey,
      DateTime.now().toIso8601String(),
    );

    await prefs.setDouble(
      _latitudeKey,
      latitude,
    );

    await prefs.setDouble(
      _longitudeKey,
      longitude,
    );

    await prefs.setString(
      _locationKey,
      locationName,
    );
  }

  /// Returns the latest cached weather data, or null if no cache exists.
  static Future<Map<String, dynamic>?> loadWeather() async {
    final prefs = await SharedPreferences.getInstance();

    final cachedJson = prefs.getString(_weatherKey);

    if (cachedJson == null || cachedJson.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(cachedJson);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  /// Returns when the cached weather was saved.
  static Future<DateTime?> getLastUpdated() async {
    final prefs = await SharedPreferences.getInstance();

    final timestamp = prefs.getString(_timestampKey);

    if (timestamp == null) {
      return null;
    }

    return DateTime.tryParse(timestamp);
  }

  /// Returns the coordinates associated with the cached weather.
  static Future<Map<String, double>?> getCachedLocation() async {
    final prefs = await SharedPreferences.getInstance();

    final latitude = prefs.getDouble(_latitudeKey);
    final longitude = prefs.getDouble(_longitudeKey);

    if (latitude == null || longitude == null) {
      return null;
    }

    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  /// Returns the location name associated with the cached weather.
  static Future<String?> getCachedLocationName() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_locationKey);
  }

  /// Clears all cached weather information.
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_weatherKey);
    await prefs.remove(_timestampKey);
    await prefs.remove(_latitudeKey);
    await prefs.remove(_longitudeKey);
    await prefs.remove(_locationKey);
  }
}