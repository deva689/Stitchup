import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:stitchup/models/user_model.dart';
import 'package:stitchup/screen/account.dart/home.dart/homepage.dart';

class ProfileInfoScreen extends StatefulWidget {
  const ProfileInfoScreen({super.key});

  @override
  _ProfileInfoScreenState createState() => _ProfileInfoScreenState();
}

class _ProfileInfoScreenState extends State<ProfileInfoScreen> {
  final TextEditingController nameController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;
  final FocusNode nameFocusNode = FocusNode();

  File? localPreviewFile;
  String? profileImageUrl;
  bool isLoading = false;
  bool isEmojiVisible = false;
  bool hasTyped = false;

  @override
  void initState() {
    super.initState();
    loadProfileImage();

    nameFocusNode.addListener(() {
      if (nameFocusNode.hasFocus) {
        setState(() => isEmojiVisible = false);
      }
    });

    nameController.addListener(() {
      setState(() => hasTyped = nameController.text.isNotEmpty);
    });
  }

  String normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10 ? digits.substring(digits.length - 10) : '';
  }

  Future<void> loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUrl = prefs.getString('cached_profile_url');

    if (cachedUrl != null) {
      setState(() => profileImageUrl = cachedUrl);
    }

    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      final data = doc.data();
      if (data != null) {
        final url = data['profileUrl'] ?? '';
        final name = data['name'] ?? '';
        nameController.text = name;

        if (url.isNotEmpty && url != cachedUrl) {
          await precacheImage(CachedNetworkImageProvider(url), context);
          await prefs.setString('cached_profile_url', url);
          setState(() => profileImageUrl = url);
        }
      }
    }
  }

  Future<void> pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
          ),
        ],
      );

      if (croppedFile != null) {
        final compressedBytes = await FlutterImageCompress.compressWithFile(
          croppedFile.path,
          quality: 50,
        );

        if (compressedBytes != null) {
          final tempFile = File(
              '${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
          await tempFile.writeAsBytes(compressedBytes);
          setState(() => localPreviewFile = tempFile);
          await uploadProfilePicture(tempFile);
        }
      }
    }
  }

  Future<void> uploadProfilePicture(File imageFile) async {
    try {
      if (user == null) return;

      final ref = FirebaseStorage.instance
          .ref()
          .child('profileImages')
          .child('${user!.uid}.jpg');
      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();
      final bustedUrl =
          "$downloadUrl?updated=${DateTime.now().millisecondsSinceEpoch}";

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .set({'profileUrl': bustedUrl}, SetOptions(merge: true));

      await precacheImage(CachedNetworkImageProvider(bustedUrl), context);

      if (!mounted) return;
      setState(() {
        profileImageUrl = bustedUrl;
        localPreviewFile = null;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_profile_url', bustedUrl);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Profile photo updated!')),
      );
    } catch (e) {
      debugPrint('❌ Upload failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠ Failed to update profile photo')),
      );
    }
  }

  Future<void> saveUserToFirestore({
    required String name,
    required String profileUrl,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final phone = user.phoneNumber ?? '';
    final normalizedPhone = normalizePhone(phone);

    UserModel userData = UserModel(
        uid: user.uid,
        name: name,
        phoneNumber: phone,
        profilePic: profileUrl,
        about: "New User",
        isOnline: true,
        lastSeen: DateTime.now());

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(userData.toMap(), SetOptions(merge: true));
  }

  Future<void> saveProfileData() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name is required")),
      );
      return;
    }

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final normalizedPhone = normalizePhone(user!.phoneNumber ?? '');

      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'uid': user!.uid,
        'name': name,
        'phone': normalizedPhone,
        'profileUrl': profileImageUrl ?? '',
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Homepage()),
      );
    } catch (e, stacktrace) {
      debugPrint("❌ Save error: $e");
      debugPrint("📌 Stacktrace: $stacktrace");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save profile: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    nameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title:
            const Text("Profile info", style: TextStyle(color: Colors.black)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    const Text(
                      "Please provide your name and an\noptional profile photo",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 30),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: localPreviewFile != null
                              ? FileImage(localPreviewFile!)
                              : (profileImageUrl != null &&
                                      profileImageUrl!.isNotEmpty)
                                  ? CachedNetworkImageProvider(profileImageUrl!)
                                  : const AssetImage(
                                          'assets/avatar_placeholder.png')
                                      as ImageProvider,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: pickAndUploadImage,
                            child: const CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.black,
                              child: Icon(Icons.add, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    TextField(
                      controller: nameController,
                      focusNode: nameFocusNode,
                      style: TextStyle(
                        color: hasTyped ? Colors.black : Colors.grey,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: "Type your name here",
                        border: const UnderlineInputBorder(),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.green),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.green, width: 2),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.emoji_emotions_outlined),
                          onPressed: () {
                            FocusScope.of(context).unfocus();
                            setState(() => isEmojiVisible = !isEmojiVisible);
                          },
                        ),
                      ),
                    ),
                    if (isEmojiVisible)
                      SizedBox(
                        height: 250,
                        child: EmojiPicker(
                          onEmojiSelected: (category, emoji) {
                            nameController.text += emoji.emoji;
                            nameController.selection =
                                TextSelection.fromPosition(
                              TextPosition(offset: nameController.text.length),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : saveProfileData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Save & Continue",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// import 'dart:io';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:image_cropper/image_cropper.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:flutter_image_compress/flutter_image_compress.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:stitchup/screen/account.dart/home.dart/homepage.dart';
// import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:stitchup/models/user_model.dart';

// class ProfileInfoScreen extends StatefulWidget {
//   final String uid;

//   const ProfileInfoScreen({super.key, required this.uid});

//   @override
//   State<ProfileInfoScreen> createState() => _ProfileInfoScreenState();
// }

// class _ProfileInfoScreenState extends State<ProfileInfoScreen> {
//   final TextEditingController nameController = TextEditingController();
//   final FocusNode nameFocusNode = FocusNode();

//   File? localPreviewFile;
//   String? profileImageUrl;
//   bool isLoading = false;
//   bool isEmojiVisible = false;
//   bool hasTyped = false;

//   @override
//   void initState() {
//     super.initState();
//     loadProfileImage();

//     nameFocusNode.addListener(() {
//       if (nameFocusNode.hasFocus) {
//         setState(() => isEmojiVisible = false);
//       }
//     });

//     nameController.addListener(() {
//       setState(() => hasTyped = nameController.text.trim().isNotEmpty);
//     });
//   }

//   String normalizePhone(String phone) {
//     final digits = phone.replaceAll(RegExp(r'\D'), '');
//     return digits.length >= 10 ? digits.substring(digits.length - 10) : '';
//   }

//   Future<void> loadProfileImage() async {
//     final prefs = await SharedPreferences.getInstance();
//     final cachedUrl = prefs.getString('cached_profile_url');

//     if (cachedUrl != null) {
//       setState(() => profileImageUrl = cachedUrl);
//     }

//     final doc = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(widget.uid)
//         .get();

//     final data = doc.data();
//     if (data != null) {
//       final url = data['profileUrl'] ?? '';
//       final name = data['name'] ?? '';
//       nameController.text = name;

//       if (url.isNotEmpty && url != cachedUrl && url.startsWith('http')) {
//         await precacheImage(CachedNetworkImageProvider(url), context);
//         await prefs.setString('cached_profile_url', url);
//         setState(() => profileImageUrl = url);
//       }
//     }
//   }

//   Future<void> pickAndUploadImage() async {
//     final picker = ImagePicker();
//     final pickedFile = await picker.pickImage(source: ImageSource.gallery);

//     if (pickedFile != null) {
//       final croppedFile = await ImageCropper().cropImage(
//         sourcePath: pickedFile.path,
//         uiSettings: [
//           AndroidUiSettings(
//             toolbarTitle: 'Crop Image',
//             toolbarColor: Colors.black,
//             toolbarWidgetColor: Colors.white,
//             hideBottomControls: true,
//           ),
//         ],
//       );

//       if (croppedFile != null) {
//         final compressedBytes = await FlutterImageCompress.compressWithFile(
//           croppedFile.path,
//           quality: 60,
//         );

//         if (compressedBytes != null) {
//           final tempFile = File(
//               '${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
//           await tempFile.writeAsBytes(compressedBytes);
//           setState(() => localPreviewFile = tempFile);
//           await uploadProfilePicture(tempFile);
//         }
//       }
//     }
//   }

//   Future<void> uploadProfilePicture(File imageFile) async {
//     try {
//       final ref = FirebaseStorage.instance
//           .ref()
//           .child('profileImages')
//           .child('${widget.uid}.jpg');

//       await ref.putFile(imageFile);
//       final downloadUrl = await ref.getDownloadURL();

//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(widget.uid)
//           .set({'profileUrl': downloadUrl}, SetOptions(merge: true));

//       await precacheImage(CachedNetworkImageProvider(downloadUrl), context);

//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString('cached_profile_url', downloadUrl);

//       setState(() {
//         profileImageUrl = downloadUrl;
//         localPreviewFile = null;
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('✅ Profile photo updated!')),
//       );
//     } catch (e) {
//       debugPrint('❌ Upload failed: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('⚠ Failed to update profile photo')),
//       );
//     }
//   }

//   Future<void> saveUserToFirestore({
//     required String name,
//     required String profileUrl,
//   }) async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     final phone = user.phoneNumber ?? '';
//     final normalizedPhone = normalizePhone(phone);

//     final userData = UserModel(
//       uid: user.uid,
//       name: name,
//       phoneNumber: normalizedPhone,
//       profilePic: profileUrl,
//       about: "New User",
//       isOnline: true,
//       lastSeen: DateTime.now(),
//     );

//     await FirebaseFirestore.instance
//         .collection('users')
//         .doc(user.uid)
//         .set(userData.toMap(), SetOptions(merge: true));
//   }

//   Future<void> saveProfileData() async {
//     final name = nameController.text.trim();
//     if (name.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Name is required")),
//       );
//       return;
//     }

//     setState(() => isLoading = true);

//     try {
//       await saveUserToFirestore(
//         name: name,
//         profileUrl: profileImageUrl ?? '',
//       );

//       if (!mounted) return;

//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const Homepage()),
//       );
//     } catch (e) {
//       debugPrint("❌ Save error: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Failed to save profile: $e")),
//       );
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }

//   @override
//   void dispose() {
//     nameController.dispose();
//     nameFocusNode.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         automaticallyImplyLeading: false,
//         backgroundColor: Colors.white,
//         elevation: 0,
//         centerTitle: true,
//         title:
//             const Text("Profile info", style: TextStyle(color: Colors.black)),
//       ),
//       body: SafeArea(
//         child: Column(
//           children: [
//             Expanded(
//               child: SingleChildScrollView(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
//                 child: Column(
//                   children: [
//                     const Text(
//                       "Please provide your name and an\noptional profile photo",
//                       textAlign: TextAlign.center,
//                       style: TextStyle(fontSize: 16),
//                     ),
//                     const SizedBox(height: 30),
//                     Stack(
//                       alignment: Alignment.center,
//                       children: [
//                         CircleAvatar(
//                           radius: 55,
//                           backgroundColor: Colors.grey[300],
//                           backgroundImage: localPreviewFile != null
//                               ? FileImage(localPreviewFile!)
//                               : (profileImageUrl != null &&
//                                       profileImageUrl!.startsWith('http'))
//                                   ? CachedNetworkImageProvider(profileImageUrl!)
//                                   : const AssetImage(
//                                           'assets/default_avatar.png')
//                                       as ImageProvider,
//                         ),
//                         Positioned(
//                           bottom: 0,
//                           right: 0,
//                           child: GestureDetector(
//                             onTap: pickAndUploadImage,
//                             child: const CircleAvatar(
//                               radius: 18,
//                               backgroundColor: Colors.black,
//                               child: Icon(Icons.add, color: Colors.white),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 25),
//                     TextField(
//                       controller: nameController,
//                       focusNode: nameFocusNode,
//                       style: TextStyle(
//                         color: hasTyped ? Colors.black : Colors.grey,
//                         fontSize: 16,
//                       ),
//                       decoration: InputDecoration(
//                         hintText: "Type your name here",
//                         border: const UnderlineInputBorder(),
//                         enabledBorder: const UnderlineInputBorder(
//                           borderSide: BorderSide(color: Colors.green),
//                         ),
//                         focusedBorder: const UnderlineInputBorder(
//                           borderSide: BorderSide(color: Colors.green, width: 2),
//                         ),
//                         suffixIcon: IconButton(
//                           icon: const Icon(Icons.emoji_emotions_outlined),
//                           onPressed: () {
//                             FocusScope.of(context).unfocus();
//                             setState(() => isEmojiVisible = !isEmojiVisible);
//                           },
//                         ),
//                       ),
//                     ),
//                     if (isEmojiVisible)
//                       SizedBox(
//                         height: 250,
//                         child: EmojiPicker(
//                           onEmojiSelected: (category, emoji) {
//                             nameController.text += emoji.emoji;
//                             nameController.selection =
//                                 TextSelection.fromPosition(
//                               TextPosition(offset: nameController.text.length),
//                             );
//                           },
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
//               child: SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: isLoading ? null : saveProfileData,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.black,
//                     minimumSize: const Size.fromHeight(48),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                   ),
//                   child: isLoading
//                       ? const CircularProgressIndicator(color: Colors.white)
//                       : const Text(
//                           "Save & Continue",
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 16,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
