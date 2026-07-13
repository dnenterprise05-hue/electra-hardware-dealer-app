import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'order_details_screen.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text("My Orders"),
        centerTitle: true,
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("orders")
            .orderBy(
              "createdAt",
              descending: true,
            )
            .snapshots(),

        builder: (context, snapshot) {

          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text("No Orders Found"),
            );
          }

          final orders = snapshot.data!.docs.where((doc) {
            final data =
                doc.data() as Map<String, dynamic>;

            return data["dealerUid"] == user?.uid;
          }).toList();

          if (orders.isEmpty) {
            return const Center(
              child: Text(
                "No Orders Found",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: orders.length,

            itemBuilder: (context, index) {

              final data =
                  orders[index].data()
                      as Map<String, dynamic>;

              final products =
                  data["products"] as List;

              final firstProduct =
                  products.first;
                                return Card(
                color: Colors.white,
                elevation: 4,
                shadowColor: Colors.black12,
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),

                child: InkWell(
                  borderRadius: BorderRadius.circular(16),

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderDetailsScreen(
                          order: data,
                        ),
                      ),
                    );
                  },

                  child: Padding(
                    padding: const EdgeInsets.all(15),

                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,

                            children: [
                                                            Text(
                                data["orderNo"] ?? "Order",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                "${data["date"]}",
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Row(
                                children: [

                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 5,
                                    ),

                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade100,
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),

                                    child: Text(
                                      data["status"],
                                      style: TextStyle(
                                        color: Colors.orange.shade900,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 10),

                                  Text(
                                    "${products.length} Model",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),

                                ],
                              ),
                                                          ],
                          ),
                        ),

                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.grey,
                          size: 28,
                        ),

                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}