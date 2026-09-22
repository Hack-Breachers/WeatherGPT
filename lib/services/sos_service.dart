import 'package:geolocator/geolocator.dart';
import 'package:telephony/telephony.dart';

class SosService {
  static const String emergencyContact = '9073723106';

  final Telephony telephony = Telephony.instance;

  Future<String> sendSosSms() async {
    try {
      // 1. Check whether location services are enabled.
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        return 'Please enable location services.';
      }

      // 2. Check location permission.
      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          return 'Location permission was denied.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return 'Location permission is permanently denied. Enable it from Settings.';
      }

      // 3. Obtain the current location.
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final double latitude = position.latitude;
      final double longitude = position.longitude;

      // 4. Construct the SMS.
      final String message = '''
SOS ALERT!

I may need immediate assistance.

Latitude: $latitude
Longitude: $longitude

Google Maps Location:
https://maps.google.com/?q=$latitude,$longitude
''';

      // 5. Check SMS permission.
      bool? permissionsGranted =
          await telephony.requestSmsPermissions;

      if (permissionsGranted != true) {
        return 'SMS permission was denied.';
      }

      // 6. Send the SMS.
      await telephony.sendSms(
        to: emergencyContact,
        message: message,
      );

      return 'SOS SMS sent successfully.';
    } catch (e) {
      return 'Failed to send SOS SMS: $e';
    }
  }
}