import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/items_list_widget.dart';
import '../widgets/menu_widget.dart';
import '../services/database_helper.dart'; // Import the DatabaseHelper
import 'package:cloud_firestore/cloud_firestore.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<Map<String, dynamic>> _favoriteGoats = [];
  final DatabaseHelper _databaseHelper =
      DatabaseHelper(); // Initialize DatabaseHelper

  @override
  void initState() {
    super.initState();
    _loadFavoriteGoats();
  }

  Future<void> _loadFavoriteGoats() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .get();

    final List<Map<String, dynamic>> fullGoatData = [];

    for (var doc in snapshot.docs) {
      final goatId = doc['goatId'];
      final goatSnapshot = await FirebaseFirestore.instance
          .collection('goats')
          .doc(goatId)
          .get();

      if (goatSnapshot.exists) {
        final goatData = goatSnapshot.data()!;
        fullGoatData.add({
          'id': goatId,
          ...goatData,
        });
      }
    }

    setState(() {
      _favoriteGoats = fullGoatData;
    });
  }

  Future<void> _toggleFavorite(String goatId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final isFavorite = _favoriteGoats.any((goat) => goat['id'] == goatId);

    setState(() {
      // Toggle the heart color to white immediately after the press
      if (isFavorite) {
        _favoriteGoats.removeWhere((goat) => goat['id'] == goatId);
      } else {
        // Add the goat to favorites list
        _favoriteGoats.add({'id': goatId});
      }
    });

    if (isFavorite) {
      // Remove from Firestore and local DB
      await _databaseHelper.removeFavorite(userId: userId, goatId: goatId);
      await FirebaseFirestore.instance
          .collection('favorites')
          .doc('${userId}_$goatId')
          .delete();
    } else {
      // Add to Firestore and local DB
      await _databaseHelper.addFavorite(userId: userId, goatId: goatId);
      await FirebaseFirestore.instance
          .collection('favorites')
          .doc('${userId}_$goatId')
          .set({
        'userId': userId,
        'goatId': goatId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    _loadFavoriteGoats(); // Reload the favorite goats to reflect the new state
  }

  @override
  Widget build(BuildContext context) {
    return MenuWidget(
      title: 'Favorites',
      selectedIndex: 1,
      child: ItemsListWidget(
        goats: _favoriteGoats,
        favoriteGoatIds:
            _favoriteGoats.map((goat) => goat['id'] as String).toList(),
        showFavorites: true, // Display only the hearts
        onFavoriteToggle:
            _toggleFavorite, // Pass the toggle function to ItemsListWidget
      ),
    );
  }
}
