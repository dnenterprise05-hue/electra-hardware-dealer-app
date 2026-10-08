import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'services/dealer_service.dart';
import 'widgets/pressable.dart';

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
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(8, 6, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: _ivory,
                        ),
                        onPressed: () =>
                            Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          "DEALER LEDGER",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _ivory,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: dealerDocId == null ||
                          dealerDocId.isEmpty
                      ? const Center(
                          child: Text(
                            "Dealer Not Found",
                            style:
                                TextStyle(color: _ivory),
                          ),
                        )
                      : _LedgerBody(
                          dealerDocId: dealerDocId),
                ),
              ],
            ),
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

  _Entry({
    required this.type,
    required this.particulars,
    required this.amount,
    required this.date,
    required this.createdAt,
  });
}

class _LedgerBody extends StatelessWidget {
  final String dealerDocId;

  const _LedgerBody({required this.dealerDocId});

  static const _gold = LedgerScreen._gold;
  static const _goldBright = LedgerScreen._goldBright;
  static const _ivory = LedgerScreen._ivory;
  static const _ivorySoft = LedgerScreen._ivorySoft;
  static const _muted = LedgerScreen._muted;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('dealers')
          .doc(dealerDocId)
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
              .doc(dealerDocId)
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

            // Build the display rows: opening first, then
            // sales/payments in date order.
            final rows = <_Row>[];
            double balance = opening;
            if (openingEntries.isNotEmpty) {
              rows.add(_Row(
                date: openingEntries.first.date,
                particulars:
                    openingEntries.first.particulars,
                sales: 0,
                payment: 0,
                balance: balance,
                isOpening: true,
              ));
            } else if (opening != 0) {
              rows.add(_Row(
                date: null,
                particulars: 'Opening Balance',
                sales: 0,
                payment: 0,
                balance: balance,
                isOpening: true,
              ));
            }

            double totalSales = 0;
            double totalPayment = 0;
            for (final e
                in entries.where((e) => e.type != 'opening')) {
              if (e.type == 'sales') {
                totalSales += e.amount;
                balance += e.amount;
                rows.add(_Row(
                  date: e.date,
                  particulars: e.particulars,
                  sales: e.amount,
                  payment: 0,
                  balance: balance,
                ));
              } else if (e.type == 'payment') {
                totalPayment += e.amount;
                balance -= e.amount;
                rows.add(_Row(
                  date: e.date,
                  particulars: e.particulars,
                  sales: 0,
                  payment: e.amount,
                  balance: balance,
                ));
              }
            }

            // O/S always equals the final running balance.
            final outstanding = balance;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                  20, 8, 20, 24),
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
                                  vertical: 16,
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
                  _glassPanel(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        // Horizontally scrollable table.
                        SingleChildScrollView(
                          scrollDirection:
                              Axis.horizontal,
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              _tableHeader(),
                              ...rows.map(_tableRow),
                              _tableTotal(
                                totalSales: totalSales,
                                totalPayment:
                                    totalPayment,
                                outstanding:
                                    outstanding,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (rows.isEmpty)
                    const Padding(
                      padding:
                          EdgeInsets.only(top: 24),
                      child: Center(
                        child: Text(
                          'No transactions yet',
                          style: TextStyle(
                              color: _muted,
                              fontSize: 14),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
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

  static const double _wDate = 92;
  static const double _wPart = 150;
  static const double _wAmt = 108;

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
          vertical: 10, horizontal: 12),
      child: Row(
        children: [
          _cell('DATE', _wDate, _muted, true),
          _cell('PARTICULARS', _wPart, _muted, true),
          _cell('SALES (₹)', _wAmt, _gold,
              true, TextAlign.right),
          _cell('PAYMENT (₹)', _wAmt, _ivorySoft,
              true, TextAlign.right),
          _cell('BALANCE (₹)', _wAmt, _goldBright,
              true, TextAlign.right),
        ],
      ),
    );
  }

  static Widget _tableRow(_Row r) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: _gold.withValues(alpha: 0.12),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(
          vertical: 9, horizontal: 12),
      child: Row(
        children: [
          _cell(
            r.date == null
                ? '—'
                : LedgerScreen._dateFmt
                    .format(r.date!),
            _wDate,
            _ivorySoft,
            false,
          ),
          _cell(r.particulars, _wPart, _ivory, false),
          _cell(
            r.sales > 0
                ? LedgerScreen._inr.format(r.sales)
                : '—',
            _wAmt,
            _gold,
            false,
            TextAlign.right,
          ),
          _cell(
            r.payment > 0
                ? LedgerScreen._inr.format(r.payment)
                : '—',
            _wAmt,
            _ivorySoft,
            false,
            TextAlign.right,
          ),
          _cell(
            LedgerScreen._inr.format(r.balance),
            _wAmt,
            _goldBright,
            true,
            TextAlign.right,
          ),
        ],
      ),
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
          vertical: 10, horizontal: 12),
      child: Row(
        children: [
          _cell('', _wDate, _ivory, true),
          _cell('TOTAL', _wPart, _ivory, true),
          _cell(
            LedgerScreen._inr.format(totalSales),
            _wAmt,
            _gold,
            true,
            TextAlign.right,
          ),
          _cell(
            LedgerScreen._inr.format(totalPayment),
            _wAmt,
            _ivorySoft,
            true,
            TextAlign.right,
          ),
          _cell(
            LedgerScreen._inr.format(outstanding),
            _wAmt,
            _goldBright,
            true,
            TextAlign.right,
          ),
        ],
      ),
    );
  }

  static Widget _cell(
    String text,
    double width,
    Color color,
    bool bold, [
    TextAlign align = TextAlign.left,
  ]) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight:
              bold ? FontWeight.w700 : FontWeight.w500,
          letterSpacing: 0.2,
        ),
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

  _Row({
    required this.date,
    required this.particulars,
    required this.sales,
    required this.payment,
    required this.balance,
    this.isOpening = false,
  });
}
