import 'package:flutter/material.dart';
import 'package:ntu_success_sprint_app/intro/onboarding_screens.dart';
import 'package:ntu_success_sprint_app/nav_bar_and_pages/nav_bar_screen.dart';
import 'package:ntu_success_sprint_app/pages/signup_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  _navigateToNextScreen() async {
    await Future.delayed(Duration(seconds: 3), () {});

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isLoggedIn = prefs.getBool('isLoggedIn');
    bool? hasSeenOnboarding = prefs.getBool('hasSeenOnboarding');
    bool? skipOnboarding = prefs.getBool('skipOnboarding');
    bool? skipForNow = prefs.getBool('skipForNow');

    if (isLoggedIn == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => NavigationScreen()),
      );
    } else if (skipForNow == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => NavigationScreen()),
      );
    } else if (skipOnboarding == true) {
      // Navigate to Home Page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SignUpPage()),
      );
    } else if (hasSeenOnboarding == true) {
      // Navigate to Sign Up Page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SignUpPage()),
      );
    } else {
      // Navigate to Onboarding
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Onboarding()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: TweenAnimationBuilder(
          tween: Tween<double>(begin: 0.3, end: 1.0),
          duration: Duration(seconds: 2),
          curve: Curves.easeInOut,
          builder: (context, double scale, child) {
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: Image.asset(
            'assets/logo.png',
            width: size.width * 0.5,
            height: size.height * 0.5,
          ),
        ),
      ),
    );
  }
}
