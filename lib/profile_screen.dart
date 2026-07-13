import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),

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
              child: Text("Dealer Not Found"),
            );
          }

          final dealer =
              snapshot.data!.data()
                  as Map<String, dynamic>;
                            return SingleChildScrollView(
            padding: const EdgeInsets.all(16),

            child: Column(
              children: [

                Card(
                  color: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),

                  child: Padding(
                    padding: const EdgeInsets.all(18),

                    child: Column(
                      children: [

                        profileTile(
                          Icons.business,
                          "Firm Name",
                          dealer["firmName"] ?? "",
                        ),

                        const Divider(),

                        profileTile(
                          Icons.badge,
                          "Dealer Code",
                          dealer["dealerCode"] ?? "",
                        ),

                        const Divider(),

                        profileTile(
                          Icons.call,
                          "Mobile",
                          dealer["mobile"] ?? "",
                        ),

                        const Divider(),

                        profileTile(
                          Icons.email,
                          "Email",
                          dealer["email"] ?? "",
                        ),

                        const Divider(),

                        profileTile(
                          Icons.receipt_long,
                          "GST Number",
                          dealer["gst"] ?? "",
                        ),

                        const Divider(),

                        profileTile(
                          Icons.location_on,
                          "Address",
                          "${dealer["address"]}, ${dealer["city"]}, ${dealer["state"]}",
                        ),

                        const Divider(),

                        Row(
                          children: [

                            const Icon(
                              Icons.verified,
                              color: Colors.green,
                            ),

                            const SizedBox(width: 12),

                            const Text(
                              "Status",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const Spacer(),

                            Text(
                              dealer["isActive"] == true
                                  ? "Active"
                                  : "Inactive",
                              style: TextStyle(
                                color: dealer["isActive"] == true
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),

                          ],
                        ),
                                              ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();

                      Navigator.of(context).popUntil(
                        (route) => route.isFirst,
                      );
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text(
                      "Logout",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),

              ],
            ),
          );
        },
      ),
    );
  }

  Widget profileTile(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Icon(
            icon,
            color: Colors.red,
            size: 24,
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),

              ],
            ),
          ),

        ],
      ),
    );
  }
}