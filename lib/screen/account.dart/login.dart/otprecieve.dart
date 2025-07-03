import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:stitchup/screen/account.dart/login.dart/ProfileInfoScreen.dart';

class Otprecieve extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;

  const Otprecieve({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
  });

  @override
  State<Otprecieve> createState() => _OtprecieveState();
}

class _OtprecieveState extends State<Otprecieve> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String otp = "";
  bool isButtonEnabled = false;
  bool isVerifying = false;
  int countdown = 120;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown > 0) {
        setState(() => countdown--);
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

  Future<void> _verifyOtp() async {
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid 6-digit OTP")),
      );
      return;
    }

    setState(() => isVerifying = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otp,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;
        final phone = userCredential.user!.phoneNumber ?? widget.phoneNumber;

        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'uid': uid,
          'phoneNumber': phone,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProfileInfoScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invalid OTP: ${e.toString()}")),
      );
    } finally {
      setState(() => isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String formattedTimer =
        "${(countdown ~/ 60).toString().padLeft(2, '0')}:${(countdown % 60).toString().padLeft(2, '0')}";

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
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
              widget.phoneNumber,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff232323)),
            ),
            const SizedBox(height: 20),
            OtpTextField(
              numberOfFields: 6,
              borderColor: Colors.blue,
              focusedBorderColor: Colors.black,
              showFieldAsBox: true,
              autoFocus: true,
              onSubmit: (code) {
                setState(() {
                  otp = code;
                  isButtonEnabled = otp.length == 6;
                });
              },
            ),
            const SizedBox(height: 20),
            Text(
              "Resend OTP in $formattedTimer",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isButtonEnabled && !isVerifying ? _verifyOtp : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isButtonEnabled && !isVerifying
                      ? Colors.black
                      : Colors.grey[300],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: isVerifying
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text(
                        "Verify & Login",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
