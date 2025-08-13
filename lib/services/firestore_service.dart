import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wishlist_app/services/cloudinary_service.dart';
import 'package:wishlist_app/models/sort_options.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _cloudinaryService = CloudinaryService();
  final String _wishlistsCollection = 'wishlists';
  final String _usersCollection = 'users';

  Stream<QuerySnapshot> getWishlists(String userId) {
    return _firestore
        .collection(_wishlistsCollection)
        .where('ownerId', isEqualTo: userId)
        .snapshots();
  }

  Future<DocumentSnapshot> getWishlist(String wishlistId) {
    return _firestore.collection(_wishlistsCollection).doc(wishlistId).get();
  }

  Future<void> saveWishlist({
    required String name,
    required bool isPrivate,
    File? imageFile,
    String? imageUrl,
    String? wishlistId,
  }) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    String? finalImageUrl = imageUrl;

    if (imageFile != null) {
      finalImageUrl = await _cloudinaryService.uploadImage(imageFile);
      if (finalImageUrl == null) {
        throw Exception('Erro ao carregar imagem.');
      }
    }

    final data = {
      'name': name,
      'private': isPrivate,
      'imageUrl': finalImageUrl,
    };

    if (wishlistId == null) {
      data['ownerId'] = userId;
      data['createdAt'] = FieldValue.serverTimestamp();
      await _firestore.collection(_wishlistsCollection).add(data);
    } else {
      await _firestore.collection(_wishlistsCollection).doc(wishlistId).update(data);
    }
  }

  Future<void> deleteWishlist(String wishlistId) async {
    await _firestore.collection(_wishlistsCollection).doc(wishlistId).delete();
  }

  Stream<QuerySnapshot> getWishItems(String wishlistId, {String? category, SortOptions? sortOption}) {
    Query query = _firestore
        .collection(_wishlistsCollection)
        .doc(wishlistId)
        .collection('items');

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    if (sortOption != null) {
      switch (sortOption) {
        case SortOptions.priceAsc:
          query = query.orderBy('price');
          break;
        case SortOptions.priceDesc:
          query = query.orderBy('price', descending: true);
          break;
        case SortOptions.nameAsc:
          query = query.orderBy('name');
          break;
        case SortOptions.nameDesc:
          query = query.orderBy('name', descending: true);
          break;
      }
    } else {
      query = query.orderBy('createdAt', descending: true);
    }

    return query.snapshots();
  }

  Future<void> saveWishItem({
    required String wishlistId,
    required String name,
    required double price,
    required String category,
    String? link,
    String? description,
    File? imageFile,
    String? imageUrl,
    String? itemId,
  }) async {
    String? finalImageUrl = imageUrl;

    if (imageFile != null) {
      finalImageUrl = await _cloudinaryService.uploadImage(imageFile);
      if (finalImageUrl == null) {
        throw Exception('Erro ao carregar imagem.');
      }
    }

    final data = {
      'name': name,
      'price': price,
      'category': category,
      'link': link,
      'description': description,
      'imageUrl': finalImageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (itemId == null) {
      await _firestore
          .collection(_wishlistsCollection)
          .doc(wishlistId)
          .collection('items')
          .add(data);
    } else {
      await _firestore
          .collection(_wishlistsCollection)
          .doc(wishlistId)
          .collection('items')
          .doc(itemId)
          .update(data);
    }
  }

  Future<void> deleteWishItem(String wishlistId, String itemId) async {
    await _firestore
        .collection(_wishlistsCollection)
        .doc(wishlistId)
        .collection('items')
        .doc(itemId)
        .delete();
  }

  Stream<QuerySnapshot> getPublicUsers({String? searchTerm}) {
    Query query = _firestore
        .collection(_usersCollection)
        .where('isPrivate', isEqualTo: false);

    if (searchTerm != null && searchTerm.isNotEmpty) {
      query = query
          .orderBy('displayName')
          .startAt([searchTerm])
          .endAt(['$searchTerm\uf8ff']);
    }

    return query.snapshots();
  }

  Stream<QuerySnapshot> getPublicWishlists({String? searchTerm}) {
    Query query = _firestore
        .collection(_wishlistsCollection)
        .where('private', isEqualTo: false);

    if (searchTerm != null && searchTerm.isNotEmpty) {
      query = query
          .orderBy('name')
          .startAt([searchTerm])
          .endAt(['$searchTerm\uf8ff']);
    }

    return query.snapshots();
  }
}