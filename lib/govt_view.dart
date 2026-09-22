import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GovtCommandScreen extends StatefulWidget {
  final VoidCallback onToggleToCitizen;
  const GovtCommandScreen({super.key, required this.onToggleToCitizen});

  @override
  State<GovtCommandScreen> createState() => _GovtCommandScreenState();
}

class _GovtCommandScreenState extends State<GovtCommandScreen> {
  static const String baseUrl = "https://occupant-cesarean-false.ngrok-free.dev";
  static const Map<String, String> requestHeaders = {
    'Content-Type': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  };

  Timer? _pollTimer;
  int _latency = 140;
  int _baseRescued = 2166;
  String? _broadcastAlert;

  final TextEditingController _taskTitleController = TextEditingController(
    text: "Need 10 volunteers to distribute food packets",
  );
  final TextEditingController _taskDetailsController = TextEditingController(
    text: "Contact: Dr. Sen (Ward 62). Assembly point at Salt Lake Karunamoyee Bus Terminus at 19:30. Bring waterproof boots.",
  );
  final TextEditingController _taskLocController = TextEditingController(
    text: "Sector V Relief Camp",
  );

  String _selectedPriority = "High";

  List<Map<String, dynamic>> _allIncidents = [
    {
      "id": "SOS-4401",
      "citizen": "R. Mondal (family of 4)",
      "contact": "+91 98301 23456",
      "coords": "22.5812, 88.4211",
      "category": "Stranded • roof evacuation",
      "catType": "danger",
      "time": "21:14",
      "status": "Open",
      "statusType": "open",
    },
    {
      "id": "SOS-4402",
      "citizen": "Anonymous (offline packet)",
      "contact": "Mesh Hop: Peer-02",
      "coords": "22.5921, 88.4110",
      "category": "Medical • insulin required",
      "catType": "danger",
      "time": "21:20",
      "status": "In Progress",
      "statusType": "progress",
    },
    {
      "id": "SOS-4403",
      "citizen": "S. Sen",
      "contact": "+91 98312 98765",
      "coords": "22.5744, 88.3980",
      "category": "Structural • wall collapse risk",
      "catType": "warning",
      "time": "21:22",
      "status": "Open",
      "statusType": "open",
    },
    {
      "id": "SOS-4404",
      "citizen": "Ward 62 Shelter Warden",
      "contact": "Shelter Comm Unit",
      "coords": "22.5612, 88.3712",
      "category": "Supplies • drinking water out",
      "catType": "warning",
      "time": "21:18",
      "status": "In Progress",
      "statusType": "progress",
    },
    {
      "id": "SOS-4405",
      "citizen": "P. Das",
      "contact": "+91 98365 44321",
      "coords": "22.5510, 88.3920",
      "category": "Elderly trapped in residence",
      "catType": "info",
      "time": "20:54",
      "status": "Resolved",
      "statusType": "resolved",
    },
  ];

