import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FavouriteItem {
  final String modelNo;
  final String imageUrl;

  FavouriteItem({
    required this.modelNo,
    required this.imageUrl,
  });
}

class FavouriteService extends ChangeNotifier {
  FavouriteService._();

  static final FavouriteService instance = FavouriteService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final List<FavouriteItem> _items = [];

  List<FavouriteItem> get items => _items;

  bool isFavourite(String modelNo) {
    return _items.any(
      (e) => e.modelNo == modelNo,
    );
  }

  Future<void> loadFavourites() async {

    _items.clear();

    final uid = _auth.currentUser?.uid;

    if (uid == null) return;

    final snapshot = await _firestore
        .collection("users")
        .doc(uid)
        .collection("favourites")
        .get();

    for (var doc in snapshot.docs) {

      _items.add(
        FavouriteItem(
          modelNo: doc["modelNo"],
          imageUrl: doc["imageUrl"],
        ),
      );

    }

    notifyListeners();
  }

  Future<void> toggleFavourite({
    required String modelNo,
    required String imageUrl,
  }) async {

    final uid = _auth.currentUser?.uid;

    if (uid == null) return;

    final docRef = _firestore
        .collection("users")
        .doc(uid)
        .collection("favourites")
        .doc(modelNo);

    if (isFavourite(modelNo)) {

      await docRef.delete();

      _items.removeWhere(
        (e) => e.modelNo == modelNo,
      );

    } else {

      await docRef.set({

        "modelNo": modelNo,
        "imageUrl": imageUrl,
        "createdAt":
            FieldValue.serverTimestamp(),

      });

      _items.add(
        FavouriteItem(
          modelNo: modelNo,
          imageUrl: imageUrl,
        ),
      );

    }

    notifyListeners();
  }
}