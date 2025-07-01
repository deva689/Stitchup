// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:stitchup/splash.dart/wrapper.dart';

// class Verifyemail extends StatefulWidget {
//   const Verifyemail({super.key});

//   @override
//   State<Verifyemail> createState() => _VerifyemailState();
// }

// class _VerifyemailState extends State<Verifyemail> {
//   @override
//   void initState() {
//     sendverifylink();
//     super.initState();
//   }

//   sendverifylink() async {
//     final User = FirebaseAuth.instance.currentUser!;
//     await User.sendEmailVerification().then((value) => {
//           Get.snackbar('Link Sent', 'A link has send to your email',
//               margin: EdgeInsets.all(30), snackPosition: SnackPosition.BOTTOM)
//         });
//   }

//   reload() async {
//     await FirebaseAuth.instance.currentUser!
//         .reload()
//         .then((Value) => {Get.offAll(Wrapped())});
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Verification"),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(28.0),
//         child: Center(
//           child: Text(
//               "Open your mail and click on the link provided to verify email & reload this pa"),
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: (() => reload()),
//         child: Icon(Icons.restart_alt_rounded),
//       ),
//     );
//   }
// }
