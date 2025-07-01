import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:stitchup/screen/account.dart/ChatScreen/ChatScreen.dart';
import 'package:stitchup/screen/account.dart/TRNdX/TRNDX.dart';
import 'package:stitchup/screen/account.dart/home.dart/homepage.dart';
import 'package:stitchup/screen/account.dart/login.dart/login.dart';
import 'package:stitchup/screen/account.dart/orderscreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitchup/widgets/MyStatusScreen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String? profileImageUrl;
  File? localPreviewFile;
  List<Map<String, dynamic>> contactsWithStories = [];
  bool isUploading = false;
  double uploadProgress = 0.0;
  List<String> yourFetchedContactUIDsFromFirestore = []; // your list of UIDs
  bool hasUploadedStory = false;
  String? myPhotoUrl;
  bool isImageReady = false;
  final ImagePicker picker = ImagePicker();
  List<Map<String, dynamic>> stories = [];
  bool isStoryLoading = false;
  bool isStoryUploading = false;
  Map<String, String> localContactNames = {};

  User? user; // 👈 This is needed!

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    loadProfileImage(); // Only this needed
  }

  Future<void> loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();

    // Load cached URL instantly
    final cachedUrl = prefs.getString('cached_profile_url');
    if (cachedUrl != null) {
      setState(() {
        profileImageUrl = cachedUrl;
      });
    }

    // Fetch latest from Firestore
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (doc.exists) {
        final url = doc.data()?['profileUrl'] ?? '';

        // If URL changed, precache new image
        if (url != cachedUrl && url.isNotEmpty) {
          if (mounted) {
            await precacheImage(CachedNetworkImageProvider(url), context);
          }

          await prefs.setString('cached_profile_url', url);

          if (mounted) {
            setState(() {
              profileImageUrl = url;
            });
          }
        }
      }
    }

    if (mounted) setState(() => isImageReady = true);
  }

  Future<void> pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: 'Crop Image'),
        ],
      );

      if (croppedFile != null) {
        final compressedBytes = await FlutterImageCompress.compressWithFile(
          croppedFile.path,
          quality: 50,
        );

        if (compressedBytes != null) {
          final tempDir = Directory.systemTemp;
          final tempFile = File(
              '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
          await tempFile.writeAsBytes(compressedBytes);

          setState(() {
            localPreviewFile = tempFile;
          });

          await uploadProfilePicture(tempFile);
        }
      }
    }
  }

  Future<void> uploadProfilePicture(File imageFile) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profileImages')
          .child('${user!.uid}.jpg');

      await ref.putFile(imageFile);

      final downloadUrl =
          await ref.getDownloadURL(); // ✅ No ?updated added manually
      final bustedUrl =
          "$downloadUrl?updated=${DateTime.now().millisecondsSinceEpoch}";

      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(user!.uid);

      await userDoc.set({'profileUrl': bustedUrl}, SetOptions(merge: true));

      if (!mounted) return;

      /// ✅ precache only if still mounted
      await precacheImage(CachedNetworkImageProvider(bustedUrl), context);

      if (!mounted) return;

      setState(() {
        profileImageUrl = bustedUrl;
        localPreviewFile = null;
      });

      /// ✅ snackbar only if still mounted
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Profile photo updated!')),
      );
    } catch (e) {
      print('❌ Upload failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠ Failed to update profile photo')),
        );
      }
    }
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void openStoryViewer(String userId) {
    final hasStory = contactsWithStories.any((s) => s['userId'] == userId);
    if (hasStory) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MyStatusScreen(userId: userId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider imageProvider;

    if (localPreviewFile != null) {
      imageProvider = FileImage(localPreviewFile!);
    } else if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
      imageProvider = CachedNetworkImageProvider(profileImageUrl!);
    } else {
      imageProvider = const AssetImage('assets/default_avatar.png');
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("My Account", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundImage: imageProvider,
                    backgroundColor: Colors.grey[300],
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: pickAndUploadImage,
                      child: const CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.black,
                        child: Icon(Icons.edit, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
            ],
          ),
          const SizedBox(height: 24),
          _buildListItem(
              context, "Orders", Icons.shopping_bag, const OrderScreen()),
          _buildListItem(context, "Customer Care", Icons.support_agent,
              const CustomerCareScreen()),
          _buildListItem(context, "Invite Friends & Earn", Icons.person_add,
              const InviteFriendsScreen(),
              subText: "You get ₹100 for every friend"),
          _buildListItem(context, "AJIO Wallet", Icons.account_balance_wallet,
              const WalletScreen(),
              subText: "Add Gift Card | Manage rewards and refunds"),
          _buildListItem(context, "Saved Cards", Icons.credit_card,
              const SavedCardsScreen()),
          _buildListItem(context, "My Rewards", Icons.card_giftcard,
              const RewardsScreen()),
          _buildListItem(
              context, "Address", Icons.location_on, const AddressScreen()),
          _buildListItem(context, "Notifications", Icons.notifications,
              const NotificationsScreen()),
          _buildListItem(context, "Return Creation Demo",
              Icons.replay_circle_filled, const ReturnDemoScreen()),
          _buildListItem(context, "How To Return", Icons.help_outline,
              const HowToReturnScreen()),
          _buildListItem(context, "How Do I Redeem My Coupon?", Icons.discount,
              const RedeemCouponScreen()),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Login()),
                );
              },
              style: ElevatedButton.styleFrom(
                // Style move to correct position
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Colors.grey),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
              ),
              child: const Text(
                "Logout",
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Login()),
                );
              },
              style: ElevatedButton.styleFrom(
                // Style move to correct position
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                  side: const BorderSide(color: Colors.grey),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 120, vertical: 14),
              ),
              child: const Text(
                "Become a Tailor",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        iconSize: 24,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Store'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Message'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'TRNDx'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: 'Order'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_circle), label: 'Account'),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const Homepage()));
              break;
            case 1:
              Future.delayed(Duration(milliseconds: 100), () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      currentUserId: user!.uid,
                      contactsWithStories: contactsWithStories,
                      localPreviewFile: localPreviewFile,
                      profileImageUrl: profileImageUrl,
                      isUploading: isUploading,
                      uploadProgress: uploadProgress,
                      contactUIDs: yourFetchedContactUIDsFromFirestore,
                      stories: stories,
                      onStoryTap: (userId) => openStoryViewer(userId),
                      localContactNames:
                          localContactNames, // make sure this is defined
                    ),
                  ),
                );
              });

              break;
            case 2:
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const Placeholder()));
              break;
            case 3:
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => Orderpage()));
              break;
            case 4:
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AccountScreen()));
              break;
          }
        },
      ),
    );
  }

  Widget _buildListItem(
      BuildContext context, String title, IconData icon, Widget page,
      {String? subText}) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      subtitle: subText != null
          ? Text(subText,
              style: const TextStyle(fontSize: 12, color: Colors.grey))
          : null,
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: () {
        _navigateTo(context, page);
      },
    );
  }

  void _openPage(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }
}

