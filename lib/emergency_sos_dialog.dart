import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:telephony/telephony.dart';

import '../services/mesh_engine.dart';
import 'widgets/ble_mesh_visualizer.dart';

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

  static void show(
    BuildContext context, {
    double? lat,
    double? lng,
    String? code,
  }) {
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
  final MeshEngine _meshEngine = MeshEngine();
  final Telephony _telephony = Telephony.instance;

  // Emergency contact number.
  // Keep the +91 format for an Indian number.
  static const String _emergencyContact = '+919073723106';

  bool isTransmitting = false;
  bool isSendingSms = false;

  int currentHop = 0;

  // Replace this with the actual battery level later.
  final int batteryLevel = 94;

  @override
  void initState() {
    super.initState();

    isTransmitting = _meshEngine.isBroadcasting;
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ------------------------------------------------------------
  // BLE MESH BROADCAST
  // ------------------------------------------------------------

  Future<void> _toggleMeshBroadcast() async {
    if (isTransmitting) {
      if (mounted) {
        setState(() {
          isTransmitting = false;
          currentHop = 0;
        });
      }

      await _meshEngine.stopMesh();
      return;
    }

    if (mounted) {
      setState(() {
        isTransmitting = true;
        currentHop = 0;
      });
    }

    try {
      await _meshEngine.startMesh(
        userName: "Citizen_SOS",
        onPacketReceived: (packet) {
          if (!mounted) return;

          setState(() {
            currentHop = packet.hops;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Relayed SOS from ${packet.phone} "
                "(Hop ${packet.hops})",
              ),
              backgroundColor: const Color(0xFF0284C7),
            ),
          );
        },
      );

      await _meshEngine.sendSosDistressBeacon(
        phone: "SOS_USER",
        lat: widget.latitude,
        lon: widget.longitude,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isTransmitting = false;
        currentHop = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Mesh SOS failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ------------------------------------------------------------
  // PHONE CALL
  // ------------------------------------------------------------

  Future<void> _makeCall(String number) async {
    final Uri uri = Uri(
      scheme: 'tel',
      path: number,
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Unable to open dialer for $number"),
        ),
      );
    }
  }

  // ------------------------------------------------------------
  // AUTOMATIC SMS SENDING
  // ------------------------------------------------------------

  Future<void> _sendFallbackSms() async {
    // Prevent duplicate taps while an SMS is being sent.
    if (isSendingSms) return;

    setState(() {
      isSendingSms = true;
    });

    try {
      // Request Android SMS permission.
      final bool? permissionsGranted =
          await _telephony.requestSmsPermissions;

      if (permissionsGranted != true) {
        throw Exception('SMS permission was not granted');
      }

      // Build the emergency SMS.
      //
      // IMPORTANT:
      // Use widget.latitude and widget.longitude because these
      // values belong to the EmergencySosDialog widget.
      final String body = '''
EMERGENCY SOS ALERT

Flood distress reported.

Location:
Latitude: ${widget.latitude.toStringAsFixed(6)}
Longitude: ${widget.longitude.toStringAsFixed(6)}

Map:
https://maps.google.com/?q=${widget.latitude},${widget.longitude}

Location code: ${widget.locationCode}
Battery: $batteryLevel%

Please contact the user immediately.
''';

      // This sends the SMS directly through Android's SMS service.
      // It does NOT open the SMS application.
      await _telephony.sendSms(
        to: _emergencyContact,
        message: body,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Emergency SMS sent successfully'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send SMS: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSendingSms = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // MAIN UI
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final MeshPacket packet = MeshPacket(
      packetId: "A1B2C3D4",
      phone: "SOS_USER",
      latitude: widget.latitude,
      longitude: widget.longitude,
      hops: currentHop,
    );

    final String hexPayload = packet
        .toBytes()
        .map(
          (byte) => byte
              .toRadixString(16)
              .padLeft(2, "0")
              .toUpperCase(),
        )
        .join(" ");

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Color(0xFF0A0F1D),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // ------------------------------------------------------
          // HEADER BAR
          // ------------------------------------------------------

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isTransmitting
                        ? const Color(0xFFEF4444)
                        : Colors.amber,
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
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        "Multi-channel offline mesh broadcaster",
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white70,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // ------------------------------------------------------
          // BODY
          // ------------------------------------------------------

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // --------------------------------------------------
                // 1. ACTIVATION BAR / MESH TOGGLE
                // --------------------------------------------------

                InkWell(
                  onTap: _toggleMeshBroadcast,
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isTransmitting
                          ? const Color(0xFF7F1D1D)
                          : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isTransmitting
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF38BDF8),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isTransmitting
                              ? Icons.sensors
                              : Icons.sensors_off,
                          color: isTransmitting
                              ? Colors.white
                              : const Color(0xFF38BDF8),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                isTransmitting
                                    ? "BROADCASTING DISTRESS BEACON"
                                    : "ACTIVATE OFFLINE BLE MESH",
                                style: TextStyle(
                                  color: isTransmitting
                                      ? Colors.white
                                      : const Color(0xFF38BDF8),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                ),
                              ),
                              Text(
                                isTransmitting
                                    ? "Broadcasting multi-hop telemetry to nearby phones"
                                    : "Tap to initiate peer-to-peer mesh propagation",
                                style: TextStyle(
                                  color: isTransmitting
                                      ? Colors.white70
                                      : Colors.white38,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isTransmitting
                                ? const Color(0xFF991B1B)
                                : const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isTransmitting ? "STOP" : "TRANSMIT",
                            style: TextStyle(
                              color: isTransmitting
                                  ? Colors.white
                                  : const Color(0xFF38BDF8),
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

                // --------------------------------------------------
                // 2. ANIMATED MESH VISUALIZER
                // --------------------------------------------------

                BleMeshVisualizer(
                  isBroadcasting: isTransmitting,
                ),

                const SizedBox(height: 16),

                // --------------------------------------------------
                // 3. OFFLINE GPS PACKET ENGINE CARD
                // --------------------------------------------------

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF334155),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Offline GPS Packet Engine",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoTag(
                              "Open Location Code",
                              widget.locationCode,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildInfoTag(
                              "Coordinates",
                              "${widget.latitude.toStringAsFixed(4)}, "
                              "${widget.longitude.toStringAsFixed(4)}",
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
                          border: Border.all(
                            color: const Color(0xFF1E293B),
                          ),
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

                      // ------------------------------------------------
                      // AUTOMATIC SMS BUTTON
                      // ------------------------------------------------

                      ElevatedButton.icon(
                        onPressed:
                            isSendingSms ? null : _sendFallbackSms,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          disabledBackgroundColor: Colors.grey,
                          minimumSize: const Size.fromHeight(36),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: isSendingSms
                            ? const SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.sms,
                                size: 15,
                                color: Colors.white,
                              ),
                        label: Text(
                          isSendingSms
                              ? "Sending SOS SMS..."
                              : "Send SOS SMS to Member",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // --------------------------------------------------
                // 4. EMERGENCY DIALERS CARD
                // --------------------------------------------------

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF334155),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Emergency Telephony Dialers",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: _buildDialCard(
                              "112",
                              "National Disaster",
                              () => _makeCall("112"),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildDialCard(
                              "101",
                              "Fire & Rescue",
                              () => _makeCall("101"),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildDialCard(
                              "1070",
                              "State Relief",
                              () => _makeCall("1070"),
                            ),
                          ),
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

  // ------------------------------------------------------------
  // INFO TAG WIDGET
  // ------------------------------------------------------------

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
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 9.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // EMERGENCY DIAL CARD WIDGET
  // ------------------------------------------------------------

  Widget _buildDialCard(
    String num,
    String desc,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 6,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF334155),
          ),
        ),
        child: Column(
          children: [
            Text(
              num,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            Text(
              desc,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 8,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}