  @override
  void initState() {
    super.initState();
    _pollIncidents();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _pollIncidents());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _taskTitleController.dispose();
    _taskDetailsController.dispose();
    _taskLocController.dispose();
    super.dispose();
  }

  Future<void> _pollIncidents() async {
    final stopwatch = Stopwatch()..start();
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/v1/incidents'), headers: requestHeaders)
          .timeout(const Duration(seconds: 2));
      stopwatch.stop();
      if (mounted) setState(() => _latency = stopwatch.elapsedMilliseconds);

      if (res.statusCode == 200) {
        final List<dynamic> liveData = jsonDecode(res.body);
        if (liveData.isNotEmpty) {
          setState(() {
            for (var item in liveData) {
              final exists = _allIncidents.any((x) => x['id'] == item['id']);
              if (!exists) {
                _allIncidents.insert(0, {
                  "id": item['id'] ?? 'SOS-AUTO',
                  "citizen": item['location_name'] ?? item['phone'] ?? 'Citizen SOS Beacon',
                  "contact": item['phone'] ?? 'Mobile Gateway',
                  "coords":
                      "${item['latitude'] != null ? (item['latitude'] as num).toStringAsFixed(4) : '22.5726'}, ${item['longitude'] != null ? (item['longitude'] as num).toStringAsFixed(4) : '88.3639'}",
                  "category": item['category'] ?? 'Stranded • Urban Flood',
                  "catType": (item['severity'] ?? 3) >= 5
                      ? 'danger'
                      : ((item['severity'] ?? 3) >= 4 ? 'warning' : 'info'),
                  "time": "Just now",
                  "status": item['status'] ?? 'Open',
                  "statusType": item['status'] == 'DISPATCHED' ? 'progress' : 'open',
                });
              }
            }
          });
        }
      }
    } catch (_) {}
  }

  void _dispatchTeam(String id, String team) {
    setState(() {
      final item = _allIncidents.firstWhere((x) => x['id'] == id);
      item['status'] = "Assigned: $team";
      item['statusType'] = "progress";
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0284C7),
        content: Text("[DISPATCH SENT] $team assigned to Incident $id. Coordinates locked."),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleResolve(String id) {
    setState(() {
      final item = _allIncidents.firstWhere((x) => x['id'] == id);
      if (item['status'] == 'Resolved') {
        item['status'] = 'In Progress';
        item['statusType'] = 'progress';
        _baseRescued -= 1;
      } else {
        item['status'] = 'Resolved';
        item['statusType'] = 'resolved';
        _baseRescued += 1;
      }
    });
  }

  void _handleBroadcast() {
    if (_taskTitleController.text.trim().isEmpty) return;
    setState(() {
      _broadcastAlert = 'Mission "${_taskTitleController.text}" broadcasted to 31 volunteers via Mesh push.';
    });
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _broadcastAlert = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeSosCount = _allIncidents.where((x) => x['status'] != 'Resolved').length;

    return Scaffold(
      backgroundColor: const Color(0xFF070C18),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1440),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildKpiGrid(activeSosCount),
                          const SizedBox(height: 16),
                          _buildMapAndBroadcastSection(),
                          const SizedBox(height: 16),
                          _buildTriageTableCard(),
                          const SizedBox(height: 16),
                          _buildDepotInventorySection(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 680;

        Widget toggleButtons = Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFF070C18),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: widget.onToggleToCitizen,
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    "Citizen View",
                    style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1))
                  ],
                ),
                child: const Text(
                  "Govt Command",
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ],
          ),
        );

        Widget fastApiBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: Color(0xFF34D399), shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              const Text(
                "FastAPI Live",
                style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFFCBD5E1)),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text("|", style: TextStyle(color: Color(0xFF475569), fontSize: 10)),
              ),
              Text(
                "~${_latency}ms",
                style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF38BDF8)),
              ),
            ],
          ),
        );

        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0D1527),
            border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1440),
              child: isNarrow
                  ? Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF38BDF8).withOpacity(0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.4)),
                                  ),
                                  child: const Icon(Icons.cloud_outlined, color: Color(0xFF38BDF8), size: 15),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "WeatherGPT",
                                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                            toggleButtons,
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Citizen • Govt Relief Platform",
                              style: TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
                            ),
                            fastApiBadge,
                          ],
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF38BDF8).withOpacity(0.2),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.4)),
                              ),
                              child: const Icon(Icons.cloud_outlined, color: Color(0xFF38BDF8), size: 16),
                            ),
                            const SizedBox(width: 10),
                            Row(
                              children: const [
                                Text(
                                  "WeatherGPT",
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.3),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Citizen • Govt Relief Platform",
                                  style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            toggleButtons,
                            const SizedBox(width: 10),
                            fastApiBadge,
                          ],
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildKpiGrid(int activeSos) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cardWidth = width < 360
            ? width
            : (width < 768 ? (width - 12) / 2 : (width - 36) / 4);

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _kpiCard("Active SOS signals", "$activeSos", "$activeSos verified beacons", true, cardWidth),
            _kpiCard("High-risk flood zones", "4", "Salt Lake, Bypass", false, cardWidth),
            _kpiCard("Rescue teams deployed", "27", "14 boats, 13 ground", false, cardWidth),
            _kpiCard("Relocated / rescued", _baseRescued.toString(), "safe rate 98%", false, cardWidth, isEmerald: true),
          ],
        );
      },
    );
  }

  Widget _kpiCard(String title, String value, String subtitle, bool hasPulse, double width, {bool isEmerald = false}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1527),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ),
              if (hasPulse)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF43F5E),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFF43F5E).withOpacity(0.6), blurRadius: 6, spreadRadius: 2)
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'monospace', color: Colors.white),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9.5,
              color: isEmerald ? const Color(0xFF34D399) : const Color(0xFF64748B),
              fontFamily: isEmerald ? 'sans-serif' : 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapAndBroadcastSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isStacked = constraints.maxWidth < 1024;
        if (isStacked) {
          return Column(
            children: [
              _buildLiveMapCard(),
              const SizedBox(height: 16),
              _buildTaskBroadcasterCard(),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: _buildLiveMapCard()),
            const SizedBox(width: 16),
            Expanded(flex: 5, child: _buildTaskBroadcasterCard()),
          ],
        );
      },
    );
  }

  Widget _buildLiveMapCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1527),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.circle, color: Color(0xFFF43F5E), size: 8),
                  SizedBox(width: 8),
                  Text(
                    "Live SOS & Inundation Map",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
                ),
                child: const Text(
                  "Inundation + SOS overlay",
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w500, color: Color(0xFF38BDF8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 300,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFF070C18),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _CanalFullMapPainter()),
                ),
                Positioned(
                  top: 10,
                  left: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("22.5726° N, 88.3639° E",
                          style: TextStyle(fontSize: 9.5, fontFamily: 'monospace', color: Color(0xFF64748B))),
                      SizedBox(height: 2),
                      Text("Kestopur Canal Lockgates 84% Capacity",
                          style: TextStyle(fontSize: 9, fontFamily: 'monospace', color: Color(0xFF0284C7))),
                    ],
                  ),
                ),
                Positioned(
                  top: 45,
                  left: 30,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      "Dum Dum\nNorth",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFFFDE68A)),
                    ),
                  ),
                ),
                Positioned(
                  top: 70,
                  right: 25,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE11D48).withOpacity(0.08),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE11D48).withOpacity(0.3)),
                        ),
                      ),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4C0519).withOpacity(0.85),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFF43F5E)),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFFF43F5E).withOpacity(0.4), blurRadius: 16, spreadRadius: 3),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              "Salt Lake Sector V",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFFFECDD3)),
                            ),
                            SizedBox(height: 2),
                            Text("1.8m Inundated",
                                style: TextStyle(fontSize: 7, fontFamily: 'monospace', color: Color(0xFFFB7185))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 30,
                  left: 30,
                  child: Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.45)),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      "New Alipore\nDrainage Alert",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: Color(0xFFFDE68A)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 6,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 4,
                children: const [
                  _LegendDot(color: Color(0xFFF43F5E), label: "Severe inundation"),
                  _LegendDot(color: Color(0xFFF59E0B), label: "Watch zone"),
                  _LegendDot(color: Color(0xFF38BDF8), label: "Resolved SOS"),
                ],
              ),
              const Text(
                "GIS Engine: ISRO MOSDAC Telemetry",
                style: TextStyle(fontSize: 9.5, fontFamily: 'monospace', color: Color(0xFF64748B)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskBroadcasterCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1527),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Raise Ground Problem / Task",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 3),
          const Text(
            "Broadcast high-priority triage missions to civilian volunteers and NDRF field units.",
            style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 14),
          _formLabel("Task title"),
          _formInput(_taskTitleController),
          const SizedBox(height: 10),
          _formLabel("Details"),
          TextField(
            controller: _taskDetailsController,
            maxLines: 3,
            style: const TextStyle(fontSize: 12, color: Colors.white),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color(0xFF070C18),
              contentPadding: const EdgeInsets.all(10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _formLabel("Target location"),
                    _formInput(_taskLocController),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _formLabel("Priority"),
                    Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF070C18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedPriority,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF0D1527),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFBBF24)),
                          items: ["High", "Critical", "Medium"]
                              .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                              .toList(),
                          onChanged: (val) => setState(() => _selectedPriority = val!),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              minimumSize: const Size(double.infinity, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.campaign_outlined, size: 18),
            label: const Text("Broadcast to Volunteers", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            onPressed: _handleBroadcast,
          ),
          if (_broadcastAlert != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF064E3B).withOpacity(0.5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF059669)),
              ),
              child: Text(
                _broadcastAlert!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10.5, color: Color(0xFF34D399)),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            runSpacing: 4,
            children: const [
              Text("Available: 31 citizens (5 ambulances)",
                  style: TextStyle(fontSize: 9.5, fontFamily: 'monospace', color: Color(0xFF38BDF8))),
              Text("Ward 62 Network", style: TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _formLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: Color(0xFFCBD5E1))),
      );

  Widget _formInput(TextEditingController ctrl) => SizedBox(
        height: 38,
        child: TextField(
          controller: ctrl,
          style: const TextStyle(fontSize: 12, color: Colors.white),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: const Color(0xFF070C18),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF334155)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF334155)),
            ),
          ),
        ),
      );

  Widget _buildTriageTableCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1527),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.circle, color: Color(0xFFF43F5E), size: 7),
                    SizedBox(width: 8),
                    Text(
                      "INCIDENT & HELP REQUEST TRIAGE",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.white),
                    ),
                  ],
                ),
                const Text(
                  "Source: FastAPI Gateway (/api/v1/incidents)",
                  style: TextStyle(fontSize: 9.5, fontFamily: 'monospace', color: Color(0xFF38BDF8)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF1E293B)),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 880),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFF070C18)),
                columnSpacing: 18,
                horizontalMargin: 14,
                headingRowHeight: 38,
                dataRowHeight: 54,
                columns: const [
                  DataColumn(
                      label: Text("ID",
                          style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF64748B)))),
                  DataColumn(
                      label: Text("CITIZEN / PROBLEM STATEMENT",
                          style: TextStyle(fontSize: 10, color: Color(0xFF64748B)))),
                  DataColumn(
                      label: Text("COORDINATES",
                          style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF64748B)))),
                  DataColumn(
                      label: Text("CATEGORY",
                          style: TextStyle(fontSize: 10, color: Color(0xFF64748B)))),
                  DataColumn(
                      label: Text("TIME",
                          style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF64748B)))),
                  DataColumn(
                      label: Text("STATUS",
                          style: TextStyle(fontSize: 10, color: Color(0xFF64748B)))),
                  DataColumn(
                      label: SizedBox(
                          width: 230,
                          child: Text("DISPATCH & TRIAGE ACTIONS",
                              textAlign: TextAlign.right, style: TextStyle(fontSize: 10, color: Color(0xFF64748B))))),
                ],
                rows: _allIncidents.map((item) {
                  final isResolved = item['status'] == 'Resolved';
                  Color catColor = const Color(0xFF38BDF8);
                  Color catBg = const Color(0xFF082F49);

                  if (item['catType'] == 'danger') {
                    catColor = const Color(0xFFFDA4AF);
                    catBg = const Color(0xFF4C0519).withOpacity(0.7);
                  } else if (item['catType'] == 'warning') {
                    catColor = const Color(0xFFFDE68A);
                    catBg = const Color(0xFF78350F).withOpacity(0.7);
                  }

                  return DataRow(
                    cells: [
                      DataCell(Text(item['id'],
                          style: const TextStyle(
                              fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)))),
                      DataCell(Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['citizen'],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isResolved ? const Color(0xFF64748B) : Colors.white,
                              decoration: isResolved ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          Text(item['contact'],
                              style: const TextStyle(fontSize: 9, color: Color(0xFF64748B), fontFamily: 'monospace')),
                        ],
                      )),
                      DataCell(Text(item['coords'],
                          style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF94A3B8)))),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: catBg,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: catColor.withOpacity(0.4)),
                        ),
                        child: Text(item['category'], style: TextStyle(fontSize: 9, color: catColor)),
                      )),
                      DataCell(Text(item['time'],
                          style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF94A3B8)))),
                      DataCell(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 6, color: isResolved ? const Color(0xFF34D399) : const Color(0xFFF43F5E)),
                          const SizedBox(width: 5),
                          Text(
                            item['status'],
                            style: TextStyle(
                              fontSize: 10,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              color: isResolved
                                  ? const Color(0xFF34D399)
                                  : (item['status'] == 'In Progress' ? const Color(0xFFFBBF24) : const Color(0xFFF43F5E)),
                            ),
                          ),
                        ],
                      )),
                      DataCell(SizedBox(
                        width: 230,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E293B),
                                minimumSize: const Size(72, 28),
                                side: const BorderSide(color: Color(0xFF334155)),
                                padding: const EdgeInsets.symmetric(horizontal: 5),
                              ),
                              onPressed: isResolved ? null : () => _dispatchTeam(item['id'], "NDRF"),
                              child: const Text("NDRF", style: TextStyle(fontSize: 9, color: Color(0xFFE2E8F0))),
                            ),
                            const SizedBox(width: 4),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E293B),
                                minimumSize: const Size(66, 28),
                                side: const BorderSide(color: Color(0xFF334155)),
                                padding: const EdgeInsets.symmetric(horizontal: 5),
                              ),
                              onPressed: isResolved ? null : () => _dispatchTeam(item['id'], "Volunteers"),
                              child: const Text("Volunteers", style: TextStyle(fontSize: 9, color: Color(0xFFE2E8F0))),
                            ),
                            const SizedBox(width: 4),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isResolved ? const Color(0xFF064E3B).withOpacity(0.6) : const Color(0xFF059669),
                                minimumSize: const Size(58, 28),
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                              ),
                              onPressed: () => _toggleResolve(item['id']),
                              child: Text(
                                isResolved ? "Resolved" : "Resolve",
                                style: TextStyle(
                                  fontSize: 9,
                                  color: isResolved ? const Color(0xFF34D399) : Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepotInventorySection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1527),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: const [
              Text("Relief Supply Depot Inventory",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
              Text("Hub: Salt Lake Central",
                  style: TextStyle(fontSize: 9.5, fontFamily: 'monospace', color: Color(0xFF94A3B8))),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            "Salt Lake Stadium Base Depot • Real-time reserve depletion",
            style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final double cardWidth;
              if (width < 520) {
                cardWidth = width;
              } else if (width < 960) {
                cardWidth = (width - 12) / 2;
              } else {
                cardWidth = (width - 48) / 5;
              }

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _depotCard("Drinking water packs", "40%", 0.40, const Color(0xFFF43F5E), "CRITICAL: Under 500L in Sector 5", "", cardWidth, isCritical: true),
                  _depotCard("Dry ration kits", "1,240 / 3,000", 0.42, const Color(0xFF0284C7), "Zone 1", "In stock", cardWidth),
                  _depotCard("Tarpaulin sheets", "310 / 500", 0.62, const Color(0xFF38BDF8), "Zone 2", "In stock", cardWidth),
                  _depotCard("Baby food tins", "96 / 300", 0.32, const Color(0xFFF59E0B), "LOW: Ward 62", "Re-order", cardWidth, isAmber: true),
                  _depotCard("First aid kits", "452 / 600", 0.75, const Color(0xFF10B981), "Zone 3", "Adequate", cardWidth),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _depotCard(
    String title,
    String val,
    double progress,
    Color barColor,
    String leftText,
    String rightText,
    double width, {
    bool isCritical = false,
    bool isAmber = false,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF070C18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCritical
              ? const Color(0xFF881337).withOpacity(0.6)
              : (isAmber ? const Color(0xFF78350F).withOpacity(0.6) : const Color(0xFF1E293B)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFFCBD5E1)),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                val,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: barColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: const Color(0xFF1E293B),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  leftText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    fontFamily: 'monospace',
                    color: isCritical ? const Color(0xFFFB7185) : (isAmber ? const Color(0xFFFBBF24) : const Color(0xFF94A3B8)),
                  ),
                ),
              ),
              if (rightText.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  rightText,
                  style: TextStyle(
                    fontSize: 9,
                    fontFamily: 'monospace',
                    color: isAmber ? const Color(0xFFFBBF24) : const Color(0xFF34D399),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8))),
      ],
    );
  }
}

class _CanalFullMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()..color = const Color(0xFF38BDF8).withOpacity(0.15);
    const spacing = 16.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.8, dotPaint);
      }
    }

    final canalBack = Paint()
      ..color = const Color(0xFF0369A1).withOpacity(0.35)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;

    final canalFront = Paint()
      ..color = const Color(0xFF38BDF8).withOpacity(0.8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path1 = Path()
      ..moveTo(120, 0)
      ..cubicTo(135, 90, 110, 180, 130, size.height);
    canvas.drawPath(path1, canalBack);
    canvas.drawPath(path1, canalFront);

    final branchBack = Paint()
      ..color = const Color(0xFF0284C7).withOpacity(0.4)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    final branchFront = Paint()
      ..color = const Color(0xFF38BDF8).withOpacity(0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path2 = Path()
      ..moveTo(125, 140)
      ..quadraticBezierTo(230, 170, 310, 240);
    canvas.drawPath(path2, branchBack);
    canvas.drawPath(path2, branchFront);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}