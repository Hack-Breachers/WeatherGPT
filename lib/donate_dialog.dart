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
  final TextEditingController _customAmountCtrl =
      TextEditingController(text: "1000");

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

    for (final ctrl in _supplyControllers.values) {
      ctrl.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Keep the dialog inside the phone's available width.
    final dialogWidth =
        screenWidth - 24 < 540 ? screenWidth - 24 : 540.0;

    // Reduce inner padding slightly on very narrow phones.
    final dialogPadding = screenWidth < 380 ? 16.0 : 22.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 20,
      ),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.90,
        ),
        padding: EdgeInsets.all(dialogPadding),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF1E293B),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.65),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // MODAL HEADER
            // ==========================================
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.volunteer_activism_outlined,
                        color: Color(0xFF38BDF8),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Donate to Cyclone Relief",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.grey,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 4),

            const Text(
              "All contributions route through verified state relief channels.",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                color: Color(0xFF94A3B8),
              ),
            ),

            const SizedBox(height: 18),

            // ==========================================
            // SEGMENTED 3-WAY TAB SWITCHER
            // ==========================================
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFF070C18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF1E293B),
                ),
              ),
              child: Row(
                children: [
                  _tabSegment(
                    title: "Monetary",
                    index: 0,
                  ),
                  _tabSegment(
                    title: "Supplies",
                    index: 1,
                  ),
                  _tabSegment(
                    title: "Ledger",
                    index: 2,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ==========================================
            // DYNAMIC TAB VIEW
            // ==========================================
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: _activeTab == 0
                    ? _buildMonetaryTab()
                    : (_activeTab == 1
                        ? _buildSuppliesTab()
                        : _buildLedgerTab()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB SEGMENT
  // ==========================================
  Widget _tabSegment({
    required String title,
    required int index,
  }) {
    final isSelected = _activeTab == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _activeTab = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 4,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF1E293B)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.normal,
              color:
                  isSelected ? Colors.white : Colors.grey,
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
        // ------------------------------------------
        // Relief Fund Routing Badge
        // ------------------------------------------
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF070C18),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF1E293B),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.account_balance_outlined,
                color: Color(0xFF38BDF8),
                size: 16,
              ),
              const SizedBox(width: 8),

              // This Expanded is the important overflow fix.
              Expanded(
                child: Text(
                  "Routing to Chief Minister's / PM National Relief Fund",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFCBD5E1),
                  ),
                ),
              ),

              const SizedBox(width: 6),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  "80G eligible",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ------------------------------------------
        // Amount Selectors
        // ------------------------------------------
        Row(
          children: [
            Expanded(
              child: _amountButton(500),
            ),
            const SizedBox(width: 6),

            Expanded(
              child: _amountButton(1000),
            ),
            const SizedBox(width: 6),

            Expanded(
              child: _amountButton(5000),
            ),
            const SizedBox(width: 6),

            Expanded(
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF070C18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF1E293B),
                  ),
                ),
                child: TextField(
                  controller: _customAmountCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Colors.white,
                    fontFamily: 'monospace',
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 10,
                    ),
                    border: InputBorder.none,
                    hintText: "Other",
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                  onChanged: (val) {
                    final parsed = int.tryParse(val);

                    if (parsed != null) {
                      setState(() {
                        _selectedAmount = parsed;
                      });
                    }
                  },
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ------------------------------------------
        // QR Code Container
        // ------------------------------------------
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF070C18),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF1E293B),
            ),
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

              // Prevent long UPI text from overflowing.
              Text(
                "wxrelief@upi · scan with GPay / PhonePe",
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // ------------------------------------------
        // Pay CTA Button
        // ------------------------------------------
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              final amount = _selectedAmount;

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF0284C7),
                  content: Text(
                    "Redirecting to UPI gateway for ₹$amount...",
                  ),
                ),
              );
            },
            child: Text(
              "Pay ₹$_selectedAmount via UPI",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // AMOUNT BUTTON
  // ==========================================
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
        height: 38,
        width: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0284C7)
              : const Color(0xFF070C18),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF38BDF8)
                : const Color(0xFF1E293B),
          ),
        ),
        child: Text(
          "₹${amount >= 1000 ? '${(amount / 1000).toStringAsFixed(0)},000' : amount}",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? Colors.white
                : const Color(0xFF94A3B8),
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
        ..._supplyControllers.keys.map(
          (title) => Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF070C18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF1E293B),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFFE2E8F0),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                SizedBox(
                  width: 70,
                  height: 34,
                  child: TextField(
                    controller: _supplyControllers[title],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontFamily: 'monospace',
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: "Qty",
                      hintStyle: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 8,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFF059669),
                  content: Text(
                    "Supplies pledge registered. "
                    "Staging instructions sent via SMS.",
                  ),
                ),
              );
            },
            child: const Text(
              "Pledge supplies",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
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

        // ------------------------------------------
        // Signed verification footer box
        // ------------------------------------------
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF064E3B).withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF059669).withOpacity(0.4),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(
                Icons.verified_outlined,
                color: Color(0xFF34D399),
                size: 16,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Every dispatch is signed by a district officer and "
                  "published to this public ledger within 30 minutes.",
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF34D399),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // LEDGER CARD
  // ==========================================
  Widget _ledgerCard({
    required String title,
    required String stat,
    required double progress,
    required String subtext,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF070C18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1E293B),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Flexible(
                child: Text(
                  stat,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: const Color(0xFF1E293B),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF0284C7),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            subtext,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontFamily: 'monospace',
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// MOCK QR PATTERN PAINTER
// ==========================================
class _MockQrPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF070C18);

    const int grid = 9;
    final double step = size.width / grid;

    for (int r = 0; r < grid; r++) {
      for (int c = 0; c < grid; c++) {
        // Draw corners and pseudo QR data blocks
        if ((r < 3 && c < 3) ||
            (r < 3 && c > 5) ||
            (r > 5 && c < 3) ||
            (r * c) % 3 == 0) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                c * step + 2,
                r * step + 2,
                step - 4,
                step - 4,
              ),
              const Radius.circular(2),
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}