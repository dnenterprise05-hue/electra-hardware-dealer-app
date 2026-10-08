import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  // Dealer Code as 6 visual boxes with a fixed "EH" prefix:
  // [E][H][d][d][d][d] — only the 4 digit boxes are editable.
  static const int _digitLength = 4;

  final List<TextEditingController> _digitControllers =
      List.generate(_digitLength, (_) => TextEditingController());
  final List<FocusNode> _digitFocusNodes =
      List.generate(_digitLength, (_) => FocusNode());
  final FocusNode _passwordFocusNode = FocusNode();

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
    for (final c in _digitControllers) {
      c.dispose();
    }
    for (final n in _digitFocusNodes) {
      n.dispose();
    }
    _passwordFocusNode.dispose();
    passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (isLoading) return;

    // Fixed "EH" prefix + the 4 entered digits, e.g. "EH0001".
    final digits = _digitControllers.map((c) => c.text).join();
    final rawCode = 'EH$digits';
    final password = passwordController.text;

    if (digits.isEmpty) {
      _showMessage('Enter Dealer Code');
      return;
    }

    if (digits.length < _digitLength) {
      _showMessage('Enter valid Dealer Code');
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

  void _onForgotPassword() {
    // TODO(backend): connect to the dealer password-reset flow once
    // Firebase password provisioning/reset is implemented.
    // No reset API exists today, so this shows guidance and keeps
    // the existing login flow completely untouched.
    _showMessage(
      'To reset your password, please contact Electra Hardware support.',
    );
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
        vertical: 14,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: const Color(0xFFD8B36A).withValues(alpha: 0.35),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Color(0xFFD8B36A),
          width: 1.2,
        ),
      ),
    );
  }

  /// Fixed "EH" prefix box — not editable, not deletable, not focusable.
  Widget _buildFixedPrefixBox(String char) {
    return SizedBox(
      height: 46,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF171513).withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFD8B36A).withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          char,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  /// One editable digit box of the Dealer Code (numbers only).
  Widget _buildDigitBox(int index) {
    return SizedBox(
      height: 46,
      child: Focus(
        onKeyEvent: (node, event) {
          // Backspace on an empty digit box moves to the previous
          // digit box. It never moves into the fixed "EH" boxes.
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              _digitControllers[index].text.isEmpty &&
              index > 0) {
            _digitFocusNodes[index - 1].requestFocus();
            final prevText = _digitControllers[index - 1].text;
            _digitControllers[index - 1].selection = TextSelection(
              baseOffset: 0,
              extentOffset: prevText.length,
            );
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: TextField(
          controller: _digitControllers[index],
          focusNode: _digitFocusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          cursorColor: const Color(0xFFE0B65C),
          inputFormatters: [
            // Numbers only, one digit per box.
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(1),
          ],
          onTap: () {
            // Tapping a filled box selects its digit for easy replace.
            final text = _digitControllers[index].text;
            if (text.isNotEmpty) {
              _digitControllers[index].selection = TextSelection(
                baseOffset: 0,
                extentOffset: text.length,
              );
            }
          },
          onChanged: (value) {
            if (value.isNotEmpty) {
              if (index < _digitLength - 1) {
                // Digit entered -> move to the next digit box.
                _digitFocusNodes[index + 1].requestFocus();
              } else {
                // 4th digit entered -> move to Password.
                _passwordFocusNode.requestFocus();
              }
            }
          },
          onSubmitted: (_) {
            if (index < _digitLength - 1) {
              _digitFocusNodes[index + 1].requestFocus();
            } else {
              _passwordFocusNode.requestFocus();
            }
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF171513).withValues(alpha: 0.72),
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFFD8B36A).withValues(alpha: 0.35),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFD8B36A),
                width: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // Background must stay completely fixed when the keyboard opens:
      // the Scaffold never resizes, so the Stack (background image)
      // keeps its exact size and position.
      resizeToAvoidBottomInset: false,
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

          // EXACT vertical center of the FULL phone screen: the center
          // of this whole group aligns with the center of the display.
          // Positioned.fill makes the full-screen centering explicit
          // (not SafeArea, not content bounds). Fixed anchor: the group
          // never moves when the keyboard opens or closes.
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20),
                  child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 340,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: 0,
sigmaY: 0,
                          ),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(
                              20,
                              18,
                              20,
                              20,
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
                                const SizedBox(height: 6),

                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      left: 2,
                                      bottom: 8,
                                    ),
                                    child: Text(
                                      'Dealer Code',
                                      style: TextStyle(
                                        color: Color(0xFFB8AEA2),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ),

                                // 6 visual boxes: fixed "EH" + 4 digits.
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildFixedPrefixBox('E'),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildFixedPrefixBox('H'),
                                    ),
                                    for (int i = 0;
                                        i < _digitLength;
                                        i++) ...[
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildDigitBox(i),
                                      ),
                                    ],
                                  ],
                                ),

                                const SizedBox(height: 10),

                                TextField(
                                  controller: passwordController,
                                  focusNode: _passwordFocusNode,
                                  obscureText: obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => login(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
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

                                const SizedBox(height: 4),

                                // Forgot Password — tappable, subtle.
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _onForgotPassword,
                                    style: TextButton.styleFrom(
                                      padding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 4,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: Color(0xFFE3B85C),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 10),

                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
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
                ],
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







