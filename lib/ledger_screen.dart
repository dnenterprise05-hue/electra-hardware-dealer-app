import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'services/dealer_service.dart';
import 'widgets/pressable.dart';
import 'order_details_screen.dart';

/// Dealer Ledger — luxury showroom theme.
///
/// Data model (Firestore):
///   dealers/{dealerDocId}                    — firmName, city, gstNumber/gst,
///                                              optional openingBalance
///   dealers/{dealerDocId}/ledger/{entryId}   — one doc per transaction:
///       type:        "opening" | "sales" | "payment"
///       particulars: String  (e.g. "Sales", "Payment", "Opening Balance")
///       amount:      number  (₹)
///       date:        Timestamp (transaction date)
///       createdAt:   Timestamp (deterministic order for same-day entries)
///       reference:   String? (optional: order no / receipt no)
///
/// Calculation rules:
///   Total Sales   = sum of "sales" amounts only (opening excluded)
///   Total Payment = sum of "payment" amounts only (opening excluded)
///   O/S Amount    = Opening Balance + Total Sales − Total Payment
///   Each row's Balance is computed sequentially; sales increase the
///   outstanding, payments decrease it.
class LedgerScreen extends StatelessWidget {
  const LedgerScreen({super.key});

  static const _gold = Color(0xFFD8B36A);
  static const _goldBright = Color(0xFFF3DFAE);
  static const _ivory = Color(0xFFFFF8EE);
  static const _ivorySoft = Color(0xFFE4D3AC);
  static const _muted = Color(0xFFB9AC93);

  static final _inr = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );
  static final _dateFmt = DateFormat('dd-MM-yyyy');

  @override
  Widget build(BuildContext context) {
    final dealerDocId = DealerService.dealerDocId;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/login_background.png',
            fit: BoxFit.cover,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.68),
                  Colors.black.withValues(alpha: 0.42),
                  Colors.black.withValues(alpha: 0.60),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: dealerDocId == null ||
                    dealerDocId.isEmpty
                ? const Center(
                    child: Text(
                      "Dealer Not Found",
                      style: TextStyle(
                          color:
                              Color(0xFFFFF8EE)),
                    ),
                  )
                : _LedgerBody(
                    dealerDocId: dealerDocId),
          ),
        ],
      ),
    );
  }
}

/// Single ledger entry after normalization.
class _Entry {
  final String type; // opening | sales | payment
  final String particulars;
  final double amount;
  final DateTime date;
  final DateTime createdAt;
  final String? reference;

  _Entry({
    required this.type,
    required this.particulars,
    required this.amount,
    required this.date,
    required this.createdAt,
    this.reference,
  });

  /// Display label: "Bill No. X" / "Receipt No. X" when a
  /// reference exists, otherwise the generic particulars.
  String get displayParticulars {
    final ref = reference?.trim() ?? '';
    if (type == 'sales') {
      return ref.isNotEmpty ? 'Bill No. $ref' : particulars;
    }
    if (type == 'payment') {
      return ref.isNotEmpty ? 'Receipt No. $ref' : particulars;
    }
    return particulars;
  }
}

class _LedgerBody extends StatefulWidget {
  final String dealerDocId;

  const _LedgerBody({required this.dealerDocId});

  @override
  State<_LedgerBody> createState() => _LedgerBodyState();
}

class _LedgerBodyState extends State<_LedgerBody> {
  static const _gold = LedgerScreen._gold;
  static const _goldBright = LedgerScreen._goldBright;
  static const _ivory = LedgerScreen._ivory;
  static const _ivorySoft = LedgerScreen._ivorySoft;
  static const _muted = LedgerScreen._muted;

  /// Selected financial year, e.g. "26/27". Null until data loads.
  String? _selectedFy;

  /// Custom FY popup overlay (glass card).
  OverlayEntry? _fyOverlay;
  final GlobalKey _fyKey = GlobalKey();

  @override
  void dispose() {
    _removeFyMenu();
    super.dispose();
  }

