import 'package:flutter/material.dart';

class GoogleSignIn extends StatefulWidget {
  const GoogleSignIn({super.key});

  @override
  State<GoogleSignIn> createState() => _GoogleSignInState();
}

class _GoogleSignInState extends State<GoogleSignIn> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: TextButton(onPressed: () {}, child: Text("Google signin")),
    ));
  }
}
