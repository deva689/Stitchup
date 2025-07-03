import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stitchup/screen/account.dart/login.dart/login.dart';
import 'package:stitchup/screen/mainNavigationScreen.dart';

class Wrapped extends StatefulWidget {
  const Wrapped({super.key});

  @override
  State<Wrapped> createState() => _WrappedState();
}

class _WrappedState extends State<Wrapped> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator()); // Optional loading state
        }

        if (snapshot.hasData) {
          return const MainNavigationScreen(); // ✅ FIXED HERE
        } else {
          return const Login();
        }
      },
    );
  }
}
