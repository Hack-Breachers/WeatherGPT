import 'package:flutter/material.dart';

class DonateReliefDialog extends StatefulWidget {
  const DonateReliefDialog({super.key});

  @override
  State<DonateReliefDialog> createState() => _DonateReliefDialogState();
}

class _DonateReliefDialogState extends State<DonateReliefDialog> {
  // 0 = Monetary, 1 = Supplies, 2 = Ledger
  int _activeTab = 0;

  // Monetary state
  int _selectedAmount = 1000;
  final TextEditingController _customAmountCtrl = TextEditingController(text: "1000");

  // Supplies state
  final Map<String, TextEditingController> _supplyControllers = {
    "Dry rations (10 kg kit)": TextEditingController(),
    "Drinking water packs": TextEditingController(),
    "Baby food tins": TextEditingController(),
    "Tarpaulin sheets": TextEditingController(),
    "First aid kits": TextEditingController(),
  };

  @override
  void dispose() {
    _customAmountCtrl.dispose();
    for (var ctrl in _supplyControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 540,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
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
            // Modal Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.volunteer_activism_outlined, color: Color(0xFF38BDF8), size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Donate to Cyclone Relief",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
              "All contributions route through verified state relief channels.",
              style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 18),

            // Segmented 3-Way Tab Switcher (Monetary | Supplies | Ledger)
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFF070C18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Row(
                children: [
                  _tabSegment(title: "Monetary", index: 0),
                  _tabSegment(title: "Supplies", index: 1),
                  _tabSegment(title: "Ledger", index: 2),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Dynamic Tab View
            Flexible(
              child: SingleChildScrollView(
                child: _activeTab == 0
                    ? _buildMonetaryTab()
                    : (_activeTab == 1 ? _buildSuppliesTab() : _buildLedgerTab()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabSegment({required String title, required int index}) {
    final isSelected = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1E293B) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: MONETARY DONATION
  // ==========================================
  Widget _buildMonetaryTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Relief Fund Routing Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF070C18),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.account_balance_outlined, color: Color(0xFF38BDF8), size: 16),
                  SizedBox(width: 8),
                  Text(
                    "Routing to Chief Minister's / PM National Relief Fund",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFFCBD5E1)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  "80G eligible",
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Amount Selectors (₹500, ₹1,000, ₹5,000, Custom)
        Row(
          children: [
            _amountButton(500),
            const SizedBox(width: 8),
            _amountButton(1000),
            const SizedBox(width: 8),
            _amountButton(5000),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF070C18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: TextField(
                  controller: _customAmountCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 12.5, color: Colors.white, fontFamily: 'monospace'),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                    border: InputBorder.none,
                    hintText: "Other",
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  onChanged: (val) {
                    final parsed = int.tryParse(val);
                    if (parsed != null) {
                      setState(() => _selectedAmount = parsed);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // QR Code Container
        Center(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF070C18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Column(
              children: [
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: CustomPaint(
                    size: const Size(130, 130),
                    painter: _MockQrPatternPainter(),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "wxrelief@upi · scan with GPay / PhonePe",
                  style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Pay CTA Button
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0284C7),
            minimumSize: const Size(double.infinity, 44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF0284C7),
                content: Text("Redirecting to UPI gateway for ₹$_selectedAmount..."),
              ),
            );
          },
          child: Text(
            "Pay ₹$_selectedAmount via UPI",
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _amountButton(int amount) {
    final isSelected = _selectedAmount == amount;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        setState(() {
          _selectedAmount = amount;
          _customAmountCtrl.text = amount.toString();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF070C18),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF1E293B),
          ),
        ),
        child: Text(
          "₹${amount >= 1000 ? '${(amount / 1000).toStringAsFixed(0)},000' : amount}",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 2: PHYSICAL SUPPLIES PLEDGE
  // ==========================================
  Widget _buildSuppliesTab() {
    return Column(
      children: [
        ..._supplyControllers.keys.map((title) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF070C18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    height: 34,
                    child: TextField(
                      controller: _supplyControllers[title],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.white, fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: "Qty",
                        hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: Color(0xFF1E293B)),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            )),
        const SizedBox(height: 14),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0284C7),
            minimumSize: const Size(double.infinity, 44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Color(0xFF059669),
                content: Text("Supplies pledge registered. Staging instructions sent via SMS."),
              ),
            );
          },
          child: const Text(
            "Pledge supplies",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 3: TRANSPARENT AUDIT LEDGER
  // ==========================================
  Widget _buildLedgerTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ledgerCard(
          title: "Funds collected",
          stat: "₹4.82 Cr",
          progress: 0.64,
          subtext: "Deployed ₹3.11 Cr (64%)",
        ),
        const SizedBox(height: 12),
        _ledgerCard(
          title: "Food packets dispatched",
          stat: "128,400",
          progress: 0.85,
          subtext: "Verified at 46 shelters",
        ),
        const SizedBox(height: 12),
        _ledgerCard(
          title: "Water crates delivered",
          stat: "9,120",
          progress: 0.42,
          subtext: "Zone 3 deficit remains",
        ),
        const SizedBox(height: 16),

        // Signed verification footer box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF064E3B).withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF059669).withOpacity(0.4)),
          ),
          child: Row(
            children: const [
              Icon(Icons.verified_outlined, color: Color(0xFF34D399), size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Every dispatch is signed by a district officer and published to this public ledger within 30 minutes.",
                  style: TextStyle(fontSize: 10.5, color: Color(0xFF34D399), height: 1.3),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _ledgerCard({
    required String title,
    required String stat,
    required double progress,
    required String subtext,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF070C18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              Text(stat,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: Colors.white)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: const Color(0xFF1E293B),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
            ),
          ),
          const SizedBox(height: 8),
          Text(subtext, style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}

// Renders the stylized QR grid representation
class _MockQrPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF070C18);
    const int grid = 9;
    final double step = size.width / grid;

    for (int r = 0; r < grid; r++) {
      for (int c = 0; c < grid; c++) {
        // Draw corners and pseudo QR data blocks
        if ((r < 3 && c < 3) || (r < 3 && c > 5) || (r > 5 && c < 3) || (r * c) % 3 == 0) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(c * step + 2, r * step + 2, step - 4, step - 4),
              const Radius.circular(2),
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}