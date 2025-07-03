import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ntu_success_sprint_app/constant.dart';
import 'package:ntu_success_sprint_app/firebase_options.dart';
import 'package:ntu_success_sprint_app/intro/splash_screen.dart';
import 'package:ntu_success_sprint_app/provider/nav_provider.dart';
import 'package:ntu_success_sprint_app/provider/user_provider.dart';
import 'package:ntu_success_sprint_app/provider/video_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => VideoProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NTU Success Sprint',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: secondaryColor),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
