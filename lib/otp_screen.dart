import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pinput/pinput.dart';
import 'dashboard_screen.dart';
import 'services/dealer_service.dart';
import 'services/favourite_service.dart';

class OtpScreen extends StatefulWidget {
  final String verificationId;

  const OtpScreen({
    super.key,
    required this.verificationId,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {

  final otpController = TextEditingController();

  bool loading = false;

  Future<void> verifyOTP() async {

    setState(() {
      loading = true;
    });

    try {

      PhoneAuthCredential credential =
      PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otpController.text.trim(),
      );

      await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      // Resolve the dealer by the authenticated mobile number.
      // The Admin Panel uses auto-generated dealer document IDs, so the
      // document ID can NOT be assumed to equal the Firebase Auth UID.
      // A Firestore/network failure must never authorize the dealer.
      final user = FirebaseAuth.instance.currentUser;

      bool dealerLookupFailed = false;
      DocumentSnapshot<Map<String, dynamic>>? dealerDoc;
      try {
        dealerDoc = await DealerService.findDealerByMobile(
          DealerService.normalizeMobile(user?.phoneNumber),
        );
      } catch (_) {
        dealerLookupFailed = true;
      }

      if (!mounted) return;

      if (dealerLookupFailed || dealerDoc == null) {
        // Unknown number or failed lookup: do not allow proceeding to
        // the Dashboard. Sign out so no stray session remains behind.
        await FirebaseAuth.instance.signOut();
        DealerService.clearSession();

        if (!mounted) return;

        setState(() {
          loading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              dealerLookupFailed
                  ? "Could not verify dealer. Please check your connection and try again."
                  : "Dealer account not found. Please contact Electra Hardware.",
            ),
          ),
        );
        return;
      }

      // Active-dealer gate: only isActive == true may proceed.
      // A missing or false isActive is treated as NOT authorized.
      // The dealer document itself is never modified here.
      final dealerData = dealerDoc.data() ?? <String, dynamic>{};

      if (dealerData["isActive"] != true) {
        await FirebaseAuth.instance.signOut();
        DealerService.clearSession();

        if (!mounted) return;

        setState(() {
          loading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Dealer account is inactive. Please contact Electra Hardware.",
            ),
          ),
        );
        return;
      }

      // Dealer found and active: remember the actual Firestore document ID
      // so every dealer lookup in this session uses it instead of the
      // Auth UID.
      DealerService.setSession(
        dealerDoc.id,
        dealerData,
      );

      debugPrint("UID: ${FirebaseAuth.instance.currentUser?.uid}");
      debugPrint("Mobile: ${FirebaseAuth.instance.currentUser?.phoneNumber}");
      await FavouriteService.instance.loadFavourites();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Login Successful"),
        ),
      );

      // અત્યારે temporary પાછા Login screen પર લઈ જઈએ
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
        ),
      );

    } on FirebaseAuthException catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? "Invalid OTP"),
        ),
      );

    }

    setState(() {
      loading = false;
    });

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify OTP"),
        backgroundColor: Colors.red,
        foregroundColor: const Color(0xFFFFF8EE),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            const Icon(
              Icons.lock,
              size: 90,
              color: Colors.red,
            ),

            const SizedBox(height: 20),

            const Text(
              "Enter OTP",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Pinput(
              controller: otpController,
              length: 6,
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton(

                onPressed: loading ? null : verifyOTP,

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: const Color(0xFFFFF8EE),
                ),

                child: loading
                    ? const CircularProgressIndicator(
                  color: const Color(0xFFFFF8EE),
                )
                    : const Text(
                  "VERIFY OTP",
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
    );
  }
}