  void _removeFyMenu() {
    _fyOverlay?.remove();
    _fyOverlay = null;
  }

  /// Toggles the premium glass FY selector popup.
  void _toggleFyMenu(List<String> fyList) {
    if (_fyOverlay != null) {
      _removeFyMenu();
      return;
    }
    final box =
        _fyKey.currentContext?.findRenderObject()
            as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(Offset.zero);
    final size = box.size;

    _fyOverlay = OverlayEntry(
      builder: (_) => Stack(
        children: [
          // Tap outside to dismiss.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _removeFyMenu,
              child: const SizedBox.shrink(),
            ),
          ),
          // Glass popup under the selector, kept on-screen.
          Positioned(
            right: 12,
            top: pos.dy + size.height + 6,
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(
                    minWidth: 100, maxWidth: 140),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        _gold.withValues(alpha: 0.45),
                  ),
                ),
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                        sigmaX: 8, sigmaY: 8),
                    child: Container(
                      color: Colors.black.withValues(
                          alpha: 0.78),
                      child: Column(
                        mainAxisSize:
                            MainAxisSize.min,
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .stretch,
                        children: fyList
                            .map(
                              (fy) =>
                                  _fyMenuItem(fy),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_fyOverlay!);
  }

  /// One FY option row in the glass popup.
  Widget _fyMenuItem(String fy) {
    final selected = fy == _selectedFy;
    return InkWell(
      onTap: () {
        setState(() => _selectedFy = fy);
        _removeFyMenu();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: _gold.withValues(alpha: 0.12),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'FY $fy',
                style: TextStyle(
                  color: selected
                      ? _goldBright
                      : _ivory,
                  fontSize: 13,
                  fontWeight: selected
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check,
                color: _gold,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  /// Indian financial year (April–March) for a date, e.g. "26/27".
  static String _fyOf(DateTime d) {
    final startYear = d.month >= 4 ? d.year : d.year - 1;
    final a = (startYear % 100).toString().padLeft(2, '0');
    final b = ((startYear + 1) % 100).toString().padLeft(2, '0');
    return '$a/$b';
  }

  /// First day of a financial year, e.g. "26/27" -> 2026-04-01.
  static DateTime _fyStart(String fy) {
    final yy = int.parse(fy.split('/')[0]);
    return DateTime(2000 + yy, 4, 1);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('dealers')
          .doc(widget.dealerDocId)
          .snapshots(),
      builder: (context, dealerSnap) {
        if (dealerSnap.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
                color: _gold),
          );
        }
        if (!dealerSnap.hasData ||
            !dealerSnap.data!.exists) {
          return const Center(
            child: Text(
              "Dealer Not Found",
              style: TextStyle(color: _ivory),
            ),
          );
        }

        final dealer =
            dealerSnap.data!.data() ?? <String, dynamic>{};
        final partyName =
            (dealer['firmName'] ?? '').toString();
        final city = (dealer['city'] ?? '').toString();
        final gst = DealerService.gstOf(dealer);

        return StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('dealers')
              .doc(widget.dealerDocId)
              .collection('ledger')
              .snapshots(),
          builder: (context, ledgerSnap) {
            if (ledgerSnap.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                    color: _gold),
              );
            }

            final docs = ledgerSnap.data?.docs ?? [];
            final entries = docs.map(_toEntry).toList();

            // Chronological, oldest first. Same-day entries keep a
            // deterministic order via createdAt.
            entries.sort((a, b) {
              final c = a.date.compareTo(b.date);
              if (c != 0) return c;
              return a.createdAt.compareTo(b.createdAt);
            });

            // Opening balance: explicit "opening" entry wins,
            // otherwise the dealer's openingBalance field, else 0.
            double opening = 0;
            final openingEntries = entries
                .where((e) => e.type == 'opening')
                .toList();
            if (openingEntries.isNotEmpty) {
              opening = openingEntries.first.amount;
            } else {
              final raw = dealer['openingBalance'];
              if (raw is num) opening = raw.toDouble();
            }

            // Display rows for the selected FY.
            final rows = <_Row>[];
            double balance = 0;
            double totalSales = 0;
            double totalPayment = 0;

            // ---- Financial year filter ----
            // Available FYs come only from actual sales/bill dates.
            final fySet = <String>{};
            for (final e in entries) {
              if (e.type == 'sales') fySet.add(_fyOf(e.date));
            }
            final fyList = fySet.toList()..sort();
            if (fyList.isEmpty) {
              // No sales yet: offer the current FY so the UI stays usable.
              fyList.add(_fyOf(DateTime.now()));
            }
            if (_selectedFy == null ||
                !fyList.contains(_selectedFy)) {
              _selectedFy = fyList.last;
            }
            final selFy = _selectedFy!;
            final fyStart = _fyStart(selFy);
            final fyEnd =
                DateTime(fyStart.year + 1, 4, 1);

            // Balance carried into the selected FY: opening +
            // net of all transactions before the FY started.
            double fyOpening = opening;
            for (final e in entries) {
              if (e.date.isBefore(fyStart)) {
                if (e.type == 'sales') {
                  fyOpening += e.amount;
                } else if (e.type == 'payment') {
                  fyOpening -= e.amount;
                }
              }
            }

            // Entries visible in the selected FY.
            final fyEntries = entries
                .where((e) =>
                    !e.date.isBefore(fyStart) &&
                    e.date.isBefore(fyEnd))
                .toList();

            // Rebuild display rows for the selected FY.
            rows.clear();
            balance = fyOpening;
            totalSales = 0;
            totalPayment = 0;
            final fyOpenEntries = fyEntries
                .where((e) => e.type == 'opening')
                .toList();
            if (fyOpenEntries.isNotEmpty) {
              final oe = fyOpenEntries.first;
              rows.add(_Row(
                date: oe.date,
                particulars: oe.displayParticulars,
                sales: 0,
                payment: 0,
                balance: balance,
                isOpening: true,
                type: 'opening',
              ));
            } else if (fyOpening != 0) {
              rows.add(_Row(
                date: null,
                particulars: 'Opening Balance',
                sales: 0,
                payment: 0,
                balance: balance,
                isOpening: true,
                type: 'opening',
              ));
            }
            for (final e in fyEntries
                .where((e) => e.type != 'opening')) {
              if (e.type == 'sales') {
                totalSales += e.amount;
                balance += e.amount;
                rows.add(_Row(
                  date: e.date,
                  particulars: e.displayParticulars,
                  sales: e.amount,
                  payment: 0,
                  balance: balance,
                  reference: e.reference,
                  type: 'sales',
                ));
              } else if (e.type == 'payment') {
                totalPayment += e.amount;
                balance -= e.amount;
                rows.add(_Row(
                  date: e.date,
                  particulars: e.displayParticulars,
                  sales: 0,
                  payment: e.amount,
                  balance: balance,
                  reference: e.reference,
                  type: 'payment',
                ));
              }
            }

            // O/S always equals the final running balance.
            final outstanding = balance;

            return Column(
              children: [
                _buildHeader(fyList),
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(
                            20, 8, 20, 16),
                    child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  _glassPanel(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        _infoRow(
                            'PARTY NAME', partyName),
                        const SizedBox(height: 8),
                        _infoRow('CITY', city),
                        const SizedBox(height: 8),
                        _infoRow('GST NO.', gst),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Prominent O/S amount.
                  Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(14),
                      border: Border.all(
                        color: _gold.withValues(
                            alpha: 0.55),
                        width: 1.2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(14),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                            sigmaX: 2.5, sigmaY: 2.5),
                        child: Container(
                          color: Colors.black.withValues(
                              alpha: 0.18),
                          padding:
                              const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 18),
                          child: Column(
                            children: [
                              const Text(
                                'O/S AMOUNT',
                                style: TextStyle(
                                  color: _muted,
                                  fontSize: 12,
                                  fontWeight:
                                      FontWeight.w600,
                                  letterSpacing: 2.0,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                LedgerScreen._inr.format(
                                    outstanding),
                                style: const TextStyle(
                                  color: _goldBright,
                                  fontSize: 30,
                                  fontWeight:
                                      FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Ledger table: fixed header, scrollable rows,
                  // fixed total. Dealer info + O/S stay visible.
                  Expanded(
                    child: _glassPanel(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                        children: [
                          _tableHeader(),
                          Expanded(
                            child: rows.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No transactions yet',
                                      style: TextStyle(
                                          color: _muted,
                                          fontSize: 14),
                                    ),
                                  )
                                : ListView.builder(
                                    padding:
                                        EdgeInsets.zero,
                                    itemCount: rows.length,
                                    itemBuilder:
                                        (context, index) =>
                                            _tableRow(
                                                context,
                                                rows[
                                                    index]),
                                  ),
                          ),
                          _tableTotal(
                            totalSales: totalSales,
                            totalPayment: totalPayment,
                            outstanding: outstanding,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
          },
        );
      },
    );
  }

  /// Header: back (left) | DEALER LEDGER (center) | FY (right).
  /// Both side zones share the same fixed width so the title stays
  /// perfectly screen-centered regardless of dropdown width.
  Widget _buildHeader(List<String> fyList) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 12, 0),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            // Left zone: single back button.
            SizedBox(
              width: 96,
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: _ivory,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            // Center: title, always screen-centered.
            const Expanded(
              child: Text(
                "DEALER LEDGER",
                textAlign: TextAlign.center,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: TextStyle(
                  color: _ivory,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                ),
              ),
            ),
            // Right zone: compact FY selector (glass popup).
            SizedBox(
              width: 96,
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  key: _fyKey,
                  onTap: () => _toggleFyMenu(fyList),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(8),
                      border: Border.all(
                        color: _gold.withValues(
                            alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'FY $_selectedFy',
                          style: const TextStyle(
                            color: _goldBright,
                            fontSize: 11,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: _gold,
                          size: 14,
                        ),
                      ],
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

  static _Entry _toEntry(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final type =
        (data['type'] ?? 'sales').toString().toLowerCase();
    final amount = (data['amount'] is num)
        ? (data['amount'] as num).toDouble()
        : 0.0;

    DateTime readDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) {
        try {
          return LedgerScreen._dateFmt.parse(v);
        } catch (_) {}
      }
      return DateTime(1970);
    }

    return _Entry(
      type: type,
      particulars:
          (data['particulars'] ?? type).toString(),
      amount: amount,
      date: readDate(data['date']),
      createdAt: readDate(data['createdAt']),
      reference: (data['reference'] as String?)?.trim(),
    );
  }

  static Widget _glassPanel({
    required Widget child,
    EdgeInsetsGeometry padding =
        const EdgeInsets.all(16),
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _gold.withValues(alpha: 0.35),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(
              sigmaX: 2.5, sigmaY: 2.5),
          child: Container(
            color:
                Colors.black.withValues(alpha: 0.10),
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }

  static Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '—' : value,
            style: const TextStyle(
              color: _ivory,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ---- Transaction table ----

  // Flex proportions — table always fits the screen width,
  // no horizontal scroll. DATE 17 / PARTICULARS 28 /
  // SALES 18 / PAYMENT 18 / BALANCE 19.
  static const int _fDate = 17;
  static const int _fPart = 29;
  static const int _fAmt = 18;
  static const int _fBal = 18;

  static Widget _tableHeader() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: _gold.withValues(alpha: 0.35),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 10),
      child: Row(
        children: [
          _hcell('DATE', _fDate, TextAlign.center),
          _vdiv(18),
          _hcell('PARTICULARS', _fPart, TextAlign.center),
          _vdiv(18),
          _hcell('SALES (₹)', _fAmt, TextAlign.center),
          _vdiv(18),
          _hcell('PAYMENT (₹)', _fAmt, TextAlign.center),
          _vdiv(18),
          _hcell('BALANCE (₹)', _fBal, TextAlign.center),
        ],
      ),
    );
  }

  /// Header cell — 9px champagne, never truncated.
  static Widget _hcell(String text, int flex,
      [TextAlign align = TextAlign.left]) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.visible,
        style: const TextStyle(
          color: _muted,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  /// Body cell — 11px ivory, single line.
  static Widget _bcell(String text, int flex, Color color,
      [TextAlign align = TextAlign.left,
      bool bold = false]) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight:
              bold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }

  /// Thin vertical grid separator (fixed height, no layout loop).
  static Widget _vdiv(double height) {
    return Container(
      width: 1,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      color: _gold.withValues(alpha: 0.18),
    );
  }

  static Widget _tableRow(BuildContext context, _Row r) {
    final tappable = (r.reference?.isNotEmpty ?? false) &&
        (r.type == 'sales' || r.type == 'payment');

    Widget row = Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: _gold.withValues(alpha: 0.12),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 9),
      child: Row(
        children: [
          _bcell(
            r.date == null
                ? '—'
                : LedgerScreen._dateFmt.format(r.date!),
            _fDate,
            _ivorySoft,
            TextAlign.center,
          ),
          _vdiv(26),
          _bcell(r.particulars, _fPart, _ivory,
              TextAlign.center),
          _vdiv(26),
          _bcell(
            r.sales > 0
                ? LedgerScreen._inr.format(r.sales)
                : '—',
            _fAmt,
            _gold,
            TextAlign.center,
          ),
          _vdiv(26),
          _bcell(
            r.payment > 0
                ? LedgerScreen._inr.format(r.payment)
                : '—',
            _fAmt,
            _ivorySoft,
            TextAlign.center,
          ),
          _vdiv(26),
          _bcell(
            LedgerScreen._inr.format(r.balance),
            _fBal,
            _goldBright,
            TextAlign.center,
            true,
          ),
        ],
      ),
    );

    if (!tappable) return row;

    // Tapping a bill/receipt row opens the matching order when
    // one exists; otherwise the tap is a silent no-op.
    return Pressable(
      onTap: () async {
        final ref = r.reference!.trim();
        try {
          final snap = await FirebaseFirestore.instance
              .collection('orders')
              .where('orderNo', isEqualTo: ref)
              .limit(1)
              .get();
          if (snap.docs.isNotEmpty && context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderDetailsScreen(
                  order: snap.docs.first.data(),
                ),
              ),
            );
          }
        } catch (_) {
          // Non-breaking: keep the row inert on any failure.
        }
      },
      child: row,
    );
  }

  static Widget _tableTotal({
    required double totalSales,
    required double totalPayment,
    required double outstanding,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: _gold.withValues(alpha: 0.45),
            width: 1.2,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 10),
      child: Row(
        children: [
          // TOTAL spans DATE + PARTICULARS, centered.
          Expanded(
            flex: _fDate + _fPart,
            child: const Text(
              'TOTAL',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
            ),
          ),
          _vdiv(20),
          _bcell(
            LedgerScreen._inr.format(totalSales),
            _fAmt,
            _muted,
            TextAlign.center,
            true,
          ),
          _vdiv(20),
          _bcell(
            LedgerScreen._inr.format(totalPayment),
            _fAmt,
            _muted,
            TextAlign.center,
            true,
          ),
          _vdiv(20),
          _bcell(
            LedgerScreen._inr.format(outstanding),
            _fBal,
            _muted,
            TextAlign.center,
            true,
          ),
        ],
      ),
    );
  }
}

/// Display row with its sequential balance.
class _Row {
  final DateTime? date;
  final String particulars;
  final double sales;
  final double payment;
  final double balance;
  final bool isOpening;
  final String? reference;
  final String type;

  _Row({
    required this.date,
    required this.particulars,
    required this.sales,
    required this.payment,
    required this.balance,
    this.isOpening = false,
    this.reference,
    this.type = '',
  });
}
