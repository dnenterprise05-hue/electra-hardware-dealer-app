import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      final user = FirebaseAuth.instance.currentUser;
      final dealerDoc = await DealerService.findDealerByMobile(
        DealerService.normalizeMobile(user?.phoneNumber),
      );

      if (!mounted) return;

      if (dealerDoc == null) {
        // Unknown number: do not allow proceeding to the Dashboard.
        // Sign out so no stray authenticated session remains behind.
        await FirebaseAuth.instance.signOut();
        DealerService.clearSession();

        if (!mounted) return;

        setState(() {
          loading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Dealer Not Found. Please contact Electra Hardware to register your number.",
            ),
          ),
        );
        return;
      }

      // Dealer found: remember the actual Firestore document ID so every
      // dealer lookup in this session uses it instead of the Auth UID.
      DealerService.setSession(
        dealerDoc.id,
        dealerDoc.data() ?? <String, dynamic>{},
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
        foregroundColor: Colors.white,
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
                  foregroundColor: Colors.white,
                ),

                child: loading
                    ? const CircularProgressIndicator(
                  color: Colors.white,
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