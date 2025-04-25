import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/items_list_widget.dart';
import '../widgets/menu_widget.dart';
import '../services/database_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<Map<String, dynamic>> _favoriteGoats = [];
  bool _isLoading = true; // Add loading flag
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadFavoriteGoats();
  }

  Future<void> _loadFavoriteGoats() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      final List<String> goatIds =
          snapshot.docs.map((doc) => doc['goatId'] as String).toList();

      if (goatIds.isEmpty) {
        setState(() {
          _favoriteGoats = [];
          _isLoading = false;
        });
        return;
      }

      final goatFutures = goatIds.map((goatId) {
        return FirebaseFirestore.instance.collection('goats').doc(goatId).get();
      }).toList();

      final goatSnapshots = await Future.wait(goatFutures);

      final List<Map<String, dynamic>> fullGoatData = [];

      for (var goatSnapshot in goatSnapshots) {
        if (goatSnapshot.exists) {
          final goatData = goatSnapshot.data()!;
          fullGoatData.add({
            'id': goatSnapshot.id,
            ...goatData,
          });
        }
      }

      setState(() {
        _favoriteGoats = fullGoatData;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error loading favorite goats: $e");
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite(String goatId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final isFavorite = _favoriteGoats.any((goat) => goat['id'] == goatId);

    setState(() {
      if (isFavorite) {
        _favoriteGoats.removeWhere((goat) => goat['id'] == goatId);
      } else {
        _favoriteGoats.add({'id': goatId});
      }
    });

    if (isFavorite) {
      await _databaseHelper.removeFavorite(userId: userId, goatId: goatId);
      await FirebaseFirestore.instance
          .collection('favorites')
          .doc('${userId}_$goatId')
          .delete();
    } else {
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

    _loadFavoriteGoats();
  }

  @override
  Widget build(BuildContext context) {
    return MenuWidget(
      title: 'Favorites',
      selectedIndex: 1,
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ItemsListWidget(
              goats: _favoriteGoats,
              favoriteGoatIds:
                  _favoriteGoats.map((goat) => goat['id'] as String).toList(),
              showFavorites: true,
              onFavoriteToggle: _toggleFavorite,
            ),
    );
  }
}
