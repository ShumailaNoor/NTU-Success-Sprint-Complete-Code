import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ntu_success_sprint_app/constant.dart';
import 'package:ntu_success_sprint_app/nav_bar_and_pages/nav_bar_screen.dart';
import 'package:ntu_success_sprint_app/pages/signup_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _passwordVisible = false;
  bool rememberMe = false;
  bool _isLoading = false;

  String emailErrorVal = '';
  String passErrorVal = '';

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  Future<void> loginUser() async {
    setState(() {
      _isLoading = true;
      emailErrorVal = ''; // Reset error messages
      passErrorVal = '';
    });

    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    // Validate email and password before attempting to log in
    if (email.isEmpty || !email.endsWith('@gmail.com')) {
      setState(() {
        emailErrorVal = 'Please enter valid email';
      });
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (password.isEmpty || password.length < 6) {
      setState(() {
        passErrorVal = 'Password should be at least 6 characters';
      });
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Sign in the user with email and password
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

// Set the logged-in flag in SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      // Navigate to the main screen after successful login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const NavigationScreen(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      // Handle errors
      if (e.code == 'invalid-credential') {
        setState(() {
          emailErrorVal = 'Invalid email or password';
          passErrorVal = 'Invalid email or password';
        });
      } else {
        setState(() {
          emailErrorVal = 'An error occurred. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        emailErrorVal = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> resetPassword() async {
    String email = emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        emailErrorVal = 'Please enter your email to reset password.';
      });
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            icon: Icon(Icons.lock_reset, color: primaryColor, size: 40),
            title: Text(
              'Password Reset Email Sent',
              style: TextStyle(color: primaryColor),
            ),
            content: Text('Check your email for the password reset link.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700])),
            actions: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                label: Text("OK"),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        emailErrorVal = 'An error occurred. Please try again. ';
      });
      print('Error sending password reset email: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            primaryColor,
            secondaryColor,
          ],
        )),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: size.height * 0.02),
                  Image.asset(
                    'assets/logo.png',
                    height: size.height * 0.15,
                    width: size.width * 0.3,
                  ),
                  SizedBox(height: size.height * 0.02),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primaryColor, width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      hintText: 'Email',
                      errorText: emailErrorVal.isEmpty ? null : emailErrorVal,
                      prefixIcon: const Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: size.height * 0.02),
                  TextField(
                    controller: passwordController,
                    obscureText: !_passwordVisible,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primaryColor, width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      hintText: 'Password',
                      errorText: passErrorVal.isEmpty ? null : passErrorVal,
                      prefixIcon: Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: secondaryColor,
                        ),
                        onPressed: () {
                          setState(() {
                            _passwordVisible = !_passwordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      TextButton(
                        onPressed: resetPassword,
                        child: Text(
                          "Forgot Password?",
                          style: TextStyle(
                            color: secondaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Don't have an account? "),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.all(0),
                            ),
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignUpPage(),
                                ),
                              );
                            },
                            child: Text(
                              "Sign Up",
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 2,
                        width: 50,
                        color: Colors.grey,
                        margin: const EdgeInsets.symmetric(vertical: 5),
                      ),
                      TextButton(
                        onPressed: () async {
                          SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                          await prefs.setBool('skipForNow', true);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NavigationScreen(),
                            ),
                          );
                        },
                        child: Text(
                          "Skip for now",
                          style: TextStyle(
                            color: secondaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: loginUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'LOGIN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.015),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
