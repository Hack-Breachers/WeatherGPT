import 'dart:async';
import 'package:flutter/material.dart';

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
                      ? (reachedGateway ? "âœ“ Gateway Reached" : "v Hop $_activeHop/${_nodes.length - 1}")
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
