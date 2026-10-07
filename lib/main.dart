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

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _progressController;

  @override
  void initState() {
    super.initState();

    // Thin glowing progress line animates across the 2-3s splash window.
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..forward();

    Timer(const Duration(milliseconds: 2800), () async {
      final next = await _resolveInitialRoute();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, __, ___) => next,
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
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
    try {
      if (await PinService.hasPin()) {
        return const PinScreen(mode: PinMode.unlock);
      }

      await FirebaseAuth.instance.signOut();
      DealerService.clearSession();
    } catch (_) {
      // Never get stuck on the splash: fall back to Dealer Login.
    }
    return const LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Same premium backdrop as the Dealer Login screen.
          Image.asset(
            'assets/login_background.png',
            fit: BoxFit.cover,
          ),
          Container(
            color: Colors.black.withValues(alpha: 0.55),
          ),
          // Subtle premium loading line near the bottom.
          Positioned(
            left: 56,
            right: 56,
            bottom: 72,
            child: AnimatedBuilder(
              animation: _progressController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _SplashProgressPainter(
                    progress: _progressController.value,
                  ),
                  size: const Size(double.infinity, 4),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Thin glowing gold progress line for the splash screen.
class _SplashProgressPainter extends CustomPainter {
  final double progress;

  _SplashProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final w = size.width;

    // Track (unchanged).
    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, cy), Offset(w, cy), track);

    if (progress <= 0) return;
    final px = (w * progress).clamp(0.0, w);

    // 1. Soft ambient gold glow around the progress line.
    final ambient = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
      ..color = const Color(0xFFE0B65C).withValues(alpha: 0.35);
    canvas.drawLine(Offset(0, cy), Offset(px, cy), ambient);

    // 2. Core gold progress line (tighter glow than before).
    final core = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..shader = const LinearGradient(
        colors: [Color(0xFF8A6A2F), Color(0xFFE0B65C)],
      ).createShader(
        Rect.fromLTWH(0, 0, px, size.height),
      );
    canvas.drawLine(
      Offset(0, cy),
      Offset(px, cy),
      core,
    );

    // 3. Bright shimmer highlight traveling left to right
    // at the head of the progress line.
    final shimmer = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFF3D6).withValues(alpha: 0.85),
          const Color(0xFFE0B65C).withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(center: Offset(px, cy), radius: 14),
      );
    canvas.drawCircle(Offset(px, cy), 14, shimmer);
  }

  @override
  bool shouldRepaint(covariant _SplashProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}














