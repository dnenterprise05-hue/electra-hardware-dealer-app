import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pinput/pinput.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import 'services/dealer_service.dart';
import 'services/favourite_service.dart';
import 'services/pin_service.dart';

/// Which job this screen performs.
enum PinMode {
  /// After the first Dealer Code + Password login: set the device PIN.
  create,

  /// On subsequent app opens: unlock with the device PIN.
  unlock,
}

/// Outcome of restoring the dealer session during PIN unlock.
enum _SessionRestoreOutcome {
  /// Session valid: dealer found and isActive == true, and the dealer
  /// matches the stored PIN owner.
  ok,

  /// The Firebase session belongs to a different dealer than the one
  /// the stored PIN was created for. Never open the Dashboard.
  ownerMismatch,

  /// Session missing/invalid, dealer not found/inactive, or a transient
  /// failure (e.g. network). Route to password login.
  failed,
}

/// 4-digit device-PIN screen.
///
/// [PinMode.create] runs once after a successful Dealer Code + Password
/// login and saves the PIN to Keystore-backed secure storage, then
/// enters the Dashboard.
///
/// [PinMode.unlock] gates app entry behind the saved PIN. A correct PIN
/// does NOT by itself grant access: the persisted Firebase Auth session
/// is re-verified (dealer-document lookup + `isActive == true`) and only
/// then is the Dashboard entered. A missing/invalid session or an
/// inactive dealer falls back to Dealer Code + Password login.
///
/// The PIN value is never logged, never printed and never appears in
/// error messages.
class PinScreen extends StatefulWidget {
  final PinMode mode;

  /// Canonical dealer code ("EH 0001") - the PIN owner in create mode,
  /// display-only in unlock mode (loaded from secure storage when empty).
  final String dealerCode;

  const PinScreen({
    super.key,
    required this.mode,
    this.dealerCode = '',
  });

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  // Unlock mode: single entry field.
  final _pinController = TextEditingController();

  // Create mode: enter + confirm fields.
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _confirmPinFocusNode = FocusNode();

  bool _busy = false;
  String? _error;
  int _failedAttempts = 0;
  bool _lockedOut = false;
  String _ownerCode = '';

  static const int _maxAttempts = 5;

  bool get _isCreate => widget.mode == PinMode.create;

