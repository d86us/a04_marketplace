import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/items_list_widget.dart';
import '../widgets/menu_widget.dart';
import 'sell_page.dart';

class SellingPage extends StatefulWidget {
  final String? successMessage;

  const SellingPage({super.key, this.successMessage});

  @override
  State<SellingPage> createState() => _SellingPageState();
}

class _SellingPageState extends State<SellingPage> {
  Future<List<Map<String, dynamic>>> _loadMyGoats() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('goats')
        .where('userId', isEqualTo: userId)
        .orderBy('created', descending: true)
        .get();

    final goats = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      data['images'] ??= [];
      return data;
    }).toList();

    return goats;
  }

  @override
  void initState() {
    super.initState();
    // Show a SnackBar with the successMessage if available
    if (widget.successMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.successMessage!),
            duration: const Duration(seconds: 3),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MenuWidget(
      title: 'My Listings',
      selectedIndex: 2,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadMyGoats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final goats = snapshot.data ?? [];

          return ItemsListWidget(
            goats: goats,
            showFavorites: false, // Disable showing heart icon for favorites
            onFavoriteToggle:
                null, // Remove functionality for toggling favorites
            favoriteGoatIds: const [], // Empty list since no favorites are needed
            header: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SellPage()),
                      );
                    },
                    icon: const Icon(Icons.sell),
                    label: const Text('Sell Goat'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
