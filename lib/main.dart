import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_screen.dart';
import 'pin_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/dealer_service.dart';
import 'services/pin_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ElectraApp());
}

class ElectraApp extends StatelessWidget {
  const ElectraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          child: child!,
        );
      },      debugShowCheckedModeBanner: false,
      title: 'Electra Hardware Connect',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () async {
      final next = await _resolveInitialRoute();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => next,
        ),
      );
    });
  }

  /// Route resolution on app start.
  ///
  /// If a device PIN exists, the dealer unlocks with the PIN screen.
  /// The PIN screen re-verifies the persisted Firebase Auth session
  /// (dealer-document lookup + isActive check) before the Dashboard,
  /// so a stale session or an inactive dealer can never slip through.
  ///
  /// If no PIN exists, any stray persisted session is dropped and
  /// Dealer Code + Password login is required. No new Firebase user is
  /// ever created here and the dealer documents are never modified.
  Future<Widget> _resolveInitialRoute() async {
    if (await PinService.hasPin()) {
      return const PinScreen(mode: PinMode.unlock);
    }

    await FirebaseAuth.instance.signOut();
    DealerService.clearSession();
    return const LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hardware,
              color: Colors.red,
              size: 90,
            ),
            SizedBox(height: 20),
            Text(
              "ELECTRA HARDWARE",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "CONNECT",
              style: TextStyle(
                color: Colors.red,
                fontSize: 18,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}














