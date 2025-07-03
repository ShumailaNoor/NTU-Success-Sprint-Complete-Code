import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:ntu_success_sprint_app/constant.dart';
import 'package:ntu_success_sprint_app/pages/semester_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String username = 'User '; // Default username
  bool isLoading = true; // Loading state

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser; // Get the current user
    if (user != null) {
      DatabaseReference userRef =
          FirebaseDatabase.instance.ref().child('Users').child(user.uid);

      // Fetch user data
      userRef.once().then((event) {
        if (event.snapshot.exists) {
          setState(() {
            username = event.snapshot
                .child('name')
                .value
                .toString(); // Get the username
            isLoading = false; // Set loading to false
          });
        }
      });
    } else {
      setState(() {
        isLoading = false; // Set loading to false if no user is found
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: EdgeInsets.all(size.width * 0.04),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.055,
                      vertical: size.height * 0.018),
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(size.width * 0.067),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: size.width * 0.015,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: size.width * 0.069,
                        backgroundImage: AssetImage('assets/profile.png'),
                      ),
                      SizedBox(width: size.width * 0.05),
                      Expanded(
                        child: Text(
                          'Hey, $username',
                          style: TextStyle(
                            fontSize: size.width * 0.063,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: size.height * 0.01),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.055,
                      vertical: size.height * 0.018),
                  margin: EdgeInsets.symmetric(vertical: size.height * 0.018),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(size.width * 0.053),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: size.width * 0.015,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        color: Colors.white,
                        size: size.width * 0.166,
                      ),
                      SizedBox(width: size.width * 0.033),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Start Your Sprint to Success!',
                              style: TextStyle(
                                fontSize: size.width * 0.052,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: size.height * 0.006),
                            Text(
                              'Choose your program and unlock customized resources to boost your academic journey at NTU.',
                              style: TextStyle(
                                fontSize: size.width * 0.035,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ProgramCard(
                  title: 'Software Engineering',
                  imagePath: 'assets/se.jpeg',
                ),
                SizedBox(height: size.height * 0.02),
                ProgramCard(
                  title: 'Computer Science',
                  imagePath: 'assets/cs.jpg',
                ),
                SizedBox(height: size.height * 0.02),
                ProgramCard(
                  title: 'Artificial Intelligence',
                  imagePath: 'assets/ai.jpg',
                ),
                SizedBox(height: size.height * 0.02),
                ProgramCard(
                  title: 'Computer Engineering',
                  imagePath: 'assets/ce.jpg',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProgramCard extends StatelessWidget {
  final String title;
  final String imagePath;

  const ProgramCard({
    super.key,
    required this.title,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () {
        if (title == 'Software Engineering') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SemesterPage(selectedProgram: title),
            ),
          );
        } else if (title == 'Computer Science') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SemesterPage(selectedProgram: title),
            ),
          );
        } else if (title == 'Artificial Intelligence') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SemesterPage(selectedProgram: title),
            ),
          );
        } else if (title == 'Computer Engineering') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SemesterPage(selectedProgram: title),
            ),
          );
        }
      },
      child: Container(
        height: size.height * 0.2,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
            opacity: 2,
          ),
          borderRadius: BorderRadius.circular(size.width * 0.027),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: size.width * 0.012,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.027, vertical: size.height * 0.006),
            child: Text(
              title,
              style: TextStyle(
                fontSize: size.width * 0.066,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
