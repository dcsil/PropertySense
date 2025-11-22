import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/domain/models/user_model.dart';
import 'package:provider/provider.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;
  final int currentIndex;

  const ScaffoldWithNavBar({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    // Get user type from your UserRepository
    final userType = context.watch<UserRepository>().currentUser?.type;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          if (userType == UserType.contractor) {
            // Contractor navigation
            switch (index) {
              case 0:
                context.go('/listings-swipe');
                break;
              case 1:
                context.go('/listings-map');
                break;
              case 2:
                context.go('/profile');
                break;
            }
          } else {
            // Homeowner navigation
            switch (index) {
              case 0:
                context.go('/listings');
                break;
              case 1:
                context.go('/profile');
                break;
            }
          }
        },
        destinations: userType == UserType.contractor
            ? const [
                // Contractor tabs
                NavigationDestination(
                  icon: Icon(Icons.work_outline),
                  selectedIcon: Icon(Icons.work),
                  label: 'Find Jobs',
                ),
                NavigationDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map),
                  label: 'Map',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ]
            : const [
                // Homeowner tabs
                NavigationDestination(
                  icon: Icon(Icons.list_outlined),
                  selectedIcon: Icon(Icons.list),
                  label: 'My Listings',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
      ),
    );
  }
}
                  