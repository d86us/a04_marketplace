import 'package:flutter/material.dart';
import '../widgets/menu_widget.dart'; // Import the menu widget

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MenuWidget(
      title: 'Settings',
      selectedIndex: 3, // This will highlight the "Settings" menu item
      child: Scaffold(
        body: const Center(
          child: Text('Settings Page Content'),
        ),
      ),
    );
  }
}