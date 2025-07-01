import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

import 'package:stitchup/screen/account.dart/splash.dart/wrapper.dart';

class StitchupSplash extends StatefulWidget {
  const StitchupSplash({super.key});

  @override
  State<StitchupSplash> createState() => _StitchupSplashState();
}

class _StitchupSplashState extends State<StitchupSplash> {
  @override
  void initState() {
    super.initState();
    Timer(
      const Duration(seconds: 2),
      () {
        if (!mounted) return; // ✅ Prevents Navigator call if widget is disposed
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Wrapped()),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          'STITCHUP',
          style: GoogleFonts.playfairDisplay(
            fontSize: 48,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
