import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a new goat listing to Firestore// Add a new goat listing to Firestore
  Future<void> addGoat({
    required String name,
    required int price,
    required String location,
    required String description,
    required String gender,
    required String health,
    required int age,
    required List<String> images, // Only image URLs or paths
    required String userId,
    required Map<String, double>? geolocation, // Add geolocation here
  }) async {
    try {
      await _firestore.collection('goats').add({
        'name': name,
        'userId': userId,
        'price': price,
        'location': location,
        'gender': gender,
        'age': age,
        'health': health,
        'description': description,
        'images':
            images, // These should be string paths (e.g., local or web URLs)
        'geolocation': geolocation, // Store geolocation
        'created': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('Goat listing added successfully!');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding goat: $e');
      }
    }
  }

  // Fetch all goat listings from Firestore
  Future<List<Map<String, dynamic>>> getGoats() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('goats').get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Include document ID if needed
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching goats: $e');
      }
      return [];
    }
  }

  // Add a goat to user's favorites
  Future<void> addFavorite({
    required String userId,
    required String goatId,
  }) async {
    try {
      await _firestore.collection('favorites').add({
        'userId': userId,
        'goatId': goatId,
        'created': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('Goat added to favorites');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding goat to favorites: $e');
      }
    }
  }

  // Remove a goat from user's favorites
  Future<void> removeFavorite({
    required String userId,
    required String goatId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .where('goatId', isEqualTo: goatId)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      if (kDebugMode) {
        print('Goat removed from favorites');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error removing goat from favorites: $e');
      }
    }
  }

  // Fetch all favorite goats for a user
  Future<List<Map<String, dynamic>>> getFavorites({
    required String userId,
  }) async {
    try {
      // Fetch the list of favorite goat IDs for the user
      final favSnapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .get();

      final goatIds =
          favSnapshot.docs.map((doc) => doc['goatId'] as String).toList();

      if (goatIds.isEmpty) {
        return [];
      }

      // Fetch the goats based on the favorite IDs
      final goatSnapshot = await _firestore
          .collection('goats')
          .where(FieldPath.documentId, whereIn: goatIds)
          .get();

      final goats = goatSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Add the document ID
        return data;
      }).toList();

      return goats;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching favorite goats: $e');
      }
      return [];
    }
  }

// Update an existing goat listing in Firestore
  Future<void> updateGoat({
    required String goatId,
    required String name,
    required int price,
    required String location,
    required String description,
    required String gender,
    required String health,
    required int age,
    required List<String> images,
    required Map<String, double>? geolocation, // Add geolocation here
  }) async {
    try {
      await _firestore.collection('goats').doc(goatId).update({
        'name': name,
        'price': price,
        'location': location,
        'description': description,
        'gender': gender,
        'health': health,
        'age': age,
        'images': images,
        'geolocation': geolocation, // Store geolocation
        'updated': FieldValue.serverTimestamp(), // Optionally track updates
      });

      if (kDebugMode) {
        print('Goat listing updated successfully!');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating goat: $e');
      }
    }
  }
}
