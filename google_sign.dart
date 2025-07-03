import 'package:flutter/material.dart';

class googleSignIn extends StatefulWidget {
  const googleSignIn({super.key});

  @override
  State<googleSignIn> createState() => _googleSignInState();
}

class _googleSignInState extends State<googleSignIn> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: TextButton(onPressed: () {}, child: Text("Google signin")),
    ));
  }
}
