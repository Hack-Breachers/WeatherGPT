import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';


enum _EmergencyDeliveryStatus {
  ready,
  sendingDirect,
  searchingRelay,
  relaying,
  queued,
  delivered,
}

class EmergencySosDialog extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String locationCode;

  const EmergencySosDialog({
    super.key,
    this.latitude = 22.7033,
    this.longitude = 88.3512,
    this.locationCode = '7MM8VFXX+82',
  });

  static void show(
    BuildContext context, {
    double? lat,
    double? lng,
    String? code,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EmergencySosDialog(
        latitude: lat ?? 22.7033,
        longitude: lng ?? 88.3512,
        locationCode: code ?? '7MM8VFXX+82',
      ),
    );
  }

  @override
  State<EmergencySosDialog> createState() => _EmergencySosDialogState();
}

class _EmergencySosDialogState extends State<EmergencySosDialog> {
  final TextEditingController _messageController = TextEditingController();
  static const String _baseUrl = 'http://192.168.1.4:8000';
  static const MethodChannel _nativeChannel =
    MethodChannel('weathergpt/mesh_relay');

  _EmergencyDeliveryStatus _status = _EmergencyDeliveryStatus.ready;
  String _selectedCategory = 'Trapped';
  bool _relayEnabled = false;
  String? _sosPacketId;

  static const Color _background = Color(0xFF0A0F1D);
  static const Color _cardBackground = Color(0xFF111827);
  static const Color _border = Color(0xFF263244);
  static const Color _accent = Color(0xFF38BDF8);
  static const Color _danger = Color(0xFFEF4444);
  static const Color _success = Color(0xFF22C55E);

  final List<String> _categories = const [
    'Trapped',
    'Medical',
    'Flood',
    'Fire',
    'Rescue',
    'Other',
  ];

  @override
void initState() {
  super.initState();
  _loadRelayStatus();
}

Future<void> _loadRelayStatus() async {
  try {
    final bool? enabled =
        await _nativeChannel.invokeMethod<bool>('getRelayStatus');

    if (!mounted) return;

    setState(() {
      _relayEnabled = enabled ?? false;
    });

    debugPrint('RESCUE RELAY: native status = $_relayEnabled');
  } on PlatformException catch (e) {
    debugPrint(
      'RESCUE RELAY STATUS FAILED: ${e.code} ${e.message}',
    );
  } catch (e) {
    debugPrint('RESCUE RELAY STATUS FAILED: $e');
  }
}

@override
void dispose() {
  _messageController.dispose();
  super.dispose();
}

  String get _statusTitle {
    switch (_status) {
      case _EmergencyDeliveryStatus.ready:
        return 'Ready to send';
      case _EmergencyDeliveryStatus.sendingDirect:
        return 'Trying direct delivery';
      case _EmergencyDeliveryStatus.searchingRelay:
        return 'Searching for a Rescue Relay';
      case _EmergencyDeliveryStatus.relaying:
        return 'Sending through the Rescue Relay network';
      case _EmergencyDeliveryStatus.queued:
        return 'SOS safely queued';
      case _EmergencyDeliveryStatus.delivered:
        return 'SOS delivered';
    }
  }

  String get _statusDescription {
    switch (_status) {
      case _EmergencyDeliveryStatus.ready:
        return 'Your SOS will try normal connectivity first, then a nearby Rescue Relay if needed.';
      case _EmergencyDeliveryStatus.sendingDirect:
        return 'Trying the normal network first. If it fails, the SOS is handed to the Rescue Relay network.';
      case _EmergencyDeliveryStatus.searchingRelay:
        return 'Looking for an opted-in Rescue Relay nearby.';
      case _EmergencyDeliveryStatus.relaying:
        return 'A Rescue Relay is forwarding the emergency packet toward a connected gateway.';
      case _EmergencyDeliveryStatus.queued:
        return 'No delivery path is available right now. The packet will retry automatically when a path returns.';
      case _EmergencyDeliveryStatus.delivered:
        return 'The server has acknowledged this SOS packet.';
    }
  }

  Color get _statusColor {
    switch (_status) {
      case _EmergencyDeliveryStatus.ready:
        return _accent;
      case _EmergencyDeliveryStatus.sendingDirect:
      case _EmergencyDeliveryStatus.searchingRelay:
      case _EmergencyDeliveryStatus.relaying:
        return Colors.amber;
      case _EmergencyDeliveryStatus.queued:
        return Colors.orange;
      case _EmergencyDeliveryStatus.delivered:
        return _success;
    }
  }

