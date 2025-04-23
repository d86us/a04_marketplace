import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';

class FilterOrderWidget extends StatefulWidget {
  final void Function(String)? onOrderChange;
  final void Function(String)? onFilterChange;

  const FilterOrderWidget({
    super.key,
    this.onOrderChange,
    this.onFilterChange,
  });

  @override
  State<FilterOrderWidget> createState() => _FilterOrderWidgetState();
}

class _FilterOrderWidgetState extends State<FilterOrderWidget> {
  String _selectedOrder = 'Date: Newest';
  String _selectedFilter = 'All';

  final Location _location = Location();
  double? _currentLatitude;
  double? _currentLongitude;

  final List<String> orderOptions = [
    'Price: Cheapest',
    'Price: Most Expensive',
    'Age: Youngest',
    'Age: Oldest',
    'Date: Newest',
    'Date: Oldest',
    'Distance: Closest',
    'Distance: Furthest',
  ];

  final List<String> filterOptions = [
    'All',
    'Gender: Male',
    'Gender: Female',
    'Health: Excellent',
    'Health: Good',
    'Health: Fair',
    'Health: Poor',
    'Health: Sick',
  ];

  Future<void> _getCurrentLocation() async {
    if (_currentLatitude != null && _currentLongitude != null) return;

    try {
      LocationData locationData = await _location.getLocation();
      setState(() {
        _currentLatitude = locationData.latitude;
        _currentLongitude = locationData.longitude;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error getting location: $e');
      }
    }
  }

  InputDecoration _dropdownDecoration() => InputDecoration(
        filled: true,
        fillColor: Colors.black,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      );

  @override
  Widget build(BuildContext context) {
    final isDistanceOption = _selectedOrder == 'Distance: Closest' || _selectedOrder == 'Distance: Furthest';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedOrder,
                  decoration: _dropdownDecoration(),
                  dropdownColor: Colors.black,
                  iconEnabledColor: Colors.white,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  isExpanded: true,
                  items: orderOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (val) async {
                    if (val != null) {
                      setState(() => _selectedOrder = val);

                      if (val == 'Distance: Closest' || val == 'Distance: Furthest') {
                        await _getCurrentLocation();
                      }

                      widget.onOrderChange?.call(val);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedFilter,
                  decoration: _dropdownDecoration(),
                  dropdownColor: Colors.black,
                  iconEnabledColor: Colors.white,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  isExpanded: true,
                  items: filterOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedFilter = val);
                      widget.onFilterChange?.call(val);
                    }
                  },
                ),
              ),
            ],
          ),
          if (isDistanceOption && _currentLatitude != null && _currentLongitude != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Location: $_currentLatitude, $_currentLongitude',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
