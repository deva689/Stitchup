// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:flutter/material.dart';

// class GoogleAuthService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final GoogleSignIn _googleSignIn = GoogleSignIn();

//   Future<void> loginWithGoogle(BuildContext context) async {
//     try {
//       // Start the sign-in process
//       final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
//       if (googleUser == null) return; // User canceled sign-in

//       // Get authentication details
//       final GoogleSignInAuthentication googleAuth =
//           await googleUser.authentication;
//       final AuthCredential credential = GoogleAuthProvider.credential(
//         accessToken: googleAuth.accessToken,
//         idToken: googleAuth.idToken,
//       );

//       // Sign in to Firebase
//       UserCredential userCredential =
//           await _auth.signInWithCredential(credential);

//       if (userCredential.user != null) {
//         // ✅ Navigate to HomePage on success
//         Navigator.pushReplacementNamed(context, "/homepage");
//       }
//     } catch (e) {
//       print("Google Sign-In Error: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Google Sign-In Failed!")),
//       );
//     }
//   }
// }