  Future<void> _sendDirectSosSms() async {
  try {
    debugPrint(
      'DIRECT SMS: requesting native SOS SMS for $_sosPacketId',
    );

    await _nativeChannel.invokeMethod(
      'sendDirectSosSms',
      {
        'packetId': _sosPacketId,
        'phone': 'SOS_USER',
        'latitude': widget.latitude,
        'longitude': widget.longitude,
        'locationCode': widget.locationCode,
        'category': _selectedCategory,
        'message': _messageController.text.trim(),
        'severity': 4,
      },
    );

    debugPrint(
      'DIRECT SMS: native SOS SMS requested successfully',
    );
  } catch (e) {
    debugPrint(
      'DIRECT SMS FAILED: $e',
    );
  }
}

  Future<void> _beginSOSFlow() async {
  debugPrint('SOS BUTTON: _beginSOSFlow() CALLED');

  if (_status != _EmergencyDeliveryStatus.ready) {
    debugPrint('SOS BUTTON: blocked because status = $_status');
    return;
  }
  debugPrint('SOS BUTTON: status is READY');

  _sosPacketId ??=
    'SOS-${DateTime.now().microsecondsSinceEpoch}';

  debugPrint('SOS BUTTON: packet ID = $_sosPacketId');

  setState(() {
    _status = _EmergencyDeliveryStatus.sendingDirect;
  });

  try {
    debugPrint('SOS HTTP: sending request to $_baseUrl/api/v1/sos');
    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/v1/sos'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'packet_id': _sosPacketId,
            'phone': 'SOS_USER',
            'latitude': widget.latitude,
            'longitude': widget.longitude,
            'category': _selectedCategory,
            'severity': 4,
            'location_code': widget.locationCode,
            'message': _messageController.text.trim(),
        }),
        )
        .timeout(const Duration(seconds: 4));

        debugPrint(
  'SOS HTTP: response ${response.statusCode} ${response.body}',
);

    if (response.statusCode == 200) {
  final data = jsonDecode(response.body);

  if (data['status'] != 'SUCCESS') {
    throw Exception(
      'Backend did not confirm SOS delivery: ${data['status']}',
    );
  }

  debugPrint(
    'SOS SUCCESS: Direct delivery confirmed by backend',
  );

  // Backend has accepted the SOS.
  // Now trigger the native Android emergency SMS.
  await _sendDirectSosSms();

  if (!mounted) return;

  setState(() {
    _status = _EmergencyDeliveryStatus.delivered;
  });

  return;
}

    throw Exception(
      'SOS request failed with status ${response.statusCode}',
    );
  } catch (e) {
  debugPrint('DIRECT SOS FAILED: $e');

  if (!mounted) return;

  await Future<void>.delayed(
    const Duration(seconds: 2),
  );

  await _tryRescueRelay();
}
}

  Future<void> _toggleRelay(bool value) async {
    try {
      await _nativeChannel.invokeMethod(
        value ? 'startRelay' : 'stopRelay',
      );

      if (!mounted) return;

      setState(() {
        _relayEnabled = value;
      });
    } on PlatformException catch (e) {
      debugPrint(
        'RESCUE RELAY TOGGLE FAILED: ${e.code} ${e.message}',
      );
    }
  }

  Future<void> _tryRescueRelay() async {
    if (!mounted) return;

    setState(() {
      _status = _EmergencyDeliveryStatus.searchingRelay;
    });

    try {
      final result = await _nativeChannel.invokeMethod<bool>(
        'sendRelaySos',
        {
          'packetId': _sosPacketId,
          'phone': 'SOS_USER',
          'latitude': widget.latitude,
          'longitude': widget.longitude,
          'locationCode': widget.locationCode,
          'category': _selectedCategory,
          'message': _messageController.text.trim(),
          'severity': 4,
        },
      );

      debugPrint('SOS RELAY: native bridge result = $result');

      if (!mounted) return;
      setState(() {
        _status = _EmergencyDeliveryStatus.relaying;
      });

      await _pollRelayDeliveryStatus();
    } on PlatformException catch (e) {
      debugPrint('SOS RELAY BRIDGE FAILED: ${e.code}: ${e.message}');
      if (!mounted) return;
      setState(() {
        _status = _EmergencyDeliveryStatus.queued;
      });
    } catch (e) {
      debugPrint('SOS RELAY FAILED: $e');
      if (!mounted) return;
      setState(() {
        _status = _EmergencyDeliveryStatus.queued;
      });
    }
  }

  Future<void> _pollRelayDeliveryStatus() async {
    const int attempts = 12;

    for (int attempt = 0; attempt < attempts; attempt++) {
      if (!mounted) return;

      try {
        final response = await http
            .get(
              Uri.parse('$_baseUrl/api/v1/sos/$_sosPacketId'),
            )
            .timeout(const Duration(seconds: 3));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final status = data['status']?.toString();

          if (status == 'DELIVERED' || status == 'SUCCESS') {
            if (!mounted) return;
            setState(() {
              _status = _EmergencyDeliveryStatus.delivered;
            });
            return;
          }
        }
      } catch (e) {
        debugPrint('SOS RELAY STATUS CHECK ${attempt + 1}: $e');
      }

      await Future<void>.delayed(const Duration(seconds: 2));
    }

    if (!mounted) return;
    setState(() {
      _status = _EmergencyDeliveryStatus.queued;
    });
  }

  Future<void> _makeCall(String number) async {
  try {
    final bool? result =
        await FlutterPhoneDirectCaller.callNumber(number);

    debugPrint(
      'DIRECT CALL: $number -> $result',
    );
  } catch (e) {
    debugPrint(
      'DIRECT CALL FAILED: $number -> $e',
    );
  }
}

    @override
  Widget build(BuildContext context) {
    return Container(
    height: MediaQuery.of(context).size.height * 0.92,
          decoration: const BoxDecoration(
            color: _background,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      24,
                    ),
                    children: [
                      _buildEmergencyBanner(),
                      const SizedBox(height: 14),
                      _buildLocationCard(),
                      const SizedBox(height: 14),
                      _buildSosCard(),
                      const SizedBox(height: 14),
                      _buildRelayCard(),
                      const SizedBox(height: 14),
                      _buildDeliveryCard(),
                      const SizedBox(height: 14),
                      _buildEmergencyNumbersCard(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emergency SOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Emergency communication fallback',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF3F1118),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF7F1D1D)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_rounded, color: _danger, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Use SOS only for an emergency',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'WeatherGPT will try direct delivery first. If connectivity is unavailable, it can use an opted-in Rescue Relay or safely queue the packet.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return _card(
      title: 'Your location',
      icon: Icons.location_on_outlined,
      child: Row(
        children: [
          Expanded(child: _locationValue('LATITUDE', widget.latitude.toStringAsFixed(6))),
          const SizedBox(width: 10),
          Expanded(child: _locationValue('LONGITUDE', widget.longitude.toStringAsFixed(6))),
          const SizedBox(width: 10),
          Expanded(child: _locationValue('LOCATION CODE', widget.locationCode)),
        ],
      ),
    );
  }

  Widget _locationValue(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSosCard() {
    return _card(
      title: 'Send emergency SOS',
      icon: Icons.sos_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose what is happening and add an optional message. The packet will contain your location, emergency category, timestamp and delivery metadata.',
            style: TextStyle(color: Colors.white60, fontSize: 11, height: 1.45),
          ),
          const SizedBox(height: 14),
          const Text('Emergency category', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 9),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: _categories.map((category) {
              final selected = _selectedCategory == category;
              return ChoiceChip(
                label: Text(category),
                selected: selected,
                onSelected: (_) => setState(() => _selectedCategory = category),
                selectedColor: _accent.withValues(alpha: 0.22),
                backgroundColor: const Color(0xFF0B1220),
                side: BorderSide(color: selected ? _accent : _border),
                labelStyle: TextStyle(color: selected ? Colors.white : Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _messageController,
            maxLength: 300,
            maxLines: 3,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Optional: tell responders what you need...',
              hintStyle: const TextStyle(color: Colors.white30, fontSize: 11),
              filled: true,
              fillColor: const Color(0xFF0B1220),
              counterStyle: const TextStyle(color: Colors.white30, fontSize: 9),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _accent)),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _status == _EmergencyDeliveryStatus.ready ? _beginSOSFlow : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _danger,
                disabledBackgroundColor: const Color(0xFF5B1B22),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.sos_rounded, size: 24),
              label: const Text('SEND SOS', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.7)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelayCard() {
    return _card(
      title: 'Rescue Relay',
      icon: Icons.cell_tower_rounded,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _relayEnabled ? const Color(0xFF0C2A26) : const Color(0xFF0B1220),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _relayEnabled ? _success : _border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _relayEnabled ? _success.withValues(alpha: 0.15) : _accent.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cell_tower_rounded, color: _relayEnabled ? _success : _accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_relayEnabled ? 'Rescue Relay is active' : 'Rescue Relay is off', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    _relayEnabled
                        ? 'This device can help forward emergency packets for nearby users.'
                        : 'Off by default. Turn it on when you are willing to help forward emergency packets.',
                    style: const TextStyle(color: Colors.white54, fontSize: 10, height: 1.35),
                  ),
                  if (_relayEnabled) ...[
                    const SizedBox(height: 5),
                    const Text('This device is participating in the Rescue Relay network.', style: TextStyle(color: Colors.white38, fontSize: 9)),
                  ],
                ],
              ),
            ),
            Switch.adaptive(value: _relayEnabled, onChanged: _toggleRelay, activeTrackColor: _success),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryCard() {
  final bool directActive =
      _status == _EmergencyDeliveryStatus.sendingDirect ||
      _status == _EmergencyDeliveryStatus.delivered;

  final bool relayActive =
      _status == _EmergencyDeliveryStatus.searchingRelay ||
      _status == _EmergencyDeliveryStatus.relaying;

  final bool queueActive =
      _status == _EmergencyDeliveryStatus.queued;

  return _card(
    title: 'Delivery status',
    icon: Icons.route_rounded,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _statusIcon,
              color: _statusColor,
              size: 23,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _statusTitle,
                    style: TextStyle(
                      color: _statusColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _statusDescription,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            _flowStep(
              'Direct',
              directActive,
              Icons.wifi_rounded,
            ),

            _flowConnector(),

            _flowStep(
              'Relay',
              relayActive,
              Icons.cell_tower_rounded,
            ),

            _flowConnector(),

            _flowStep(
              'Queue',
              queueActive,
              Icons.inventory_2_outlined,
            ),
          ],
        ),
      ],
    ),
  );
}
  IconData get _statusIcon {
    switch (_status) {
      case _EmergencyDeliveryStatus.ready:
        return Icons.check_circle_outline_rounded;
      case _EmergencyDeliveryStatus.sendingDirect:
        return Icons.wifi_find_rounded;
      case _EmergencyDeliveryStatus.searchingRelay:
        return Icons.cell_tower_rounded;
      case _EmergencyDeliveryStatus.relaying:
        return Icons.route_rounded;
      case _EmergencyDeliveryStatus.queued:
        return Icons.inventory_2_outlined;
      case _EmergencyDeliveryStatus.delivered:
        return Icons.verified_rounded;
    }
  }

  Widget _flowStep(String label, bool active, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: active ? _statusColor.withValues(alpha: 0.16) : const Color(0xFF0B1220),
              shape: BoxShape.circle,
              border: Border.all(color: active ? _statusColor : _border),
            ),
            child: Icon(icon, size: 16, color: active ? _statusColor : Colors.white30),
          ),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(color: active ? Colors.white : Colors.white38, fontSize: 9, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _flowConnector() => Container(width: 22, height: 1, margin: const EdgeInsets.only(bottom: 18), color: _border);

  Widget _buildEmergencyNumbersCard() {
    return _card(
      title: 'Emergency numbers',
      icon: Icons.phone_in_talk_outlined,
      child: Row(
        children: [
          Expanded(child: _buildDialCard('112', 'National', () => _makeCall('112'))),
          const SizedBox(width: 8),
          Expanded(child: _buildDialCard('101', 'Fire', () => _makeCall('101'))),
          const SizedBox(width: 8),
          Expanded(child: _buildDialCard('1070', 'Disaster Relief', () => _makeCall('1070'))),
        ],
      ),
    );
  }

  Widget _buildDialCard(String number, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
        decoration: BoxDecoration(color: const Color(0xFF0B1220), borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
        child: Column(
          children: [
            Text(number, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white38, fontSize: 8)),
          ],
        ),
      ),
    );
  }

  Widget _card({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _cardBackground, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _accent, size: 18),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
