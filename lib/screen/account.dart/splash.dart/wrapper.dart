import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stitchup/screen/account.dart/home.dart/homepage.dart';
import 'package:stitchup/screen/account.dart/login.dart/login.dart';

class Wrapped extends StatefulWidget {
  const Wrapped({super.key});

  @override
  State<Wrapped> createState() => _WrappedState();
}

class _WrappedState extends State<Wrapped> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            // snapshot.hasData check pannanum

            return Homepage();
          } else {
            return Login();
          }
        },
      ),
    );
  }
}
