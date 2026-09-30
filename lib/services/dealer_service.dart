import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Dealer identity resolution for the Dealer APK.
///
/// The Admin Panel creates dealer documents with auto-generated Firestore
/// document IDs, so the APK must NOT assume `dealers/{authUID}`.
/// Dealers sign in with their Dealer Code + Password via Firebase
/// Authentication (Email/Password provider) using a deterministic login
/// email derived from the dealer code. After sign-in, the dealer document
/// is resolved by its stored `dealerCode` ("EH 0001") and only an
/// `isActive == true` dealer may proceed.
///
/// This lookup is strictly read-only: it never creates, migrates,
/// renames or deletes dealer documents, and no password (or hash) is
/// ever stored in Firestore.
class DealerService {
  DealerService._();

  /// In-memory session for the currently signed-in dealer.
  /// Populated once after successful Dealer Code + Password sign-in
  /// and dealer lookup.
  static String? dealerDocId;
  static Map<String, dynamic>? dealerData;

  static void setSession(String docId, Map<String, dynamic> data) {
    dealerDocId = docId;
    dealerData = data;
  }

  static void clearSession() {
    dealerDocId = null;
    dealerData = null;
  }

  /// Normalizes a phone number to the 10-digit form used in Admin dealer
  /// records. Firebase Auth returns "+91XXXXXXXXXX"; Admin stores
  /// "XXXXXXXXXX". Keeps the last 10 digits so other country codes and
  /// formatting (spaces, dashes) are handled too.
  static String normalizeMobile(String? phone) {
    if (phone == null) return '';
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 10) {
      return digits.substring(digits.length - 10);
    }
    return digits;
  }

  /// Strict 10-digit normalization for order writes.
  /// Removes all non-digits; keeps the last 10 digits when longer.
  /// Returns null when fewer than 10 digits remain (invalid number).
  static String? normalizeMobile10(String? phone) {
    if (phone == null) return null;
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 10) return null;
    return digits.substring(digits.length - 10);
  }

  /// Finds the dealer document by normalized 10-digit mobile number.
  /// Returns null when no dealer exists for the number.
  /// (Kept for order/cart mobile fallbacks; login now uses dealer code.)
  static Future<DocumentSnapshot<Map<String, dynamic>>?> findDealerByMobile(
    String mobile10,
  ) async {
    if (mobile10.isEmpty) return null;
    final query = await FirebaseFirestore.instance
        .collection('dealers')
        .where('mobile', isEqualTo: mobile10)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return query.docs.first;
  }

  /// Normalizes dealer-code input to the canonical Admin Panel format
  /// "EH 0001". Accepts "EH 0001", "eh0001", "EH0001", "eh 1", etc.
  /// Input that does not look like an EH code is returned trimmed and
  /// upper-cased so the lookup simply finds nothing.
  static String normalizeDealerCode(String? code) {
    if (code == null) return '';
    final compact = code.replaceAll(RegExp(r'[^0-9a-zA-Z]'), '').toUpperCase();
    final m = RegExp(r'^EH(\d+)$').firstMatch(compact);
    if (m != null) {
      return 'EH ${m.group(1)!.padLeft(4, '0')}';
    }
    return code.trim().toUpperCase();
  }

  /// Deterministic Firebase Auth login email derived from the canonical
  /// dealer code, e.g. "EH 0001" -> "eh0001@dealers.electra.local".
  /// No extra Firestore field is needed and the Admin Panel's dealer-code
  /// generation stays untouched. The password itself is stored only as a
  /// Firebase Auth credential hash - never in Firestore, never logged.
  static String loginEmailForCode(String canonicalCode) {
    final compact =
        canonicalCode.replaceAll(RegExp(r'[^0-9a-zA-Z]'), '').toLowerCase();
    return '$compact@dealers.electra.local';
  }

  /// Reverse of [loginEmailForCode]: recovers the canonical dealer code
  /// from a persisted Firebase Auth session so the dealer can be
  /// re-verified on app restart. Returns '' for non-dealer emails.
  static String dealerCodeFromLoginEmail(String? email) {
    if (email == null) return '';
    final local = email.split('@').first.toUpperCase();
    final m = RegExp(r'^EH(\d+)$').firstMatch(local);
    if (m != null) {
      return 'EH ${m.group(1)!.padLeft(4, '0')}';
    }
    return '';
  }

  /// Finds the dealer document by canonical dealer code ("EH 0001").
  /// Returns null when no dealer exists for the code.
  static Future<DocumentSnapshot<Map<String, dynamic>>?> findDealerByCode(
    String canonicalCode,
  ) async {
    if (canonicalCode.isEmpty) return null;
    final query = await FirebaseFirestore.instance
        .collection('dealers')
        .where('dealerCode', isEqualTo: canonicalCode)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return query.docs.first;
  }

  /// One-shot fetch of the signed-in dealer's document.
  /// Prefers the document ID resolved at login; falls back to a fresh
  /// mobile-based lookup. Returns null when the dealer cannot be resolved.
  static Future<DocumentSnapshot<Map<String, dynamic>>?> getDealerDoc() async {
    final id = dealerDocId;
    if (id != null && id.isNotEmpty) {
      return FirebaseFirestore.instance.collection('dealers').doc(id).get();
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return findDealerByMobile(normalizeMobile(user.phoneNumber));
  }

  /// GST display that tolerates the current Admin schema (`gstNumber`)
  /// while keeping compatibility with the legacy APK field (`gst`).
  static String gstOf(Map<String, dynamic> dealer) {
    final value = dealer['gstNumber'] ?? dealer['gst'];
    return value?.toString() ?? '';
  }

  /// "City, State" skipping missing parts
  /// (Admin records may not have city/state).
  static String locationOf(Map<String, dynamic> dealer) {
    final parts = <String>[];
    for (final key in ['city', 'state']) {
      final v = dealer[key]?.toString().trim() ?? '';
      if (v.isNotEmpty) parts.add(v);
    }
    return parts.join(', ');
  }

  /// "address, city, state" skipping missing parts.
  static String addressOf(Map<String, dynamic> dealer) {
    final parts = <String>[];
    for (final key in ['address', 'city', 'state']) {
      final v = dealer[key]?.toString().trim() ?? '';
      if (v.isNotEmpty) parts.add(v);
    }
    return parts.join(', ');
  }
}
