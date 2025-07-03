import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:ntu_success_sprint_app/constant.dart';
import 'package:ntu_success_sprint_app/pages/signup_page.dart';
import 'package:ntu_success_sprint_app/widgets/snackbar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String username = '';
  String email = '';
  String password = '';
  bool isLoading = true;
  bool isLoggedIn = false;

  // Update your initState method
  @override
  void initState() {
    super.initState();
    checkLoginAndFetchUser();
    startListeningForEmailUpdates(); // Add this line
  }

// Add this method to your _ProfilePageState class
  void startListeningForEmailUpdates() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null && mounted) {
        // Reload user to get the latest email
        user.reload().then((_) {
          final updatedUser = FirebaseAuth.instance.currentUser;
          if (updatedUser != null && updatedUser.email != email) {
            setState(() {
              email = updatedUser.email ?? 'No email found';
            });
          }
        });
      }
    });
  }

  Future<void> checkLoginAndFetchUser() async {
    User? user = FirebaseAuth.instance.currentUser;

    await user?.reload();
    user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        isLoggedIn = true;
      });

      DatabaseReference userRef =
          FirebaseDatabase.instance.ref().child('Users').child(user.uid);
      final snapshot = await userRef.once();

      if (snapshot.snapshot.exists) {
        setState(() {
          username = snapshot.snapshot.child('name').value?.toString() ?? '';
          email = user?.email ?? 'No email found';
          isLoading = false;
        });
      } else {
        setState(() {
          email = user?.email ?? 'No email found';
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoggedIn = false;
        isLoading = false;
      });
    }
  }

  void editUserInfo(String field) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    TextEditingController controller = TextEditingController();
    TextEditingController passwordController = TextEditingController();

    if (field == 'name') controller.text = username;
    if (field == 'email') controller.text = email;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          icon: Icon(Icons.edit, color: primaryColor, size: 40),
          title: Text("Update $field"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (field == 'password') ...[
                SizedBox(height: 10),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration:
                      InputDecoration(hintText: 'Enter current password'),
                ),
              ],
              TextField(
                controller: controller,
                decoration: InputDecoration(hintText: 'Enter new $field'),
                obscureText: field == 'password',
              ),
              if (field == 'email') ...[
                SizedBox(height: 10),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration:
                      InputDecoration(hintText: 'Enter current password'),
                ),
              ]
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                final newValue = controller.text.trim();
                final currentPassword = passwordController.text.trim();

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => Center(
                    child: CircularProgressIndicator(
                      color: primaryColor,
                    ),
                  ),
                );

                try {
                  if (field == 'name') {
                    // Update in database
                    await FirebaseDatabase.instance
                        .ref()
                        .child('Users')
                        .child(user.uid)
                        .update({'name': newValue});
                    setState(() {
                      username = newValue;
                    });
                  } else {
                    // Re-authenticate
                    final cred = EmailAuthProvider.credential(
                      email: user.email!,
                      password: currentPassword,
                    );
                    await user.reauthenticateWithCredential(cred);

                    if (field == 'email') {
                      await user.verifyBeforeUpdateEmail(newValue);

                      showCustomTopSnackBar(
                        context,
                        'Verification email sent. Please verify to complete the update.',
                      );
                    } else if (field == 'password') {
                      await user.updatePassword(newValue);
                    }
                  }
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  if (field != 'email') {
                    showCustomTopSnackBar(
                        context, '$field updated successfully');
                  }
                } catch (e) {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  showCustomTopSnackBar(context,
                      '$field failed to update. Please check your current password.');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('OK',
                  style: TextStyle(
                    color: Colors.white,
                  )),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        color: secondaryColor,
        onRefresh: checkLoginAndFetchUser,
        child: Center(
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3), // changes position of shadow
                  ),
                ],
              ),
              child: isLoggedIn
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: size.height * 0.02),
                        CircleAvatar(
                          radius: size.width * 0.09,
                          backgroundImage: AssetImage('assets/profile.png'),
                        ),
                        SizedBox(height: size.height * 0.02),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.person, color: primaryColor),
                          title: Text('Name: $username'),
                          trailing: IconButton(
                            icon: Icon(Icons.edit, color: secondaryColor),
                            onPressed: () => editUserInfo('name'),
                          ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.email, color: primaryColor),
                          title: Text('Email: $email',
                              overflow: TextOverflow.ellipsis),
                          trailing: IconButton(
                            icon: Icon(Icons.edit, color: secondaryColor),
                            onPressed: () => editUserInfo('email'),
                          ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.lock, color: primaryColor),
                          title: Text(
                              'Password: ********'), // Show encrypted password
                          trailing: IconButton(
                            icon: Icon(Icons.edit, color: secondaryColor),
                            onPressed: () => editUserInfo('password'),
                          ),
                        ),
                        SizedBox(height: size.height * 0.02),
                        ElevatedButton(
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SignUpPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: const Text(
                              'LOG OUT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: size.height * 0.01),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: size.height * 0.05),
                        Icon(
                          Icons.person_off,
                          size: size.width * 0.2,
                          color: secondaryColor,
                        ),
                        SizedBox(height: size.height * 0.03),
                        Text(
                          'You are not logged in.',
                          style: TextStyle(
                            fontSize: size.width * 0.055,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: size.height * 0.01),
                        Text(
                          'Please sign up or log in to view your profile details and access all features.',
                          style: TextStyle(
                            fontSize: size.width * 0.04,
                            color: Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: size.height * 0.04),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SignUpPage()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14.0, horizontal: 24.0),
                            child: Text(
                              'Sign Up / Log In',
                              style: TextStyle(
                                fontSize: size.width * 0.045,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
