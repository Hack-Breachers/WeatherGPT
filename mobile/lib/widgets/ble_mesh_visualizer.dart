import 'dart:math';
import 'package:flutter/material.dart';

class BleMeshVisualizer extends StatefulWidget {
  final bool isActive;
  final int currentHop;
  final int maxHops;

  const BleMeshVisualizer({
    super.key,
    required this.isActive,
    this.currentHop = 0,
    this.maxHops = 3,
  });

  @override
  State<BleMeshVisualizer> createState() => _BleMeshVisualizerState();
}

class _BleMeshVisualizerState extends State<BleMeshVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isActive ? const Color(0xFFEF4444).withOpacity(0.6) : const Color(0xFF334155),
          width: widget.isActive ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "BLE MESH RELAY VISUALIZER",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: widget.isActive ? const Color(0xFF7F1D1D) : const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.isActive ? "HOP ${widget.currentHop}/${widget.maxHops} RELAYING" : "STANDBY (OFFLINE)",
                  style: TextStyle(
                    color: widget.isActive ? const Color(0xFFFCA5A5) : Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Mesh Topology Node Bar
          AnimatedBuilder(
            animation: _animCtrl,
            builder: (context, child) {
              return CustomPaint(
                painter: _MeshPacketPathPainter(
                  isActive: widget.isActive,
                  currentHop: widget.currentHop,
                  progress: _animCtrl.value,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNodeItem(
                        icon: Icons.cell_tower,
                        label: "This Phone",
                        sub: "Origin (Hop 0)",
                        nodeIndex: 0,
                        isOrigin: true,
                      ),
                      _buildNodeItem(
                        icon: Icons.phone_android,
                        label: "Peer Relay 1",
                        sub: "Nearby Peer",
                        nodeIndex: 1,
                      ),
                      _buildNodeItem(
                        icon: Icons.directions_boat,
                        label: "Peer Relay 2",
                        sub: "Vehicle/Boat",
                        nodeIndex: 2,
                      ),
                      _buildNodeItem(
                        icon: Icons.shield,
                        label: "Control HQ",
                        sub: "NDRF Hub",
                        nodeIndex: 3,
                        isTarget: true,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            widget.isActive
                ? "Propagating 24-byte telemetry beacons via background BLE advertising."
                : "Zero cellular dependency. Handsets forward encrypted distress packets peer-to-peer.",
            style: TextStyle(
              color: widget.isActive ? const Color(0xFFEF4444).withOpacity(0.9) : Colors.white54,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeItem({
    required IconData icon,
    required String label,
    required String sub,
    required int nodeIndex,
    bool isOrigin = false,
    bool isTarget = false,
  }) {
    final bool reached = widget.isActive && (widget.currentHop >= nodeIndex);
    final bool isPulsingNode = widget.isActive && isOrigin;

    return Stack(
      alignment: Alignment.center,
      children: [
        if (isPulsingNode)
          Container(
            width: 58 + (_animCtrl.value * 14),
            height: 58 + (_animCtrl.value * 14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.redAccent.withOpacity(0.28 * (1.0 - _animCtrl.value)),
            ),
          ),
        Container(
          width: 72,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            color: reached
                ? (isTarget ? const Color(0xFF065F46) : const Color(0xFF7F1D1D).withOpacity(0.6))
                : const Color(0xFF1E293B).withOpacity(0.7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: reached
                  ? (isTarget ? const Color(0xFF34D399) : const Color(0xFFEF4444))
                  : const Color(0xFF334155),
              width: reached ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: reached
                    ? (isTarget ? const Color(0xFF34D399) : Colors.white)
                    : Colors.white38,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: reached ? Colors.white : Colors.white60,
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
              Text(
                sub,
                style: TextStyle(
                  color: reached ? (isTarget ? const Color(0xFFA7F3D0) : const Color(0xFFFCA5A5)) : Colors.white24,
                  fontSize: 7.5,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MeshPacketPathPainter extends CustomPainter {
  final bool isActive;
  final int currentHop;
  final double progress;

  _MeshPacketPathPainter({
    required this.isActive,
    required this.currentHop,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isActive) return;

    final baseLinePaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final activeLinePaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final centerY = size.height / 2;
    canvas.drawLine(Offset(36, centerY), Offset(size.width - 36, centerY), baseLinePaint);

    final double hopDistance = (size.width - 72) / 3;
    final double reachedX = 36 + (currentHop * hopDistance);
    canvas.drawLine(Offset(36, centerY), Offset(reachedX, centerY), activeLinePaint);

    // Traveling packet beacon
    if (currentHop < 3) {
      final double segStartX = 36 + (currentHop * hopDistance);
      final double packetX = segStartX + (hopDistance * progress);

      final packetPaint = Paint()
        ..color = const Color(0xFFFDE047)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(packetX, centerY), 4.5, packetPaint);

      final glowPaint = Paint()
        ..color = const Color(0xFFFDE047).withOpacity(0.4)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(packetX, centerY), 8.0, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MeshPacketPathPainter old) =>
      old.progress != progress || old.currentHop != currentHop || old.isActive != isActive;
}