  @override
  void initState() {
    super.initState();
    _ownerCode = widget.dealerCode;
    if (!_isCreate && _ownerCode.isEmpty) {
      PinService.pinOwnerCode().then((code) {
        if (!mounted) return;
        setState(() {
          _ownerCode = code ?? '';
        });
      });
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    _confirmPinFocusNode.dispose();
    super.dispose();
  }

  void _setError(String? message) {
    if (!mounted) return;
    setState(() {
      _error = message;
    });
  }

  // ------------------------- UNLOCK -------------------------

  Future<void> _submitUnlock() async {
    if (_busy) return;

    final pin = _pinController.text.trim();
    if (!PinService.isValidPinFormat(pin)) {
      _setError('Enter your 4-digit PIN.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final matches = await PinService.verifyPin(pin);
    if (!mounted) return;

    if (!matches) {
      _failedAttempts++;
      _pinController.clear();
      setState(() {
        _busy = false;
        if (_failedAttempts >= _maxAttempts) {
          _lockedOut = true;
          _error = 'Too many incorrect attempts.';
        } else {
          // Generic message - never hints at the real PIN.
          _error = 'Incorrect PIN. Please try again.';
        }
      });
      return;
    }

    // PIN correct: re-verify the Firebase session + dealer before
    // entering the Dashboard. The PIN alone never authorizes access.
    final outcome = await _restoreSession();
    if (!mounted) return;
    setState(() {
      _busy = false;
    });

    switch (outcome) {
      case _SessionRestoreOutcome.ok:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const DashboardScreen(),
          ),
        );
      case _SessionRestoreOutcome.ownerMismatch:
        // The PIN belongs to another dealer account: the PIN and the
        // session have already been cleared inside _restoreSession.
        // Force Dealer Code + Password login with a safe message.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This PIN belongs to another dealer account. Please login again.',
            ),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const LoginScreen(),
          ),
        );
      case _SessionRestoreOutcome.failed:
        // Session missing/invalid or dealer not verifiable (incl.
        // inactive): force Dealer Code + Password login.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Session expired. Please login with Dealer Code and Password.',
            ),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const LoginScreen(),
          ),
        );
    }
  }

  /// Restores the dealer session from the persisted Firebase Auth user.
  /// Re-resolves the dealer document by code and enforces
  /// `isActive == true`.
  ///
  /// Also enforces the PIN-owner binding: the securely stored PIN-owner
  /// dealer code must match the dealer resolved from the Firebase
  /// session. On mismatch the PIN, the Firebase session and the
  /// in-memory dealer session are all cleared and
  /// [_SessionRestoreOutcome.ownerMismatch] is returned, so the
  /// Dashboard is never opened for the wrong dealer.
  ///
  /// A network failure returns [_SessionRestoreOutcome.failed] WITHOUT
  /// signing out so a transient blip never destroys the session or the
  /// device PIN.
  Future<_SessionRestoreOutcome> _restoreSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _SessionRestoreOutcome.failed;

    final code = DealerService.dealerCodeFromLoginEmail(user.email);
    if (code.isEmpty) {
      await FirebaseAuth.instance.signOut();
      DealerService.clearSession();
      return _SessionRestoreOutcome.failed;
    }

    // PIN-owner binding: the PIN may only unlock the session of the
    // dealer it was created for. A missing/unreadable owner code is
    // treated as a mismatch — the safe fallback is password login.
    final ownerCode = await PinService.pinOwnerCode();
    if (ownerCode == null || ownerCode.isEmpty || ownerCode != code) {
      await FirebaseAuth.instance.signOut();
      DealerService.clearSession();
      await PinService.clearPin();
      return _SessionRestoreOutcome.ownerMismatch;
    }

    try {
      final dealerDoc = await DealerService.findDealerByCode(code);
      final dealerData = dealerDoc?.data();
      if (dealerDoc == null ||
          dealerData == null ||
          dealerData['isActive'] != true) {
        await FirebaseAuth.instance.signOut();
        DealerService.clearSession();
        return _SessionRestoreOutcome.failed;
      }
      DealerService.setSession(dealerDoc.id, dealerData);
      await FavouriteService.instance.loadFavourites();
      return _SessionRestoreOutcome.ok;
    } catch (_) {
      return _SessionRestoreOutcome.failed;
    }
  }

  Future<void> _forgotPin() async {
    // No OTP anywhere: delete the device PIN and return to
    // Dealer Code + Password. A new PIN is created after that login.
    await PinService.clearPin();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  void _goToPasswordLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  // ------------------------- CREATE -------------------------

  Future<void> _submitCreate() async {
    if (_busy) return;

    final pin = _newPinController.text.trim();
    final confirm = _confirmPinController.text.trim();

    if (!PinService.isValidPinFormat(pin)) {
      _setError('PIN must be exactly 4 digits.');
      return;
    }
    if (pin != confirm) {
      _newPinController.clear();
      _confirmPinController.clear();
      _setError("PINs do not match. Please try again.");
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await PinService.savePin(pin, widget.dealerCode);
    } catch (_) {
      // Secure storage unavailable: continue to the Dashboard on the
      // valid password session; next launch falls back to password
      // login since no PIN was saved.
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save PIN securely on this device.'),
        ),
      );
      return;
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const DashboardScreen(),
      ),
    );
  }

  // ------------------------- UI -------------------------

  @override
  Widget build(BuildContext context) {
    // Premium dark theme matching the Dealer Login screen.
    // Layout, PIN mechanism, validation and auth logic are unchanged.
    final defaultPinTheme = PinTheme(
      width: 46,
      height: 46,
      textStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF171513).withValues(alpha: 0.72),
        border: Border.all(
          color: const Color(0xFFD8B36A).withValues(alpha: 0.35),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(
          color: const Color(0xFFD8B36A),
          width: 1.5,
        ),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(
          color: const Color(0xFFD8B36A).withValues(alpha: 0.55),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
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
          // Full-screen vertical centering, same principle as the
          // finalized Dealer Login: the whole group is one block whose
          // center aligns with the screen center. Fixed anchor: the
          // keyboard overlays instead of shifting the group.
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Column(
                      children: [
                      Text(
                      _isCreate ? 'Set Login PIN' : 'Welcome Back',
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (!_isCreate && _ownerCode.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _ownerCode,
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFFC5B9AB),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      _isCreate
                          ? 'Create a PIN for quick and secure login.'
                          : 'Enter your 4-digit PIN',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            const Color(0xFFC5B9AB),
                      ),
                    ),
                    const SizedBox(height: 28),

                    if (_isCreate) ...[
                      const Align(
                        alignment: Alignment.center,
                        child: Text(
                          'Enter PIN',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Pinput(
                        length: 4,
                        controller: _newPinController,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        // Do not let Pinput unfocus/close the keyboard on
                        // completion: its internal unfocus races the focus
                        // move to Confirm PIN and kills it on device.
                        closeKeyboardWhenCompleted: false,
                        defaultPinTheme: defaultPinTheme,
                        focusedPinTheme: focusedPinTheme,
                        submittedPinTheme: submittedPinTheme,
                        onCompleted: (_) {
                          // Defer until the current input transaction has
                          // finished, then move focus explicitly.
                          WidgetsBinding.instance
                              .addPostFrameCallback((_) {
                            if (!mounted) return;
                            FocusScope.of(context)
                                .requestFocus(_confirmPinFocusNode);
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      const Align(
                        alignment: Alignment.center,
                        child: Text(
                          'Confirm PIN',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Pinput(
                        length: 4,
                        controller: _confirmPinController,
                        focusNode: _confirmPinFocusNode,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        defaultPinTheme: defaultPinTheme,
                        focusedPinTheme: focusedPinTheme,
                        submittedPinTheme: submittedPinTheme,
                        onSubmitted: (_) => _submitCreate(),
                      ),
                    ] else ...[
                      Pinput(
                        length: 4,
                        controller: _pinController,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        defaultPinTheme: defaultPinTheme,
                        focusedPinTheme: focusedPinTheme,
                        submittedPinTheme: submittedPinTheme,
                        onCompleted: (_) => _submitUnlock(),
                      ),
                    ],

                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFE57373),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _busy
                            ? null
                            : (_isCreate ? _submitCreate : _submitUnlock),
                        style: ElevatedButton.styleFrom(
                          elevation: 8,
                          shadowColor: const Color(0xFFD6A94D)
                              .withValues(alpha: 0.25),
                          backgroundColor: const Color(0xFFDDB45F),
                          foregroundColor: const Color(0xFF17120D),
                          disabledBackgroundColor:
                              const Color(0xFF806C48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: _busy
                            ? const SizedBox(
                                width: 23,
                                height: 23,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.3,
                                  color: Color(0xFF17120D),
                                ),
                              )
                            : Text(
                                _isCreate ? 'SAVE PIN' : 'CONTINUE',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),

                    if (!_isCreate) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _busy ? null : _forgotPin,
                        child: const Text(
                          'Forgot PIN?',
                          style: TextStyle(
                            color: Color(0xFFE0B65C),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (_lockedOut) ...[
                        const SizedBox(height: 4),
                        OutlinedButton(
                          onPressed: _goToPasswordLogin,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Color(0xFFE0B65C),
                            side: const BorderSide(
                                color: Color(0xFFE0B65C)),
                          ),
                          child: const Text(
                            'Login with Dealer Code + Password',
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
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
