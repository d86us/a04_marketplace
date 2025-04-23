import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../pages/market_page.dart' as market;
import '../pages/favorites_page.dart';
import '../pages/selling_page.dart';
import '../pages/settings_page.dart' as settings;

class MenuWidget extends StatefulWidget {
  final String title; // Add title parameter
  final int selectedIndex;
  final Widget child;

  const MenuWidget({
    super.key,
    required this.title, // Accept title parameter
    required this.selectedIndex,
    required this.child,
  });

  @override
  State<MenuWidget> createState() => _MenuWidgetState();
}

class _MenuWidgetState extends State<MenuWidget> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
  }

  void _onItemTapped(BuildContext context, int index) {
    final routes = ['/market', '/favorites', '/selling', '/settings'];
    final routeName = routes[index];

    setState(() {
      _selectedIndex = index;
    });

    Navigator.of(context).pushReplacement(_noAnimationRoute(routeName));
  }

  PageRouteBuilder _noAnimationRoute(String routeName) {
    return PageRouteBuilder(
      settings: RouteSettings(name: routeName),
      pageBuilder: (context, animation, secondaryAnimation) =>
          _getPageByRouteName(routeName),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }

  Widget _getPageByRouteName(String name) {
    switch (name) {
      case '/market':
        return const market.MarketPage();
      case '/favorites':
        return const FavoritesPage();
      case '/selling':
        return const SellingPage();
      case '/settings':
        return const settings.SettingsPage();
      default:
        return const market.MarketPage();
    }
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title), // Use the title passed to MenuWidget
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => _onItemTapped(context, index),
        items: [
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/goat_icon.svg',
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                _selectedIndex == 0
                    ? Colors.white
                    : Colors.grey, // Change color based on selection
                BlendMode.srcIn, // Apply color filter
              ),
            ),
            label: 'Goats',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.sell),
            label: 'Selling',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
