import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'pin_screen.dart';
import 'theme/lux_theme.dart';

// ================================================================
// FORCE PASSWORD CHANGE SCREEN (Dealer App)
// ================================================================
//
// Shown immediately after login when the dealer document has
// `mustChangePassword: true` (initial/temporary password).
// The dealer cannot reach the PIN setup or dashboard until they
// set their own password.
//
// On success:
//   1. Firebase Auth password is updated.
//   2. `mustChangePassword` is cleared on the dealer document.
//   3. Navigation continues to PIN creation.
//
// Premium dark-luxury theme: charcoal background, ivory text,
// gold accents — consistent with Dealer Login and PIN screens.

class ForcePasswordChangeScreen extends StatefulWidget {
  final String dealerDocId;
  final String dealerCode;

  const ForcePasswordChangeScreen({
    super.key,
    required this.dealerDocId,
    required this.dealerCode,
  });

  @override
  State<ForcePasswordChangeScreen> createState() =>
      _ForcePasswordChangeScreenState();
}

class _ForcePasswordChangeScreenState
    extends State<ForcePasswordChangeScreen> {
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color(0xFFB9AC93),
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
          color: Color(0xFFE3B85C),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Color(0xFFE57373),
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Color(0xFFE57373),
          width: 1.5,
        ),
      ),
    );
  }

  Future<void> _save() async {
    final newPassword = _newController.text.trim();
    final confirm = _confirmController.text.trim();

    if (newPassword.length < 6) {
      setState(() {
        _error = 'Password must be at least 6 characters.';
      });
      return;
    }
    if (newPassword != confirm) {
      setState(() {
        _error = 'Passwords do not match.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Not signed in. Please login again.');
      }

      await user.updatePassword(newPassword);

      // Clear the flag so this screen doesn't show again.
      await FirebaseFirestore.instance
          .collection('dealers')
          .doc(widget.dealerDocId)
          .update({
        'mustChangePassword': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PinScreen(
            mode: PinMode.create,
            dealerCode: widget.dealerCode,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _saving = false;
        _error = e.code == 'requires-recent-login'
            ? 'Session expired. Please logout and login again.'
            : (e.message ?? 'Could not update password.');
      });
    } catch (e) {
      setState(() {
        _saving = false;
        _error = 'Could not update password: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuxColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Gold icon in ring
                  Center(
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: LuxColors.goldBorder,
                          width: 1.5,
                        ),
                        color: LuxColors.goldTint,
                      ),
                      child: const Icon(
                        Icons.lock_reset_rounded,
                        size: 40,
                        color: LuxColors.gold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Set New Password',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: LuxColors.textPrimary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You are using a temporary password. '
                    'Please create your own secure password to continue.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: LuxColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _newController,
                    obscureText: _obscureNew,
                    enableSuggestions: false,
                    autocorrect: false,
                    style: const TextStyle(
                      color: LuxColors.textPrimary,
                    ),
                    decoration: _inputDecoration(
                      label: 'New Password',
                      icon: Icons.lock_outline_rounded,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscureNew = !_obscureNew;
                          });
                        },
                        icon: Icon(
                          _obscureNew
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFFC8B08A),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _confirmController,
                    obscureText: _obscureConfirm,
                    enableSuggestions: false,
                    autocorrect: false,
                    onSubmitted: (_) {
                      if (!_saving) _save();
                    },
                    style: const TextStyle(
                      color: LuxColors.textPrimary,
                    ),
                    decoration: _inputDecoration(
                      label: 'Confirm New Password',
                      icon: Icons.lock_outline_rounded,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscureConfirm = !_obscureConfirm;
                          });
                        },
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFFC8B08A),
                        ),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE57373)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE57373)
                              .withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFE57373),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LuxColors.gold,
                        foregroundColor: const Color(0xFF1A1408),
                        disabledBackgroundColor:
                            LuxColors.gold.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Color(0xFF1A1408),
                              ),
                            )
                          : const Text('Set Password & Continue'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Minimum 6 characters. Choose something memorable.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: LuxColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
