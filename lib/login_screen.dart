import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'pin_screen.dart';
import 'services/dealer_service.dart';
import 'services/favourite_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final dealerCodeController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    dealerCodeController.dispose();
    passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (isLoading) return;

    final rawCode = dealerCodeController.text.trim();
    final password = passwordController.text;

    if (rawCode.isEmpty) {
      _showMessage('Enter Dealer Code');
      return;
    }

    if (password.isEmpty) {
      _showMessage('Enter Password');
      return;
    }

    final dealerCode = DealerService.normalizeDealerCode(rawCode);

    if (dealerCode.isEmpty) {
      _showMessage('Enter valid Dealer Code');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final dealerDoc =
          await DealerService.findDealerByCode(dealerCode);

      if (dealerDoc == null) {
        _showMessage('Dealer Code not found');

        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        return;
      }

      final dealerData = dealerDoc.data();

      if (dealerData == null) {
        _showMessage('Dealer information not found');

        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        return;
      }

      if (dealerData['isActive'] != true) {
        _showMessage('Your dealer account is inactive');

        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        return;
      }

      final email = DealerService.loginEmailForCode(dealerCode);

      final credential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        _showMessage('Login failed');

        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        return;
      }

      DealerService.setSession(
        dealerDoc.id,
        dealerData,
      );

      await FavouriteService.instance.loadFavourites();

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PinScreen(
            mode: PinMode.create,
            dealerCode: dealerCode,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          message = 'Invalid Dealer Code or Password';
          break;

        case 'too-many-requests':
          message =
              'Too many login attempts. Please try again later.';
          break;

        case 'network-request-failed':
          message =
              'Network error. Please check your internet connection.';
          break;

        default:
          message = e.message ?? 'Login failed';
      }

      setState(() {
        isLoading = false;
      });

      _showMessage(message);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showMessage('Login failed. Please try again.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1A1714),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color(0xFFB8AEA2),
        fontSize: 14,
      ),
      floatingLabelStyle: const TextStyle(
        color: Color(0xFFE3B85C),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: Icon(
        icon,
        color: const Color(0xFFC8B08A),
        size: 21,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFF171513).withValues(alpha: 0.72),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Color(0xFFD9AD52),
          width: 1.2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Exact luxury background photo.
          Image.asset(
            'assets/login_background.png',
            fit: BoxFit.cover,
          ),

          // Dark cinematic overlay.
          Container(
            color: Colors.black.withValues(alpha: 0.28),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 120),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 430,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: 0,
sigmaY: 0,
                          ),
                          child: Container(
                            padding: EdgeInsets.fromLTRB(
                              25,
                              size.height < 700 ? 24 : 30,
                              25,
                              28,
                            ),
                            decoration: BoxDecoration(
                              // Smoked transparent glass.
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(color: Colors.transparent, width: 0),
                              boxShadow: const [] ,
                            ),
                            child: Column(
                              children: [
                                const SizedBox(height: 8),

                                TextField(
                                  controller: dealerCodeController,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  textInputAction: TextInputAction.next,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  cursorColor: const Color(0xFFE0B65C),
                                  decoration: _inputDecoration(
                                    label: 'Dealer Code',
                                    icon: Icons.badge_outlined,
                                  ),
                                ),

                                const SizedBox(height: 15),

                                TextField(
                                  controller: passwordController,
                                  obscureText: obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => login(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  cursorColor: const Color(0xFFE0B65C),
                                  decoration: _inputDecoration(
                                    label: 'Password',
                                    icon: Icons.lock_outline,
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          obscurePassword =
                                              !obscurePassword;
                                        });
                                      },
                                      icon: Icon(
                                        obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: const Color(0xFFC5B9AB),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 25),

                                SizedBox(
                                  width: double.infinity,
                                  height: 55,
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : login,
                                    style: ElevatedButton.styleFrom(
                                      elevation: 8,
                                      shadowColor: const Color(0xFFD6A94D)
                                          .withValues(alpha: 0.25),
                                      backgroundColor:
                                          const Color(0xFFDDB45F),
                                      foregroundColor:
                                          const Color(0xFF17120D),
                                      disabledBackgroundColor:
                                          const Color(0xFF806C48),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15),
                                      ),
                                    ),
                                    child: isLoading
                                        ? const SizedBox(
                                            width: 23,
                                            height: 23,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 2.3,
                                              color: Color(0xFF17120D),
                                            ),
                                          )
                                        : const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Login',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                              SizedBox(width: 10),
                                              Icon(
                                                Icons.arrow_forward_rounded,
                                                size: 21,
                                              ),
                                            ],
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
                ),
              ),
            ),
          ),

          // Company details stay OUTSIDE the login card.
          Positioned(
            left: 20,
            right: 20,
            bottom: 25,
            child: Column(
              children: [
                const Text(
                  'D N ENTERPRISE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Manufacturer & Exporter of Premium Hardware Products',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFD0C7BC),
                    fontSize: 11.5,
                    letterSpacing: 0.2,
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







