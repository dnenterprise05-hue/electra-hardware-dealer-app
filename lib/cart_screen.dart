import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

import 'models/cart_item.dart';
import 'services/cart_service.dart';
import 'services/dealer_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  Widget build(BuildContext context) {
    final items = CartService.cartItems;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text("My Cart"),
      ),

      body: items.isEmpty
          ? const Center(
              child: Text(
                "Cart is Empty",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : Column(
              children: [

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: items.length,

                    itemBuilder: (context, index) {

                      final CartItem item = items[index];
                                            return Card(
                        color: Colors.white,
                        elevation: 4,
                        shadowColor: Colors.black12,
                        margin: const EdgeInsets.only(bottom: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Row(
                                children: [

                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      item.imageUrl,
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          width: 90,
                                          height: 90,
                                          color: Colors.grey.shade200,
                                          child: const Icon(
                                            Icons.image,
                                            size: 40,
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                  const SizedBox(width: 15),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [

                                        Text(
                                          item.modelNo,
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),

                                        const SizedBox(height: 5),

                                        Text(
                                          "Finish : ${item.finish}",
                                          style: const TextStyle(
                                            fontSize: 16,
                                          ),
                                        ),

                                      ],
                                    ),
                                  ),

                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        CartService.removeItem(index);
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                  ),

                                ],
                              ),

                              const SizedBox(height: 15),

                              ...item.quantities.entries
    .where((e) => e.value > 0)
    .map(
      (e) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [

            SizedBox(
              width: 80,
              child: Text(
                e.key,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const Icon(
              Icons.arrow_forward,
              size: 16,
              color: Colors.grey,
            ),

            const SizedBox(width: 10),

            Text(
              "${e.value} PCS",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),

          ],
        ),
      ),
    ),

],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [

                            const Text(
                              "Total Models",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            Text(
                              "${items.length}",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),

                          ],
                        ),

                        const SizedBox(height: 15),

                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton.icon(
                            onPressed: () async {

final counterRef = FirebaseFirestore.instance
    .collection("counters")
    .doc("orders");

final counterSnapshot = await counterRef.get();

int lastNumber = 0;

if (counterSnapshot.exists) {
  lastNumber = counterSnapshot["lastNumber"] ?? 0;
}

lastNumber++;

await counterRef.set(
  {
    "lastNumber": lastNumber,
  },
  SetOptions(merge: true),
);
  final user = FirebaseAuth.instance.currentUser;

  // Resolve the dealer without assuming the document ID equals the
  // Firebase Auth UID (Admin dealer documents use auto-generated IDs).
  // Never crash here: a missing dealer shows an error instead.
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

  final dealerData = dealerDoc.data() ?? <String, dynamic>{};

  debugPrint("ORDER UID : ${user?.uid}");
debugPrint("ORDER MOBILE : ${user?.phoneNumber}");

final orderRef = FirebaseFirestore.instance
    .collection("orders")
    .doc();

await orderRef.set({

  "dealerMobile": user?.phoneNumber ?? "",

  "dealerUid": user?.uid ?? "",
  "dealerName": dealerData["firmName"],

"dealerCity": dealerData["city"],
  "orderDocId": orderRef.id,

  "orderNo":
    "EH-${DateFormat("yyyyMMdd").format(DateTime.now())}-${lastNumber.toString().padLeft(4, '0')}",

  "date": DateFormat(
    "dd-MM-yyyy",
  ).format(DateTime.now()),

  "time": DateFormat(
    "hh:mm a",
  ).format(DateTime.now()),

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
    "Order Submitted\nOrder No : EH-${DateFormat("yyyyMMdd").format(DateTime.now())}-${lastNumber.toString().padLeft(4, '0')}",
  ),
),
  );

  setState(() {});

},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(15),
                              ),
                            ),
                            icon: const Icon(Icons.send),
                            label: const Text(
                              "SUBMIT ORDER",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                      ],
                    ),
                  ),
                ),

              ],
            ),
    );
  }
}