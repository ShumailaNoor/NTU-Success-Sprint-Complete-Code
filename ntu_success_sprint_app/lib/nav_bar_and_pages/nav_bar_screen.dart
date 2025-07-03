import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:ntu_success_sprint_app/constant.dart';
import 'package:ntu_success_sprint_app/nav_bar_and_pages/home_page.dart';
import 'package:ntu_success_sprint_app/nav_bar_and_pages/performance_page.dart';
import 'package:ntu_success_sprint_app/nav_bar_and_pages/profile_page.dart';
import 'package:ntu_success_sprint_app/provider/nav_provider.dart';
import 'package:provider/provider.dart';

class NavigationScreen extends StatelessWidget {
  const NavigationScreen({super.key});

  final List<Widget> _pages = const [
    PerformancePage(),
    HomePage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context);

    return Scaffold(
      body: _pages[navProvider.currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: secondaryColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        child: GNav(
          backgroundColor: secondaryColor,
          color: Colors.white,
          activeColor: Colors.white,
          tabBackgroundColor: primaryColor,
          gap: 8,
          padding: const EdgeInsets.all(12),
          selectedIndex: navProvider.currentIndex,
          onTabChange: (index) {
            navProvider.setIndex(index);
          },
          tabs: const [
            GButton(icon: Icons.bar_chart, text: 'Performance'),
            GButton(icon: Icons.home, text: 'Home'),
            GButton(icon: Icons.person, text: 'Profile'),
          ],
        ),
      ),
    );
  }
}
