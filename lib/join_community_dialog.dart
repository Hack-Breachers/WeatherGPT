import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class JoinRescueCommunityDialog extends StatefulWidget {
  final bool startAtTasks;
  const JoinRescueCommunityDialog({super.key, this.startAtTasks = false});

  @override
  State<JoinRescueCommunityDialog> createState() => _JoinRescueCommunityDialogState();
}

class _JoinRescueCommunityDialogState extends State<JoinRescueCommunityDialog> {
  late bool _isSignUpTab;
    bool _isRegistering = false;

  // Temporary coordinates for registration.
  // We will replace this with actual user-provided/current coordinates later.
  static const double _registrationLatitude = 22.5726;
  static const double _registrationLongitude = 88.3639;

  Future<void> _registerMember() async {
    final fullName = _nameController.text.trim();
    final mobileNumber = _mobileController.text.trim();

    if (fullName.isEmpty || mobileNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter your name and mobile number."),
        ),
      );
      return;
    }

    setState(() {
      _isRegistering = true;
    });

    try {
      final uri = Uri.parse(
        "http://127.0.0.1:8000/api/rescue-community/register",
      ).replace(
        queryParameters: {
          "full_name": fullName,
          "mobile_number": mobileNumber,
          "blood_group": _selectedBloodGroup,
          "latitude": _registrationLatitude.toString(),
          "longitude": _registrationLongitude.toString(),
          "skills": _selectedBadges.join(", "),
        },
      );

      final response = await http.post(uri);

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 && data["success"] == true) {
        setState(() {
          _isSignUpTab = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Registration successful."),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data["message"] ?? "Registration failed.",
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Could not connect to the server: $e"),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  final TextEditingController _nameController = TextEditingController(text: "Arindam Ghosh");
  final TextEditingController _mobileController = TextEditingController(text: "+91 98300 00000");
  String _selectedBloodGroup = "O+";

  final List<String> _bloodGroups = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"];
  final List<String> _badges = [
    "Certified Swimmer",
    "Paramedic / Doctor",
    "4x4 Vehicle Owner",
    "Ham Radio Operator",
    "Boat Owner",
  ];
  final Set<String> _selectedBadges = {"Certified Swimmer"};

  final List<Map<String, dynamic>> _groundTasks = [
    {
      "title": "Distribute 200 food packets at Sector V Relief Camp",
      "description": "Camp population 480. Packets staged at Depot B, need carriers by 23:30.",
      "distance": "1.2 km away",
      "location": "Sector V Relief Camp, Salt Lake",
      "urgency": "Critical",
      "badges": ["Vehicle Owner", "General"],
      "claimed": false,
    },
    {
      "title": "Clear fallen tree near City Hospital Gate",
      "description": "Blocking ambulance lane. Chainsaw team + 4 hands required.",
      "distance": "2.7 km away",
      "location": "City Hospital Gate 2, Beliaghata",
      "urgency": "High",
      "badges": ["4x4 Vehicle Owner", "General"],
      "claimed": false,
    },
    {
      "title": "Boat evacuation support — Ward 58 lanes",
      "description": "Waist-deep water. Certified swimmers and boat owners only.",
      "distance": "3.4 km away",
      "location": "Ward 58, Topsia",
      "urgency": "Critical",
      "badges": ["Certified Swimmer", "Boat Owner"],
      "claimed": false,
    },
    {
      "title": "Ham radio relay at Rajarhat blackout pocket",
      "description": "Cellular down for 6 hrs. Need operator to relay headcounts hourly.",
      "distance": "6.1 km away",
      "location": "Rajarhat Block C",
      "urgency": "Medium",
      "badges": ["Ham Radio Operator"],
      "claimed": false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _isSignUpTab = !widget.startAtTasks;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  void _claimTask(int index) {
    setState(() => _groundTasks[index]["claimed"] = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0284C7),
        content: Text("Mobilized for: ${_groundTasks[index]["title"]}"),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 560,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E293B)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.65),
              blurRadius: 28,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modal Top Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.people_outline, color: Color(0xFF38BDF8), size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Join the Rescue Community",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              "Register once, then claim verified government-raised ground tasks.",
              style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 18),

            // Tab Buttons: "Volunteer sign-up" & "Ground tasks (4)"
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFF070C18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isSignUpTab = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _isSignUpTab ? const Color(0xFF1E293B) : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          "Volunteer sign-up",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: _isSignUpTab ? FontWeight.bold : FontWeight.normal,
                            color: _isSignUpTab ? Colors.white : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isSignUpTab = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: !_isSignUpTab ? const Color(0xFF1E293B) : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          "Ground tasks (4)",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: !_isSignUpTab ? FontWeight.bold : FontWeight.normal,
                            color: !_isSignUpTab ? Colors.white : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab Content
            Flexible(
              child: SingleChildScrollView(
                child: _isSignUpTab ? _buildSignUpTab() : _buildGroundTasksTab(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Volunteer Form View
  Widget _buildSignUpTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 400) {
              return Column(
                children: [
                  _buildInputField("Full name", _nameController),
                  const SizedBox(height: 12),
                  _buildInputField("Mobile number", _mobileController),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: _buildInputField("Full name", _nameController)),
                const SizedBox(width: 14),
                Expanded(child: _buildInputField("Mobile number", _mobileController)),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        const Text("Blood group", style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFFCBD5E1))),
        const SizedBox(height: 6),
        Container(
          height: 38,
          width: 170,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF070C18),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedBloodGroup,
              dropdownColor: const Color(0xFF0D1527),
              style: const TextStyle(fontSize: 12.5, color: Colors.white),
              items: _bloodGroups.map((bg) => DropdownMenuItem(value: bg, child: Text(bg))).toList(),
              onChanged: (val) => setState(() => _selectedBloodGroup = val!),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text("Skill badges", style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFFCBD5E1))),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _badges.map((badge) {
            final isSelected = _selectedBadges.contains(badge);
            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedBadges.remove(badge);
                  } else {
                    _selectedBadges.add(badge);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0284C7).withOpacity(0.2) : const Color(0xFF070C18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF1E293B)),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF94A3B8),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 22),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0284C7),
            minimumSize: const Size(double.infinity, 44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _isRegistering ? null : _registerMember,
child: _isRegistering
    ? const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
      )
    : const Text(
        "Register & see tasks",
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
        ),
      ],
    );
  }

  // 2. Ground Tasks View
  Widget _buildGroundTasksTab() {
    return Column(
      children: List.generate(_groundTasks.length, (index) {
        final task = _groundTasks[index];
        final isCritical = task["urgency"] == "Critical";
        final isHigh = task["urgency"] == "High";
        final isClaimed = task["claimed"] == true;

        Color badgeColor = isCritical
            ? const Color(0xFFE11D48)
            : (isHigh ? const Color(0xFFF59E0B) : const Color(0xFF38BDF8));

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF070C18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      task["title"],
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: badgeColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      task["urgency"],
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                task["description"],
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8), height: 1.35),
              ),
              const SizedBox(height: 10),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_outlined, color: Color(0xFF64748B), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "${task["distance"]} · ${task["location"]}",
                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  ...(task["badges"] as List<String>).map((b) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(b, style: const TextStyle(fontSize: 9.5, color: Color(0xFFCBD5E1))),
                      )),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isClaimed ? const Color(0xFF059669) : const Color(0xFF0284C7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: const Size(0, 34),
                ),
                onPressed: isClaimed ? null : () => _claimTask(index),
                child: Text(
                  isClaimed ? "✓ Mobilized" : "Claim Task & Mobilize",
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildInputField(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFFCBD5E1))),
        const SizedBox(height: 6),
        Container(
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF070C18),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: TextField(
            controller: ctrl,
            style: const TextStyle(fontSize: 12.5, color: Colors.white),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}