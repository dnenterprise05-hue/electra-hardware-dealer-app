import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Dealer identity resolution for the Dealer APK.
///
/// The Admin Panel creates dealer documents with auto-generated Firestore
/// document IDs, so the APK must NOT assume `dealers/{authUID}`.
/// After OTP sign-in, the dealer is resolved by the authenticated
/// (normalized 10-digit) mobile number instead.
///
/// This lookup is strictly read-only: it never creates, migrates,
/// renames or deletes dealer documents.
class DealerService {
  DealerService._();

  /// In-memory session for the currently signed-in dealer.
  /// Populated once after successful OTP verification + dealer lookup.
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

  /// Finds the dealer document by normalized 10-digit mobile number.
  /// Returns null when no dealer exists for the number.
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
