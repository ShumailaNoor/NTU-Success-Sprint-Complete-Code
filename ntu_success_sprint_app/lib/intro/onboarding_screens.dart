import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:ntu_success_sprint_app/constant.dart';
import 'package:ntu_success_sprint_app/pages/signup_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Onboarding extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return IntroductionScreen(
      globalBackgroundColor: Colors.white,
      pages: [
        PageViewModel(
          title: "Unlock Your Academic Success!",
          body:
              "Discover a one-stop platform for all your course materials, outlines, and quizzes – designed to help you excel at NTU!",
          image: Center(
              child:
                  Image.asset("assets/student.png", height: size.height * 0.3)),
          decoration: PageDecoration(
            pageColor: Colors.white,
            imagePadding: EdgeInsets.only(top: size.height * 0.1),
            titleTextStyle: TextStyle(
                fontSize: size.width * 0.06,
                fontWeight: FontWeight.bold,
                color: secondaryColor),
            bodyTextStyle: TextStyle(fontSize: size.width * 0.04),
          ),
        ),
        PageViewModel(
          title: "Master Every Course Effortlessly!",
          body:
              "Access detailed course outlines, high-quality YouTube lectures, and valuable study materials to stay ahead in your academic journey.",
          image: Center(
              child:
                  Image.asset("assets/youtube.png", height: size.height * 0.3)),
          decoration: PageDecoration(
            pageColor: Colors.white,
            imagePadding: EdgeInsets.only(top: size.height * 0.1),
            titleTextStyle: TextStyle(
                fontSize: size.width * 0.06,
                fontWeight: FontWeight.bold,
                color: primaryColor),
            bodyTextStyle: TextStyle(fontSize: size.width * 0.04),
          ),
        ),
        PageViewModel(
          title: "Test, Track & Triumph!",
          body:
              "Take interactive quizzes, monitor your progress, and sharpen your skills to achieve top grades in every semester!",
          image: Center(
              child: Image.asset("assets/quiz.png", height: size.height * 0.3)),
          decoration: PageDecoration(
            pageColor: Colors.white,
            imagePadding: EdgeInsets.only(top: size.height * 0.1),
            titleTextStyle: TextStyle(
                fontSize: size.width * 0.06,
                fontWeight: FontWeight.bold,
                color: secondaryColor),
            bodyTextStyle: TextStyle(fontSize: size.width * 0.04),
          ),
        ),
      ],
      onDone: () async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('hasSeenOnboarding', true);
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => SignUpPage()));
      },
      onSkip: () async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('hasSeenOnboarding', true);
        await prefs.setBool('skipOnboarding', true);
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => SignUpPage()));
      },
      showSkipButton: true,
      skip: Text(
        "Skip",
        style: TextStyle(
            color: secondaryColor,
            fontSize: size.width * 0.04,
            fontWeight: FontWeight.bold),
      ),
      next: Icon(
        Icons.arrow_forward,
        color: secondaryColor,
        size: size.width * 0.08,
      ),
      done: Text("Done",
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: secondaryColor,
              fontSize: size.width * 0.04)),
      dotsDecorator: DotsDecorator(
        size: const Size(10.0, 10.0),
        color: Colors.grey,
        activeSize: const Size(22.0, 10.0),
        activeColor: secondaryColor,
        activeShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(size.width * 0.02)),
      ),
    );
  }
}
