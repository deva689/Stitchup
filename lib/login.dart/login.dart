import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:stitchup/login.dart/ProfileInfoScreen.dart';
import 'package:stitchup/login.dart/otprecieve.dart';
import 'package:stitchup/login.dart/privacypolicy.dart';
import 'package:stitchup/login.dart/terms_condition.dart';
import 'package:flutter/gestures.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _phoneController = TextEditingController();
  final FirebaseAuth auth = FirebaseAuth.instance;
  String? _verificationId;
  bool isButtonEnabled = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_validatePhoneNumber);
  }

  void _validatePhoneNumber() {
    setState(() {
      isButtonEnabled = _phoneController.text.length == 10;
    });
  }

  void _verifyPhoneNumber() async {
    setState(() {
      isLoading = true;
    });

    try {
      await auth.verifyPhoneNumber(
        phoneNumber: "+91${_phoneController.text}",
        forceResendingToken: null,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // For auto verification
          await auth.signInWithCredential(credential);
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/home');
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Verification Failed: ${e.message}")),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            isLoading = false;
            _verificationId = verificationId;
          });

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => Otprecieve(
                phoneNumber: _phoneController.text,
                verificationId: verificationId,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error: $e");
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // Force account picker by signing out any previous account
      await googleSignIn.signOut(); // 🔥 This line is important

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase Sign-In
      await FirebaseAuth.instance.signInWithCredential(credential);

      // Navigate to Homepage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ProfileInfoScreen()),
      );
    } catch (e) {
      print("Error signing in: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-in failed. Please try again.')),
      );
    }
  }

// //facebook login
//   Future<void> signInWithFacebook(BuildContext context) async {
//     try {
//       // Sign out first to always trigger account selection
//       await FacebookAuth.instance.logOut();

//       final LoginResult result = await FacebookAuth.instance.login();

//       if (result.status == LoginStatus.success) {
//         final accessToken = result.accessToken;

//         final credential = FacebookAuthProvider.credential(accessToken!.token);

//         await FirebaseAuth.instance.signInWithCredential(credential);

//         // Navigate to homepage
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => Homepage()),
//         );
//       } else {
//         print("Facebook login failed: ${result.status}");
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Facebook login failed.')),
//         );
//       }
//     } catch (e) {
//       print("Error during Facebook sign-in: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Something went wrong.')),
//       );
//     }
//   }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 96),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xff0000000),
                      child: Image.asset(
                        'assets/Login logo.png',
                        width: 48,
                        height: 48,
                      ),
                    ),
                    // const SizedBox(width: 16),
                    // const Text(
                    //   'Stitchup',
                    //   style: TextStyle(
                    //       fontSize: 24,
                    //       fontWeight: FontWeight.w500,
                    //       fontFamily: 'Playfair_Display_SC'),
                    // ),
                  ],
                ),
                const SizedBox(
                  height: 14,
                ),
                const Text(
                  'Your Niche To Make Style',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontFamily: 'Playfair_Display_SC'),
                ),
                const SizedBox(
                  height: 8,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Unique',
                      style: TextStyle(
                          fontSize: 14,
                          color: Color(0xff777777),
                          fontWeight: FontWeight.w400),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.0),
                      child: Text('•',
                          style: TextStyle(
                            color: Color(0xff777777),
                          )),
                    ),
                    Text(
                      'Affordable',
                      style: TextStyle(
                          fontSize: 14,
                          color: Color(0xff777777),
                          fontWeight: FontWeight.w400),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.0),
                      child: Text('•',
                          style: TextStyle(
                            color: Color(0xff777777),
                          )),
                    ),
                    Text(
                      'Trusted',
                      style: TextStyle(
                          fontSize: 14,
                          color: Color(0xff777777),
                          fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 24,
                ),
                Container(
                  width: double.infinity,
                  height: 54,
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(5),
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      Row(
                        children: [
                          Image.asset('assets/flag-7403565_1920.png',
                              width: 24, height: 16, fit: BoxFit.cover),
                          SizedBox(width: 6),
                          Text('+91', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        margin: EdgeInsets.symmetric(horizontal: 12),
                        color: Colors.grey.shade300,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(10),
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Enter Mobile Number",
                            hintStyle: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'We’ll send a one-time password (OTP) to your mobile number for verification.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isButtonEnabled && !isLoading
                        ? _verifyPhoneNumber
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isButtonEnabled ? Colors.black : Colors.grey[300],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Send OTP',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                  ),
                ),
                SizedBox(
                  height: 256,
                ),
                // Column(
                //   children: [
                //     const Text(
                //       "Or Continue With Social Account",
                //       style:
                //           TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
                //     ),
                //   ],
                // ),
                SizedBox(height: 28),
                SizedBox(height: 24),
                Column(children: [
                  // ⚠️ Warning Box
                  Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1), // Light yellow
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.email_outlined,
                          color: Colors.black87,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                              children: [
                                const TextSpan(
                                    text:
                                        'Email login is no longer supported. Please '),
                                // TextSpan(
                                //   text: 'click here',
                                //   style: const TextStyle(
                                //     color: Colors.blue,
                                //     decoration: TextDecoration.underline,
                                //     fontWeight: FontWeight.w500,
                                //   ),
                                //   recognizer: TapGestureRecognizer()
                                //     ..onTap = () {
                                // TODO: Implement restore mobile number action
                                //     },
                                // ),
                                const TextSpan(
                                    text: ' use your mobile number to log in.'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      signInWithGoogle(context); // Pass the context here
                    },
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Color(0xffffffff),
                        borderRadius: BorderRadius.circular(2),
                        image: const DecorationImage(
                          image: AssetImage('assets/g-logo.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  // Terms & Conditions
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.black87),
                              children: [
                                const TextSpan(
                                    text: 'By Signing In, I agree to '),
                                TextSpan(
                                  text: 'Terms & Conditions',
                                  style: const TextStyle(color: Colors.blue),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                TermsAndConditionsPage()),
                                      );
                                    },
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: const TextStyle(color: Colors.blue),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const PrivacyPolicyPage()),
                                      );
                                    },
                                ),
                              ]))),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
