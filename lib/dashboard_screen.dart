import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'place_order_screen.dart';
import 'my_orders_screen.dart';
import 'contact_us_screen.dart';
import 'profile_screen.dart';
import 'favourite_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("dealers")
            .doc(user!.uid)
            .snapshots(),

        builder: (context, snapshot) {

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(
              child: Text(
                "Dealer Not Found",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          final dealer =
              snapshot.data!.data()
                  as Map<String, dynamic>;
                            return Column(
            children: [

              // ================= HEADER =================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  20,
                  45,
                  20,
                  18,
                ),

                decoration: const BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),

                child: const Center(
                  child: Text(
                    "ELECTRA HARDWARE",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // =============== DEALER DETAILS ===============

              Align(
                alignment: Alignment.centerLeft,

                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      Text(
                        dealer["firmName"] ?? "",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "📍 ${dealer["city"]}, ${dealer["state"]}",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "📄 GSTIN : ${dealer["gst"]}",
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black54,
                        ),
                      ),

                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),
                            Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),

                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 1.08,

                    children: [

                      dashboardCard(
                        context,
                        Icons.shopping_cart_outlined,
                        "Place Order",
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const PlaceOrderScreen(),
                            ),
                          );
                        },
                      ),

                      dashboardCard(
                        context,
                        Icons.inventory_2_outlined,
                        "My Orders",
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const MyOrdersScreen(),
                            ),
                          );
                        },
                      ),

                      dashboardCard(
                        context,
                        Icons.account_balance_wallet_outlined,
                        "Ledger",
                        () {},
                      ),

                      dashboardCard(
  context,
  Icons.favorite_border,
  "Favourite",
  () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FavouriteScreen(),
      ),
    );
  },
),

                      dashboardCard(
  context,
  Icons.person_outline,
  "Profile",
  () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProfileScreen(),
      ),
    );
  },
),

                      dashboardCard(
  context,
  Icons.support_agent,
  "Contact Us",
  () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>  ContactUsScreen(),
      ),
    );
  },
),

                    ],
                  ),
                ),
              ),

            ],
          );
                  },
      ),
    );
  }

  static Widget dashboardCard(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 5,
      color: Colors.white,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 46,
              color: Colors.red,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}