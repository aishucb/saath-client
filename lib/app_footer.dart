/// AppFooter widget for the Saath app
///
/// This file defines the reusable bottom navigation bar (footer)
/// used across all main pages for easy navigation.
import 'package:flutter/material.dart';

class AppFooter extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  const AppFooter({Key? key, required this.currentIndex, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.pinkAccent,
      unselectedItemColor: Colors.grey,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      currentIndex: currentIndex,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
        BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'Forum'),
        BottomNavigationBarItem(icon: Icon(Icons.spa), label: 'Wellness'),
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
      ],
    );
  }
}
