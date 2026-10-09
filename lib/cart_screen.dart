import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'models/cart_item.dart';
import 'services/cart_service.dart';
import 'services/dealer_service.dart';

/// Cart — luxury showroom theme.
///
/// UI-only redesign. Cart items, quantities, remove, totals and
/// the full order-submission flow are unchanged.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static const _gold = Color(0xFFD8B36A);
  static const _goldBright = Color(0xFFF3DFAE);
  static const _ivory = Color(0xFFFFF8EE);
  static const _ivorySoft = Color(0xFFE4D3AC);
  static const _muted = Color(0xFFB9AC93);

  @override
  Widget build(BuildContext context) {
    final items = CartService.cartItems;

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
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          "MY CART",
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
                  child: items.isEmpty
                      ? const Center(
                          child: Text(
                            "Cart is Empty",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: _ivory,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                              20, 8, 20, 16),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final CartItem item =
                                items[index];
                            return Container(
                              margin:
                                  const EdgeInsets.only(
                                      bottom: 12),
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(
                                        14),
                                border: Border.all(
                                  color: _gold.withValues(
                                      alpha: 0.35),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(
                                        14),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                      sigmaX: 2.5,
                                      sigmaY: 2.5),
                                  child: Container(
                                    color: Colors.black
                                        .withValues(
                                            alpha: 0.10),
                                    padding:
                                        const EdgeInsets
                                            .all(14),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        Row(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                          10),
                                              child:
                                                  Image.network(
                                                item.imageUrl,
                                                width: 84,
                                                height: 84,
                                                fit: BoxFit
                                                    .contain,
                                                errorBuilder:
                                                    (context,
                                                        error,
                                                        stackTrace) {
                                                  return Container(
                                                    width:
                                                        84,
                                                    height:
                                                        84,
                                                    color: Colors
                                                        .black
                                                        .withValues(
                                                            alpha:
                                                                0.4),
                                                    child:
                                                        const Icon(
                                                      Icons
                                                          .image,
                                                      size:
                                                          36,
                                                      color:
                                                          _muted,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                            const SizedBox(
                                                width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .start,
                                                children: [
                                                  Text(
                                                    item
                                                        .modelNo,
                                                    style:
                                                        const TextStyle(
                                                      fontSize:
                                                          18,
                                                      fontWeight:
                                                          FontWeight
                                                              .w600,
                                                      color:
                                                          _ivory,
                                                      letterSpacing:
                                                          0.4,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                      height:
                                                          6),
                                                  Text(
                                                    "Finish : ${item.finish}",
                                                    style:
                                                        const TextStyle(
                                                      fontSize:
                                                          14,
                                                      color:
                                                          _ivory,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () {
                                                setState(
                                                    () {
                                                  CartService
                                                      .removeItem(
                                                          index);
                                                });
                                              },
                                              icon:
                                                  const Icon(
                                                Icons
                                                    .delete_outline,
                                                color: _gold,
                                                size: 22,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                            height: 10),
                                        ...item.quantities
                                            .entries
                                            .where((e) =>
                                                e.value >
                                                0)
                                            .map(
                                              (e) {
                                                final price =
                                                    item.prices[
                                                        e.key];
                                                final lineTotal =
                                                    price !=
                                                            null
                                                        ? (price *
                                                                e.value)
                                                            .roundToDouble()
                                                        : null;
                                                final fmt =
                                                    NumberFormat.currency(
                                                  locale:
                                                      'en_IN',
                                                  symbol:
                                                      '₹',
                                                  decimalDigits:
                                                      0,
                                                );
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets
                                                          .only(
                                                              bottom:
                                                                  6),
                                                  child:
                                                      FittedBox(
                                                    fit: BoxFit
                                                        .scaleDown,
                                                    alignment:
                                                        Alignment
                                                            .centerLeft,
                                                    child:
                                                        Row(
                                                      children: [
                                                        Text(
                                                          e.key,
                                                          style:
                                                              const TextStyle(
                                                            fontSize:
                                                                13,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500,
                                                            color:
                                                                _ivory,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width:
                                                                6),
                                                        const Icon(
                                                          Icons
                                                              .arrow_forward,
                                                          size:
                                                              12,
                                                          color:
                                                              _ivory,
                                                        ),
                                                        const SizedBox(
                                                            width:
                                                                6),
                                                        Text(
                                                          "${e.value} PCS",
                                                          style:
                                                              const TextStyle(
                                                            fontSize:
                                                                13,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600,
                                                            color:
                                                                _ivory,
                                                          ),
                                                        ),
                                                        if (price !=
                                                                null &&
                                                            lineTotal !=
                                                                null) ...[
                                                          const Text(
                                                            " × ",
                                                            style:
                                                                TextStyle(
                                                              fontSize:
                                                                  13,
                                                              color:
                                                                  _ivory,
                                                            ),
                                                          ),
                                                          Text(
                                                            fmt.format(price),
                                                            style:
                                                                const TextStyle(
                                                              fontSize:
                                                                  13,
                                                              color:
                                                                  _ivory,
                                                            ),
                                                          ),
                                                          const Text(
                                                            " = ",
                                                            style:
                                                                TextStyle(
                                                              fontSize:
                                                                  13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color:
                                                                  _ivory,
                                                            ),
                                                          ),
                                                          Text(
                                                            fmt.format(
                                                                lineTotal),
                                                            style:
                                                                const TextStyle(
                                                              fontSize:
                                                                  13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color:
                                                                  _ivory,
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                if (items.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: _gold.withValues(
                              alpha: 0.25),
                        ),
                      ),
                    ),
                    child: ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                            sigmaX: 2.5, sigmaY: 2.5),
                        child: Container(
                          color: Colors.black
                              .withValues(alpha: 0.35),
                          padding:
                              const EdgeInsets.fromLTRB(
                                  20, 14, 20, 14),
                          child: SafeArea(
                            top: false,
                            child: Column(
                              mainAxisSize:
                                  MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .spaceBetween,
                                  children: [
                                    const Text(
                                      "Total Models",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight:
                                            FontWeight.w600,
                                        color: _ivory,
                                      ),
                                    ),
                                    Text(
                                      "${items.length}",
                                      style:
                                          const TextStyle(
                                        fontSize: 19,
                                        fontWeight:
                                            FontWeight.w700,
                                        color: _goldBright,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Price summary: taxable + GST 18% + total.
                                Builder(
                                  builder: (context) {
                                    double taxable = 0;
                                    bool hasPricing =
                                        false;
                                    for (final item
                                        in items) {
                                      if (item
                                          .hasPricing) {
                                        hasPricing =
                                            true;
                                      }
                                      taxable += item
                                          .estimateTotal;
                                    }
                                    if (!hasPricing) {
                                      return const SizedBox
                                          .shrink();
                                    }
                                    taxable = taxable
                                        .roundToDouble();
                                    final gst =
                                        (taxable *
                                                18 /
                                                100)
                                            .roundToDouble();
                                    final total =
                                        taxable + gst;
                                    final fmt =
                                        NumberFormat
                                            .currency(
                                      locale: 'en_IN',
                                      symbol: '₹',
                                      decimalDigits: 0,
                                    );
                                    Widget row(
                                        String label,
                                        double amount,
                                        {bool bold =
                                            false}) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets
                                                .only(
                                                    bottom:
                                                        6),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment
                                                  .spaceBetween,
                                          children: [
                                            Text(
                                              label,
                                              style:
                                                  const TextStyle(
                                                fontSize:
                                                    14,
                                                color:
                                                    _ivory,
                                                fontWeight: bold
                                                    ? FontWeight
                                                        .w700
                                                    : FontWeight
                                                        .w500,
                                              ),
                                            ),
                                            Text(
                                              fmt.format(
                                                  amount),
                                              style:
                                                  TextStyle(
                                                fontSize: bold
                                                    ? 18
                                                    : 15,
                                                fontWeight:
                                                    FontWeight
                                                        .w700,
                                                color:
                                                    _ivory,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }

                                    return Padding(
                                      padding:
                                          const EdgeInsets
                                              .only(
                                                  bottom:
                                                      8),
                                      child: Column(
                                        children: [
                                          row(
                                              "Taxable Amount",
                                              taxable),
                                          row("GST 18%",
                                              gst),
                                          const Divider(
                                            color: _gold,
                                            height: 12,
                                            thickness:
                                                0.5,
                                          ),
                                          row(
                                              "TOTAL ESTIMATE",
                                              total,
                                              bold:
                                                  true),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child:
                                      ElevatedButton.icon(
                                    onPressed: () async =>
                                        _submitOrder(
                                            context),
                                    style: ElevatedButton
                                        .styleFrom(
                                      backgroundColor:
                                          _gold,
                                      foregroundColor:
                                          Colors.black,
                                      shape:
                                          RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                                    14),
                                      ),
                                      elevation: 0,
                                    ),
                                    icon: const Icon(
                                        Icons.send,
                                        size: 20),
                                    label: const Text(
                                      "SUBMIT ORDER",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight:
                                            FontWeight.w700,
                                        letterSpacing: 1.4,
                                      ),
                                    ),
                                  ),
                                ),
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
        ],
      ),
    );
  }

  /// Order submission — logic unchanged from the previous implementation.
  Future<void> _submitOrder(BuildContext context) async {
    final items = CartService.cartItems;

    // ---- 1. Dealer safety: fail fast before touching the counter.
    // Uses the dealer identity/session from the OTP login gate.
    final user = FirebaseAuth.instance.currentUser;

    final dealerDoc = await DealerService.getDealerDoc();

    if (dealerDoc == null || !dealerDoc.exists) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Dealer Not Found. Please login again.",
          ),
        ),
      );
      return;
    }

    final dealerData =
        dealerDoc.data() ?? <String, dynamic>{};

    // ---- 2. Mobile normalization: exactly 10 digits, validated.
    // Auth number first, dealer master record as fallback.
    final mobile10 = DealerService.normalizeMobile10(
          user?.phoneNumber,
        ) ??
        DealerService.normalizeMobile10(
          dealerData["mobile"]?.toString(),
        );

    if (mobile10 == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Invalid dealer mobile number. Please login again.",
          ),
        ),
      );
      return;
    }

    try {
      // ---- 3. Transactional order counter.
      // Atomic: simultaneous submissions cannot
      // allocate the same sequence number.
      final counterRef = FirebaseFirestore.instance
          .collection("counters")
          .doc("orders");

      final int orderSeq = await FirebaseFirestore.instance
          .runTransaction((transaction) async {
        final snapshot =
            await transaction.get(counterRef);

        int lastNumber = 0;
        if (snapshot.exists) {
          final raw = snapshot.data()?["lastNumber"];
          if (raw is int) {
            lastNumber = raw;
          } else if (raw is num) {
            lastNumber = raw.toInt();
          }
        }

        final next = lastNumber + 1;
        transaction.set(
          counterRef,
          {"lastNumber": next},
          SetOptions(merge: true),
        );
        return next;
      });

      final orderNo =
          "EH-${DateFormat("yyyyMMdd").format(DateTime.now())}-${orderSeq.toString().padLeft(4, '0')}";

      debugPrint("ORDER UID : ${user?.uid}");
      debugPrint("ORDER MOBILE : $mobile10");

      final orderRef =
          FirebaseFirestore.instance.collection("orders").doc();

      await orderRef.set({
        "dealerMobile": mobile10,
        "dealerUid": user?.uid ?? "",
        "dealerName": dealerData["firmName"] ?? "",
        "dealerCity": dealerData["city"] ?? "",
        "orderDocId": orderRef.id,
        "orderNo": orderNo,
        "date": DateFormat("dd-MM-yyyy").format(DateTime.now()),
        "time": DateFormat("hh:mm a").format(DateTime.now()),
        "createdAt": FieldValue.serverTimestamp(),
        "status": "Pending",
        "products": items.map((item) {
          return {
            "modelNo": item.modelNo,
            "finish": item.finish,
            "imageUrl": item.imageUrl,
            "quantities": item.quantities,
          };
        }).toList(),
      });

      CartService.clearCart();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Order Submitted\nOrder No : $orderNo",
          ),
        ),
      );
    } catch (_) {
      // Never crash, never leave a partial order,
      // and keep the cart intact on failure.
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Order submission failed. Please try again.",
          ),
        ),
      );
      return;
    }

    if (context.mounted) setState(() {});
  }
}