/// **🔹 Dummy Screens for Navigation**
class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Edit Profile")),
        body: Center(child: Text("Edit Profile Page")));
  }
}

class OrderScreen extends StatelessWidget {
  const OrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("My Orders")),
        body: Center(child: Text("Orders Page")));
  }
}

class CustomerCareScreen extends StatelessWidget {
  const CustomerCareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Customer Care")),
        body: Center(child: Text("Customer Care Page")));
  }
}

class InviteFriendsScreen extends StatelessWidget {
  const InviteFriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Invite Friends")),
        body: Center(child: Text("Invite Friends Page")));
  }
}

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("AJIO Wallet")),
        body: Center(child: Text("Wallet Page")));
  }
}

class SavedCardsScreen extends StatelessWidget {
  const SavedCardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Saved Cards")),
        body: Center(child: Text("Saved Cards Page")));
  }
}

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("My Rewards")),
        body: Center(child: Text("Rewards Page")));
  }
}

class AddressScreen extends StatelessWidget {
  const AddressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Address")),
        body: Center(child: Text("Address Page")));
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Notifications")),
        body: Center(child: Text("Notifications Page")));
  }
}

class ReturnDemoScreen extends StatelessWidget {
  const ReturnDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Return Creation Demo")),
        body: Center(child: Text("Return Demo Page")));
  }
}

class HowToReturnScreen extends StatelessWidget {
  const HowToReturnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("How To Return")),
        body: Center(child: Text("How To Return Page")));
  }
}

class RedeemCouponScreen extends StatelessWidget {
  const RedeemCouponScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Redeem Coupon")),
        body: Center(child: Text("Redeem Coupon Page")));
  }
}
