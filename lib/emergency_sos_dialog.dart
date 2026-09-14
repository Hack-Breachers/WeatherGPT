import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/ble_mesh_service.dart';
import '../widgets/ble_mesh_visualizer.dart';

class EmergencySosDialog extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String locationCode;

  const EmergencySosDialog({
    super.key,
    this.latitude = 22.7033,
    this.longitude = 88.3512,
    this.locationCode = "7MM8VFXX+82",
  });

  static void show(BuildContext context, {double? lat, double? lng, String? code}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EmergencySosDialog(
        latitude: lat ?? 22.7033,
        longitude: lng ?? 88.3512,
        locationCode: code ?? "7MM8VFXX+82",
      ),
    );
  }

  @override
  State<EmergencySosDialog> createState() => _EmergencySosDialogState();
}

class _EmergencySosDialogState extends State<EmergencySosDialog> {
  final BleMeshService _meshService = BleMeshService();
  StreamSubscription<int>? _hopSubscription;

  bool isTransmitting = false;
  int currentHop = 0;
  final int batteryLevel = 94;

  @override
  void initState() {
    super.initState();
    isTransmitting = _meshService.isTransmitting;
    _hopSubscription = _meshService.hopStream.listen((hop) {
      if (mounted) setState(() => currentHop = hop);
    });
  }

  @override
  void dispose() {
    _hopSubscription?.cancel();
    super.dispose();
  }

  void _toggleMeshBroadcast() {
    setState(() {
      isTransmitting = !isTransmitting;
      if (isTransmitting) {
        _meshService.startSosBroadcast(
          lat: widget.latitude,
          lng: widget.longitude,
          batteryLevel: batteryLevel,
        );
      } else {
        _meshService.stopSosBroadcast();
        currentHop = 0;
      }
    });
  }

  Future<void> _makeCall(String number) async {
    final Uri uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _sendFallbackSms() async {
    final String body =
        "EMERGENCY SOS: Flood distress at OLC ${widget.locationCode} (${widget.latitude.toStringAsFixed(4)}, ${widget.longitude.toStringAsFixed(4)}). Battery: $batteryLevel%. Immediate rescue required.";
    final Uri uri = Uri(scheme: 'sms', path: '112', queryParameters: {'body': body});
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final String hexPayload = SosMeshPacket(
      distressId: "A1B2C3D4",
      latitude: widget.latitude,
      longitude: widget.longitude,
      batteryLevel: batteryLevel,
      hopCount: currentHop,
    ).toHexDisplay();

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Color(0xFF0A0F1D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isTransmitting ? const Color(0xFFEF4444) : Colors.amber,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Emergency SOS Dispatcher",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        "Multi-channel offline mesh broadcaster",
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Activation Bar (Toggle)
                InkWell(
                  onTap: _toggleMeshBroadcast,
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isTransmitting ? const Color(0xFF7F1D1D) : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isTransmitting ? const Color(0xFFEF4444) : const Color(0xFF38BDF8),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isTransmitting ? Icons.sensors : Icons.sensors_off,
                          color: isTransmitting ? Colors.white : const Color(0xFF38BDF8),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isTransmitting ? "BROADCASTING DISTRESS BEACON" : "ACTIVATE OFFLINE BLE MESH",
                                style: TextStyle(
                                  color: isTransmitting ? Colors.white : const Color(0xFF38BDF8),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                ),
                              ),
                              Text(
                                isTransmitting
                                    ? "Broadcasting multi-hop telemetry to nearby phones"
                                    : "Tap to initiate peer-to-peer mesh propagation",
                                style: TextStyle(
                                  color: isTransmitting ? Colors.white70 : Colors.white38,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isTransmitting ? const Color(0xFF991B1B) : const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isTransmitting ? "STOP" : "TRANSMIT",
                            style: TextStyle(
                              color: isTransmitting ? Colors.white : const Color(0xFF38BDF8),
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. The Animated Mesh Visualizer
                BleMeshVisualizer(
                  isActive: isTransmitting,
                  currentHop: currentHop,
                  maxHops: 3,
                ),
                const SizedBox(height: 16),

                // 3. Offline GPS Packet Engine Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Offline GPS Packet Engine",
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoTag("Open Location Code", widget.locationCode),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildInfoTag(
                              "Coordinates",
                              "${widget.latitude.toStringAsFixed(4)}, ${widget.longitude.toStringAsFixed(4)}",
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B0F19),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF1E293B)),
                        ),
                        child: Text(
                          hexPayload,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            color: Color(0xFF38BDF8),
                            fontSize: 10.5,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _sendFallbackSms,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          minimumSize: const Size.fromHeight(36),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.sms, size: 15, color: Colors.white),
                        label: const Text(
                          "Echo Formatted SMS Payload to 112",
                          style: TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Emergency Dialers Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Emergency Telephony Dialers",
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _buildDialCard("112", "National Disaster", () => _makeCall("112"))),
                          const SizedBox(width: 8),
                          Expanded(child: _buildDialCard("101", "Fire & Rescue", () => _makeCall("101"))),
                          const SizedBox(width: 8),
                          Expanded(child: _buildDialCard("1070", "State Relief", () => _makeCall("1070"))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTag(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0F19),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9.5)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildDialCard(String num, String desc, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(
          children: [
            Text(num, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            Text(desc, style: const TextStyle(color: Colors.white38, fontSize: 8), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}