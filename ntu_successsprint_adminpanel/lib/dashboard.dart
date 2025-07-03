import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ntu_successsprint_adminpanel/constant.dart';
import 'package:ntu_successsprint_adminpanel/pages/course_content.dart';
import 'package:ntu_successsprint_adminpanel/pages/course_title.dart';
import 'package:ntu_successsprint_adminpanel/login_page.dart';
import 'package:ntu_successsprint_adminpanel/pages/youtube_links.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int selectedIndex = 0; // Default: Manage Course Title

  // List of pages
  final List<Widget> pages = [
    const ManageCourseTitle(),
    const ManageCourseOutline(),
    const ManageYoutubeLink(),
  ];

  Future<void> logout(BuildContext context) async {
    FirebaseAuth auth = FirebaseAuth.instance;
    await auth.signOut();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isLoggedIn", false);

    bool rememberMe = prefs.getBool("rememberMe") ?? false;
    if (!rememberMe) {
      await prefs.remove("savedEmail");
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SignInPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Fixed Navigation Drawer
          Container(
            width: size.width * 0.25,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 0,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Logo
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Image.asset(
                      'assets/logo.png',
                      width: size.width * 0.2,
                      height: size.height * 0.25,
                    ),
                  ),
                ),
                // Navigation Options
                Expanded(
                  child: Column(
                    children: [
                      buildNavItem(
                          Icons.library_books, "Manage Course Title", 0),
                      buildNavItem(
                          Icons.list, "Manage Course Content Outline", 1),
                      buildNavItem(
                          Icons.video_library, "Manage YouTube Link", 2),
                    ],
                  ),
                ),
                // Logout Button at the Bottom
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ElevatedButton.icon(
                    onPressed: () => logout(context),
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text("Logout"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          // Main Content Area (Only Changes When Navigation Clicked)
          Expanded(
            child: pages[selectedIndex], // Show the selected page
          ),
        ],
      ),
    );
  }

  // Navigation Item with Active Highlight
  Widget buildNavItem(IconData icon, String title, int index) {
    return InkWell(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
      child: Container(
        color: selectedIndex == index ? secondaryColor : Colors.transparent,
        child: ListTile(
          leading: Icon(icon,
              color: selectedIndex == index ? Colors.white : secondaryColor),
          title: Text(
            title,
            style: TextStyle(
                color: selectedIndex == index ? Colors.white : Colors.black),
          ),
        ),
      ),
    );
  }
}
