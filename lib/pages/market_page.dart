import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:location/location.dart';
import '../widgets/items_list_widget.dart';
import '../widgets/menu_widget.dart';
import '../widgets/filter_order_widget.dart';

class MarketPage extends StatefulWidget {
  const MarketPage({super.key});

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  List<String> _favoriteGoats = [];
  List<Map<String, dynamic>> _allGoats = [];
  String _selectedOrder = 'Date: Newest';
  String _selectedFilter = 'All';

  double? _currentLatitude;
  double? _currentLongitude;

  final Location _location = Location();

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
    _fetchGoats();
    _detectLocation();
  }

  Future<void> _detectLocation() async {
    try {
      final locationData = await _location.getLocation();
      setState(() {
        _currentLatitude = locationData.latitude;
        _currentLongitude = locationData.longitude;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error detecting location: $e');
      }
    }
  }

  Future<void> _fetchFavorites() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .get();

    setState(() {
      _favoriteGoats =
          snapshot.docs.map((doc) => doc['goatId'] as String).toList();
    });
  }

  Future<void> _fetchGoats() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('goats')
        .orderBy('created', descending: true)
        .get();

    final goats = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      data['images'] ??= [];
      return data;
    }).toList();

    setState(() {
      _allGoats = goats;
    });
  }

  Future<void> _toggleFavorite(String goatId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final favRef = FirebaseFirestore.instance
        .collection('favorites')
        .doc('${userId}_$goatId');

    final exists = _favoriteGoats.contains(goatId);

    if (exists) {
      await favRef.delete();
      setState(() {
        _favoriteGoats.remove(goatId);
      });
    } else {
      await favRef.set({
        'userId': userId,
        'goatId': goatId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      setState(() {
        _favoriteGoats.add(goatId);
      });
    }
  }

  List<Map<String, dynamic>> _getFilteredAndSortedGoats() {
    List<Map<String, dynamic>> filtered = _allGoats;

    if (_selectedFilter != 'All') {
      // This assumes 'gender', 'health', and other attributes exist in the goat's data.
      filtered = filtered.where((goat) {
        final filterKey = _selectedFilter.split(':')[0].trim().toLowerCase();
        final filterValue = _selectedFilter.split(':')[1].trim().toLowerCase();

        // Check if the goat's attribute matches the filter
        if (filterKey == 'gender') {
          return (goat['gender'] as String?)?.toLowerCase() == filterValue;
        } else if (filterKey == 'health') {
          return (goat['health'] as String?)?.toLowerCase() == filterValue;
        }
        return false; // You can add more filter checks here if needed
      }).toList();
    }

    switch (_selectedOrder) {
      case 'Price: Cheapest':
        filtered.sort((a, b) => (a['price'] ?? 0).compareTo(b['price'] ?? 0));
        break;
      case 'Price: Most Expensive':
        filtered.sort((a, b) => (b['price'] ?? 0).compareTo(a['price'] ?? 0));
        break;
      case 'Age: Youngest':
        filtered.sort((a, b) => (a['age'] ?? 0).compareTo(b['age'] ?? 0));
        break;
      case 'Age: Oldest':
        filtered.sort((a, b) => (b['age'] ?? 0).compareTo(a['age'] ?? 0));
        break;
      case 'Date: Newest':
        filtered
            .sort((a, b) => (b['created'] ?? 0).compareTo(a['created'] ?? 0));
        break;
      case 'Date: Oldest':
        filtered
            .sort((a, b) => (a['created'] ?? 0).compareTo(b['created'] ?? 0));
        break;
      case 'Distance: Closest':
      case 'Distance: Furthest':
        if (_currentLatitude != null && _currentLongitude != null) {
          filtered.sort((a, b) {
            final aLat = a['latitude'] ?? 0.0;
            final aLng = a['longitude'] ?? 0.0;
            final bLat = b['latitude'] ?? 0.0;
            final bLng = b['longitude'] ?? 0.0;

            double distanceA = _calculateDistance(
                _currentLatitude!, _currentLongitude!, aLat, aLng);
            double distanceB = _calculateDistance(
                _currentLatitude!, _currentLongitude!, bLat, bLng);

            return _selectedOrder == 'Distance: Closest'
                ? distanceA.compareTo(distanceB)
                : distanceB.compareTo(distanceA);
          });
        }
        break;
    }

    return filtered;
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  @override
  Widget build(BuildContext context) {
    return MenuWidget(
      title: 'Goat Market',
      selectedIndex: 0,
      child: _allGoats.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ItemsListWidget(
              goats: _getFilteredAndSortedGoats(),
              favoriteGoatIds: _favoriteGoats,
              showFavorites: true,
              onFavoriteToggle: _toggleFavorite,
              header: FilterOrderWidget(
                onOrderChange: (order) {
                  setState(() {
                    _selectedOrder = order;
                  });
                },
                onFilterChange: (filter) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
              ),
            ),
    );
  }
}
