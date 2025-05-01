import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:stitchup/login.dart/ProfileInfoScreen.dart';

class Otprecieve extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;

  const Otprecieve(
      {super.key, required this.phoneNumber, required this.verificationId});

  @override
  _OtprecieveState createState() => _OtprecieveState();
}

class _OtprecieveState extends State<Otprecieve> {
  FirebaseAuth auth = FirebaseAuth.instance;
  String otp = "";
  bool isButtonEnabled = false;
  int countdown = 120; // 2-minute timer
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    startCountdown();
  }

  void startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown > 0) {
        setState(() {
          countdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void verifyOtp() async {
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a 6-digit OTP")),
      );
      return;
    }

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otp,
      );

      UserCredential userCredential =
          await auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        String uid = userCredential.user!.uid;
        String phoneNumber =
            userCredential.user!.phoneNumber ?? widget.phoneNumber;

        // 🔥 Store phone number in Firestore
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'phoneNumber': phoneNumber,
          'uid': uid,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // 🚀 Navigate to profile info screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfileInfoScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invalid OTP: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white, // Light theme background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            const Text(
              "Verification Code",
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff222222)),
            ),
            const SizedBox(height: 10),
            Text(
              "Please enter the 6-digit code sent to",
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 5),
            Text(
              widget.phoneNumber, // ✅ Automatically displays phone number
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff232323)),
            ),
            const SizedBox(height: 20),
            OtpTextField(
              autoFocus: true,
              numberOfFields: 6,
              borderColor: Colors.blue,
              focusedBorderColor: const Color.fromARGB(255, 0, 0, 0),
              showFieldAsBox: true,
              onSubmit: (code) {
                setState(() {
                  otp = code;
                  isButtonEnabled = otp.length == 6;
                });
              },
            ),
            const SizedBox(height: 20),
            Text(
              "Resend OTP in ${countdown ~/ 60}:${(countdown % 60).toString().padLeft(2, '0')}",
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isButtonEnabled ? verifyOtp : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isButtonEnabled
                      ? const Color.fromARGB(255, 0, 0, 0)
                      : Colors.grey[300],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text("Verify & Login",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w400)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
