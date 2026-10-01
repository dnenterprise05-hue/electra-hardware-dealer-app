import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pin_screen.dart';
import 'services/dealer_service.dart';
import 'services/favourite_service.dart';
import 'theme/lux_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final codeController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  // UI-only: the app has no remember-me persistence today, so this
  // checkbox is visual only and is never stored anywhere.
  bool _rememberMe = false;

  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    // Subtle premium entry: card fades and rises into place.
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.045),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _anim.forward();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: LuxColors.cardElevated,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> login() async {
    final rawCode = codeController.text.trim();
    final password = passwordController.text;

    if (rawCode.isEmpty || password.isEmpty) {
      _showError("Enter Dealer Code and Password");
      return;
    }

    setState(() {
      isLoading = true;
    });

    // Canonical code ("EH 0001") -> deterministic login email.
    // The password is verified by Firebase Auth only; it is never
    // stored in Firestore, never logged and never printed.
    final canonicalCode = DealerService.normalizeDealerCode(rawCode);
    final loginEmail = DealerService.loginEmailForCode(canonicalCode);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: loginEmail,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      // Never reveal whether the code or the password was wrong.
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential' ||
          e.code == 'invalid-email') {
        _showError("Invalid Dealer Code or Password");
      } else {
        _showError(
            "Could not connect. Please check your connection and try again.");
      }
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      _showError(
          "Could not connect. Please check your connection and try again.");
      return;
    }

    // Signed in: resolve the dealer by the actual dealer document.
    // Dealer documents use auto-generated IDs, so the document ID can
    // NOT be assumed to equal the Firebase Auth UID.
    // A Firestore/network failure must never authorize the dealer.
    bool dealerLookupFailed = false;
    DocumentSnapshot<Map<String, dynamic>>? dealerDoc;
    try {
      dealerDoc = await DealerService.findDealerByCode(canonicalCode);
    } catch (_) {
      dealerLookupFailed = true;
    }

    if (!mounted) return;

    if (dealerLookupFailed || dealerDoc == null) {
      // No dealer for this code, or lookup failed: do not allow
      // proceeding to the Dashboard. Sign out so no stray session
      // remains behind. Do not reveal which of the two happened.
      await FirebaseAuth.instance.signOut();
      DealerService.clearSession();

      if (!mounted) return;
      setState(() {
        isLoading = false;
      });

      _showError(
        dealerLookupFailed
            ? "Could not verify dealer. Please check your connection and try again."
            : "Invalid Dealer Code or Password",
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
        isLoading = false;
      });

      _showError(
        "Your dealer account is inactive. Please contact Electra Hardware.",
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

    await FavouriteService.instance.loadFavourites();

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Login Successful"),
      ),
    );

    // First Dealer Code + Password login on this device: create the
    // device PIN before entering the Dashboard. The dealer session
    // (DealerService + favourites) is already established above.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PinScreen(
          mode: PinMode.create,
          dealerCode: canonicalCode,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    codeController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ------------------------- UI -------------------------

  InputDecoration _luxFieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: LuxColors.textMuted, fontSize: 15),
      prefixIcon: Icon(icon, color: LuxColors.gold, size: 22),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withOpacity(0.06),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: LuxColors.gold.withOpacity(0.35),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: LuxColors.gold, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        // Keyboard must NOT resize the Scaffold: the Stack (background
        // image + wall logo) stays pixel-fixed; only the scrollable form
        // below adjusts through manual bottom padding.
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Luxury background — exact existing asset, fixed.
            // NOTE: assets/login_background.png does not exist anywhere
            // in this project (checked sandbox + git history), so the
            // project's real luxury background is used instead.
            Positioned.fill(
              child: Image.asset(
                'assets/images/login_bg.jpg',
                fit: BoxFit.cover,
              ),
            ),
            // Dark translucent overlay for card readability.
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.45)),
            ),

            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    // Manual keyboard avoidance: the background Stack
                    // keeps its full size (fixed image, fixed logo);
                    // only this bottom padding grows so the form can
                    // scroll above the keyboard when needed.
                    padding: EdgeInsets.fromLTRB(
                      24,
                      20,
                      24,
                      20 + MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 40,
                      ),
                      child: Column(
                        children: [
                          // Generous space above the card so the
                          // wall-mounted Electra logo in the background
                          // stays fully visible.
                          const Spacer(flex: 3),
                          FadeTransition(
                            opacity: _fade,
                            child: SlideTransition(
                              position: _slide,
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 360,
                                  ),
                                  child: ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(28),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 18,
                                        sigmaY: 18,
                                      ),
                                      child: Container(
                                        // Premium smoked glass: ~45% black
                                        // + blur, so the luxury background
                                        // stays clearly visible through it
                                        // while text/fields stay readable.
                                        padding:
                                            const EdgeInsets.fromLTRB(
                                                24, 26, 24, 26),
                                        decoration: BoxDecoration(
                                          color: Colors.black
                                              .withOpacity(0.45),
                                          borderRadius:
                                              BorderRadius.circular(
                                                  28),
                                          border: Border.all(
                                            color: LuxColors.gold
                                                .withOpacity(0.35),
                                            width: 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: LuxColors.gold
                                                  .withOpacity(0.16),
                                              blurRadius: 36,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          mainAxisSize:
                                              MainAxisSize.min,
                                          children: [
                                            RichText(
                                              text: const TextSpan(
                                                style: TextStyle(
                                                  fontSize: 32,
                                                  fontWeight:
                                                      FontWeight.w700,
                                                  letterSpacing: 0.5,
                                                ),
                                                children: [
                                                  TextSpan(
                                                    text: 'Dealer ',
                                                    style: TextStyle(
                                                      color:
                                                          Colors.white,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: 'Login',
                                                    style: TextStyle(
                                                      color: LuxColors
                                                          .gold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            const Text(
                                              'Access your Electra Hardware Account',
                                              textAlign:
                                                  TextAlign.center,
                                              style: TextStyle(
                                                color: LuxColors
                                                    .textSecondary,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 28),

                                            // Dealer Code — small label inside
                                            // the field, exactly as in the
                                            // approved reference.
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withOpacity(0.06),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        14),
                                                border: Border.all(
                                                  color: LuxColors.gold
                                                      .withOpacity(0.35),
                                                  width: 1,
                                                ),
                                              ),
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      14, 10, 14, 10),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.store_outlined,
                                                    color:
                                                        LuxColors.gold,
                                                    size: 26,
                                                  ),
                                                  const SizedBox(
                                                      width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisSize:
                                                          MainAxisSize
                                                              .min,
                                                      children: [
                                                        const Text(
                                                          'Dealer Code',
                                                          style:
                                                              TextStyle(
                                                            color: LuxColors
                                                                .textSecondary,
                                                            fontSize:
                                                                12,
                                                          ),
                                                        ),
                                                        TextField(
                                                          controller:
                                                              codeController,
                                                          textCapitalization:
                                                              TextCapitalization
                                                                  .characters,
                                                          style:
                                                              const TextStyle(
                                                            color:
                                                                Colors.white,
                                                            fontSize:
                                                                16,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600,
                                                            letterSpacing:
                                                                1.2,
                                                          ),
                                                          decoration:
                                                              const InputDecoration(
                                                            hintText:
                                                                'EH 0001',
                                                            hintStyle: TextStyle(
                                                                color: LuxColors
                                                                    .textMuted,
                                                                fontSize:
                                                                    15),
                                                            border:
                                                                InputBorder
                                                                    .none,
                                                            isDense:
                                                                true,
                                                            contentPadding:
                                                                EdgeInsets
                                                                    .only(
                                                                        top:
                                                                            2),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 18),

                                            // Password.
                                            TextField(
                                              controller:
                                                  passwordController,
                                              obscureText:
                                                  obscurePassword,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                              ),
                                              decoration:
                                                  _luxFieldDecoration(
                                                hint: 'Password',
                                                icon: Icons
                                                    .lock_outline,
                                                suffixIcon: IconButton(
                                                  icon: Icon(
                                                    obscurePassword
                                                        ? Icons
                                                            .visibility_off_outlined
                                                        : Icons
                                                            .visibility_outlined,
                                                    color: LuxColors
                                                        .textSecondary,
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      obscurePassword =
                                                          !obscurePassword;
                                                    });
                                                  },
                                                ),
                                              ),
                                              onSubmitted: (_) =>
                                                  login(),
                                            ),
                                            const SizedBox(height: 14),

                                            // Remember me + Forgot password.
                                            Row(
                                              children: [
                                                SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: Checkbox(
                                                    value: _rememberMe,
                                                    onChanged:
                                                        (value) {
                                                      setState(() {
                                                        _rememberMe =
                                                            value ??
                                                                false;
                                                      });
                                                    },
                                                    activeColor:
                                                        LuxColors.gold,
                                                    checkColor:
                                                        Colors.black,
                                                    side: BorderSide(
                                                      color: LuxColors
                                                          .gold
                                                          .withOpacity(
                                                              0.6),
                                                    ),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(
                                                                  5),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                const Text(
                                                  'Remember me',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 13.5,
                                                  ),
                                                ),
                                                const Spacer(),
                                                TextButton(
                                                  onPressed: () {
                                                    // No password-reset
                                                    // flow exists in the
                                                    // app; honest
                                                    // guidance only.
                                                    _showError(
                                                      'For password help, please contact Electra Hardware.',
                                                    );
                                                  },
                                                  style: TextButton
                                                      .styleFrom(
                                                    padding:
                                                        EdgeInsets.zero,
                                                    minimumSize:
                                                        Size.zero,
                                                    tapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                  ),
                                                  child: const Text(
                                                    'Forgot password?',
                                                    style: TextStyle(
                                                      color: LuxColors
                                                          .gold,
                                                      fontSize: 13.5,
                                                      fontWeight:
                                                          FontWeight
                                                              .w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 22),

                                            // Login button.
                                            SizedBox(
                                              width: double.infinity,
                                              height: 58,
                                              child: DecoratedBox(
                                                decoration:
                                                    BoxDecoration(
                                                  gradient:
                                                      const LinearGradient(
                                                    colors: [
                                                      Color(
                                                          0xFFE8C87E),
                                                      LuxColors.gold,
                                                      Color(
                                                          0xFFB8863B),
                                                    ],
                                                    begin: Alignment
                                                        .topLeft,
                                                    end: Alignment
                                                        .bottomRight,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius
                                                          .circular(
                                                              16),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: LuxColors
                                                          .gold
                                                          .withOpacity(
                                                              0.35),
                                                      blurRadius: 22,
                                                      offset:
                                                          const Offset(
                                                              0, 8),
                                                    ),
                                                  ],
                                                ),
                                                child: Material(
                                                  color: Colors
                                                      .transparent,
                                                  child: InkWell(
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(
                                                                16),
                                                    onTap: isLoading
                                                        ? null
                                                        : login,
                                                    child: Center(
                                                      child: isLoading
                                                          ? const SizedBox(
                                                              width: 26,
                                                              height:
                                                                  26,
                                                              child:
                                                                  CircularProgressIndicator(
                                                                color: Colors
                                                                    .black,
                                                                strokeWidth:
                                                                    3,
                                                              ),
                                                            )
                                                          : const Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Text(
                                                                  'Login',
                                                                  style:
                                                                      TextStyle(
                                                                    color: Colors
                                                                        .black,
                                                                    fontSize:
                                                                        18,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w800,
                                                                    letterSpacing:
                                                                        0.5,
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                    width:
                                                                        10),
                                                                Icon(
                                                                  Icons
                                                                      .arrow_forward,
                                                                  color: Colors
                                                                      .black,
                                                                  size:
                                                                      22,
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
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const Spacer(flex: 2),

                          // Footer — outside the card, at the bottom.
                          Column(
                            children: [
                              Container(
                                width: 44,
                                height: 2.5,
                                decoration: BoxDecoration(
                                  color: LuxColors.gold,
                                  borderRadius:
                                      BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'D N ENTERPRISE',
                                style: TextStyle(
                                  color: LuxColors.gold,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Manufacturer & Exporter of Premium Hardware Products',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: LuxColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
