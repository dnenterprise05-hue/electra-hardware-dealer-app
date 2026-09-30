import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Device-local 4-digit PIN convenience login for the Dealer APK.
///
/// The PIN is stored ONLY in Android Keystore-backed secure storage
/// (flutter_secure_storage -> EncryptedSharedPreferences). It is never
/// written to Firestore, SharedPreferences, plain-text files or logs,
/// never printed, and never sent anywhere - it is strictly device-local.
///
/// The PIN is only a convenience unlock gate. It is NOT a replacement
/// for the Firebase password: after a correct PIN the existing persisted
/// Firebase Auth session is re-verified (dealer-document lookup +
/// `isActive == true`) before the Dashboard is entered. If that session
/// is missing or invalid, the dealer is sent back to Dealer Code +
/// Password login.
///
/// The PIN is deleted on logout and on "Forgot PIN?".
class PinService {
  PinService._();

  static const _storage = FlutterSecureStorage();

  /// The 4-digit PIN itself.
  static const _pinKey = 'dealer_pin';

  /// Canonical dealer code ("EH 0001") the PIN was created for.
  /// Display-only; session restore always re-derives identity from the
  /// Firebase Auth session, never from this value.
  static const _pinOwnerKey = 'dealer_pin_owner';

  /// True when a usable 4-digit PIN exists on this device.
  /// Storage errors (unavailable Keystore, etc.) are treated as "no PIN"
  /// so the app safely falls back to Dealer Code + Password login.
  static Future<bool> hasPin() async {
    try {
      final pin = await _storage.read(key: _pinKey);
      return pin != null && isValidPinFormat(pin);
    } catch (_) {
      return false;
    }
  }

  /// Saves (or replaces) the device PIN for [dealerCode].
  /// Throws when secure storage is unavailable; callers fall back to
  /// password login in that case.
  static Future<void> savePin(String pin, String dealerCode) async {
    await _storage.write(key: _pinKey, value: pin);
    await _storage.write(key: _pinOwnerKey, value: dealerCode);
  }

  /// Compares [pin] against the stored PIN without ever exposing the
  /// stored value. Returns false on any storage error.
  static Future<bool> verifyPin(String pin) async {
    try {
      final stored = await _storage.read(key: _pinKey);
      return stored != null && stored == pin;
    } catch (_) {
      return false;
    }
  }

  /// Canonical dealer code the current PIN belongs to (display only).
  static Future<String?> pinOwnerCode() async {
    try {
      return await _storage.read(key: _pinOwnerKey);
    } catch (_) {
      return null;
    }
  }

  /// Deletes the device PIN. Called on logout and on "Forgot PIN?".
  /// Never throws.
  static Future<void> clearPin() async {
    try {
      await _storage.delete(key: _pinKey);
      await _storage.delete(key: _pinOwnerKey);
    } catch (_) {
      // Best effort: a leftover PIN must never block password login,
      // and hasPin() treats unreadable storage as "no PIN".
    }
  }

  /// Exactly 4 numeric digits.
  static bool isValidPinFormat(String pin) =>
      RegExp(r'^\d{4}$').hasMatch(pin);
}
