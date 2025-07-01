import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:stitchup/screen/account.dart/login.dart/ProfileInfoScreen.dart';

class Otprecieve extends StatefulWidget {
  final String phoneNumber;

  const Otprecieve({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<Otprecieve> createState() => _OtprecieveState();
}

class _OtprecieveState extends State<Otprecieve> {
  String otp = "";
  bool isButtonEnabled = false;
  bool loading = false;
  int countdown = 120;
  Timer? _timer;
  final _storage = const FlutterSecureStorage();

  final String baseUrl = "https://salespatner.onrender.com"; // your backend

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
      showError("Please enter the 6-digit OTP");
      return;
    }

    setState(() => loading = true);

    try {
      final res = await http.post(
        Uri.parse("https://salespatner.onrender.com/auth/verify-otp"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "emailOrPhone": widget.phoneNumber,
          "otp": otp,
        }),
      );

      if (res.statusCode == 200) {
        final token = jsonDecode(res.body)['token'];
        await _storage.write(key: "token", value: token);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfileInfoScreen()),
        );
      } else {
        final error = jsonDecode(res.body)['error'] ?? "Invalid OTP";
        showError(error);
      }
    } catch (e) {
      showError("Network error. Please try again.");
    }

    setState(() => loading = false);
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("❌ $message"), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text("Enter the 6-digit OTP sent to your number",
                style: TextStyle(fontSize: 16, color: Colors.grey[700])),
            const SizedBox(height: 5),
            Text(widget.phoneNumber,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff232323))),
            const SizedBox(height: 20),
            OtpTextField(
              autoFocus: true,
              numberOfFields: 6,
              borderColor: Colors.blue,
              focusedBorderColor: Colors.black,
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
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isButtonEnabled && !loading ? verifyOtp : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isButtonEnabled ? Colors.black : Colors.grey[300],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Verify & Login",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w400)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
