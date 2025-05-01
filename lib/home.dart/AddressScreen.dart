// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:stitchup/home.dart/LocationSearchDelegate.dart';
// import 'package:stitchup/home.dart/MapPickerScreen.dart';

// Future<void> getCoordinatesFromAddress(String address) async {
//   final apiKey = 'AIzaSy************'; // use your key here
//   final url = Uri.parse(
//     'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$apiKey',
//   );

//   final response = await http.get(url);
//   final data = json.decode(response.body);

//   if (data['status'] == 'OK') {
//     final location = data['results'][0]['geometry']['location'];
//     print("Latitude: ${location['lat']}, Longitude: ${location['lng']}");
//   } else {
//     print("Error: ${data['status']}");
//   }
// }

// Future<void> getAddressFromCoordinates(double lat, double lng) async {
//   final apiKey = 'AIzaSy************'; // your API key
//   final url = Uri.parse(
//     'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey',
//   );

//   final response = await http.get(url);
//   final data = json.decode(response.body);

//   if (data['status'] == 'OK') {
//     final address = data['results'][0]['formatted_address'];
//     print("Address: $address");
//   } else {
//     print("Error: ${data['status']}");
//   }
// }

// class AddressScreen extends StatefulWidget {
//   const AddressScreen({super.key});

//   @override
//   State<AddressScreen> createState() => _AddressScreenState();
// }

// class _AddressScreenState extends State<AddressScreen> {
//   List<String> savedAddresses = [];
//   String? selectedAddress;

//   @override
//   void initState() {
//     super.initState();
//     loadSavedAddresses();
//   }

//   Future<void> loadSavedAddresses() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     setState(() {
//       savedAddresses = prefs.getStringList('saved_addresses') ?? [];
//       selectedAddress = prefs.getString('selected_address');
//     });
//   }

//   Future<void> useCurrentLocation() async {
//     Position position = await Geolocator.getCurrentPosition();
//     List<Placemark> placemarks =
//         await placemarkFromCoordinates(position.latitude, position.longitude);
//     String addr =
//         "${placemarks.first.name}, ${placemarks.first.locality}, ${placemarks.first.postalCode}";

//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => MapPickerScreen(
//           initialPosition: LatLng(position.latitude, position.longitude),
//           onAddressSelected: (address) async {
//             SharedPreferences prefs = await SharedPreferences.getInstance();
//             savedAddresses.add(address);
//             prefs.setStringList('saved_addresses', savedAddresses);
//             prefs.setString('selected_address', address);
//             await loadSavedAddresses();
//           },
//         ),
//       ),
//     );
//   }

//   void openSearch() async {
//     final result =
//         await showSearch(context: context, delegate: LocationSearchDelegate());
//     if (result != null) {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       savedAddresses.add(result);
//       prefs.setStringList('saved_addresses', savedAddresses);
//       prefs.setString('selected_address', result);
//       await loadSavedAddresses();
//     }
//   }

//   void selectAddress(String address) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     prefs.setString('selected_address', address);
//     setState(() {
//       selectedAddress = address;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(title: Text("Enter your area or apartment name")),
//       body: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           children: [
//             TextField(
//               readOnly: true,
//               onTap: openSearch,
//               decoration: InputDecoration(
//                 prefixIcon: Icon(Icons.search),
//                 hintText: "Try Camproad , East Tambaram, etc.",
//                 border:
//                     OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//               ),
//             ),
//             ListTile(
//               leading: Icon(Icons.my_location, color: Colors.orange),
//               title: Text("Use my current location",
//                   style: TextStyle(color: Colors.orange)),
//               onTap: useCurrentLocation,
//             ),
//             ListTile(
//               leading: Icon(Icons.add, color: Colors.orange),
//               title: Text("Add new address",
//                   style: TextStyle(color: Colors.orange)),
//               onTap: useCurrentLocation,
//             ),
//             const Divider(),
//             Align(
//               alignment: Alignment.centerLeft,
//               child: Text("Saved Addresses",
//                   style: TextStyle(fontWeight: FontWeight.bold)),
//             ),
//             ...savedAddresses.map((address) => ListTile(
//                   leading: Icon(Icons.location_on),
//                   title: Text(address,
//                       maxLines: 1, overflow: TextOverflow.ellipsis),
//                   subtitle: selectedAddress == address
//                       ? Container(
//                           padding:
//                               EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                           decoration: BoxDecoration(
//                               color: Colors.green.shade100,
//                               borderRadius: BorderRadius.circular(6)),
//                           child: Text("CURRENTLY SELECTED",
//                               style: TextStyle(fontSize: 12)),
//                         )
//                       : null,
//                   onTap: () => selectAddress(address),
//                 )),
//           ],
//         ),
//       ),
//     );
//   }
// }

// import 'dart:io';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:image_cropper/image_cropper.dart';
// import 'package:flutter_image_compress/flutter_image_compress.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:stitchup/Trndxscreen.dart';
// import 'package:stitchup/home.dart/homepage.dart';
// import 'package:stitchup/login.dart/login.dart';
// import 'package:stitchup/message.dart';
// import 'package:stitchup/orderscreen.dart';

// class AccountScreen extends StatefulWidget {
//   const AccountScreen({super.key});

//   @override
//   _AccountScreenState createState() => _AccountScreenState();
// }

// class _AccountScreenState extends State<AccountScreen> {
//   String? profileImageUrl;
//   File? localPreviewFile;
//   String name = "";
//   String email = "";
//   String phone = "";
//   bool isImageReady = false;

//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController phoneController = TextEditingController();

//   User? user; // 👈 This is needed!

//   @override
//   void initState() {
//     super.initState();
//     user = FirebaseAuth.instance.currentUser;
//     loadUserDetails();
//   }

//   Future<void> loadUserDetails() async {
//     if (user != null) {
//       try {
//         final docSnapshot = await FirebaseFirestore.instance
//             .collection('users')
//             .doc(user!.uid)
//             .get();

//         if (docSnapshot.exists) {
//           final data = docSnapshot.data();
//           final url = data?['profileUrl'] ?? '';

//           if (url.isNotEmpty) {
//             await precacheImage(CachedNetworkImageProvider(url), context);
//           }

//           setState(() {
//             name = data?['name'] ?? '';
//             email = data?['email'] ?? '';
//             phone = data?['phone'] ?? '';
//             profileImageUrl = url;

//             nameController.text = name;
//             emailController.text = email;
//             phoneController.text = phone;

//             localPreviewFile = null;
//             isImageReady = true;
//           });
//         } else {
//           // Document doesn't exist, but still stop loading indicator
//           setState(() {
//             isImageReady = true;
//           });
//         }
//       } catch (e) {
//         print('❌ Error loading user details: $e');
//         // Even on error, stop the loading spinner
//         setState(() {
//           isImageReady = true;
//         });
//       }
//     }
//   }

//   Future<void> pickAndUploadImage() async {
//     final picker = ImagePicker();
//     final pickedFile = await picker.pickImage(
//       source: ImageSource.gallery,
//       imageQuality: 70,
//     );

//     if (pickedFile != null) {
//       CroppedFile? croppedFile = await ImageCropper().cropImage(
//         sourcePath: pickedFile.path,
//         uiSettings: [
//           AndroidUiSettings(
//             toolbarTitle: 'Crop Image',
//             toolbarColor: Colors.black,
//             toolbarWidgetColor: Colors.white,
//             lockAspectRatio: false,
//           ),
//           IOSUiSettings(title: 'Crop Image'),
//         ],
//       );

//       if (croppedFile != null) {
//         final compressedBytes = await FlutterImageCompress.compressWithFile(
//           croppedFile.path,
//           quality: 50,
//         );

//         if (compressedBytes != null) {
//           final tempDir = Directory.systemTemp;
//           final tempFile = File(
//               '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
//           await tempFile.writeAsBytes(compressedBytes);

//           setState(() {
//             localPreviewFile = tempFile;
//           });

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
//           .child('${user!.uid}.jpg');

//       await ref.putFile(imageFile);
//       final downloadUrl = await ref.getDownloadURL();

//       final userDoc =
//           FirebaseFirestore.instance.collection('users').doc(user!.uid);

//       await userDoc.set({'profileUrl': downloadUrl}, SetOptions(merge: true));

//       await precacheImage(CachedNetworkImageProvider(downloadUrl), context);

//       setState(() {
//         profileImageUrl =
//             '$downloadUrl?ts=${DateTime.now().millisecondsSinceEpoch}';
//         localPreviewFile = null;
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('✅ Profile photo updated!')),
//       );
//     } catch (e) {
//       print('❌ Upload failed: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('⚠ Failed to update profile photo')),
//       );
//     }
//   }

//   void _navigateTo(BuildContext context, Widget screen) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => screen),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     ImageProvider imageProvider;

//     if (localPreviewFile != null) {
//       imageProvider = FileImage(localPreviewFile!);
//     } else if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
//       imageProvider = CachedNetworkImageProvider(profileImageUrl!);
//     } else {
//       imageProvider = const AssetImage('assets/default_avatar.png');
//     }

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: const Text("My Account", style: TextStyle(color: Colors.black)),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.black),
//       ),
//       body: isImageReady
//           ? ListView(
//               padding: const EdgeInsets.all(16),
//               children: [
//                 Row(
//                   children: [
//                     Stack(
//                       children: [
//                         CircleAvatar(
//                           radius: 32,
//                           backgroundImage: imageProvider,
//                           backgroundColor: Colors.grey[300],
//                         ),
//                         Positioned(
//                           bottom: 0,
//                           right: 0,
//                           child: InkWell(
//                             onTap: pickAndUploadImage,
//                             child: const CircleAvatar(
//                               radius: 14,
//                               backgroundColor: Colors.black,
//                               child: Icon(Icons.edit,
//                                   size: 14, color: Colors.white),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           TextField(
//                             controller: nameController,
//                             decoration:
//                                 const InputDecoration(labelText: 'Name'),
//                           ),
//                           TextField(
//                             controller: emailController,
//                             decoration:
//                                 const InputDecoration(labelText: 'Email'),
//                           ),
//                           TextField(
//                             controller: phoneController,
//                             decoration: const InputDecoration(
//                                 labelText: 'Phone Number'),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 24),
//                 ElevatedButton(
//                   onPressed: () async {
//                     if (user != null) {
//                       await FirebaseFirestore.instance
//                           .collection('users')
//                           .doc(user!.uid)
//                           .update({
//                         'name': nameController.text.trim(),
//                         'email': emailController.text.trim(),
//                         'phone': phoneController.text.trim(),
//                       });

//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                             content: Text('Profile updated successfully')),
//                       );
//                     }
//                   },
//                   child: const Text("Save Changes"),
//                 ),
//                 _buildListItem(
//                     context, "Orders", Icons.shopping_bag, const OrderScreen()),
//                 _buildListItem(context, "Customer Care", Icons.support_agent,
//                     const CustomerCareScreen()),
//                 _buildListItem(context, "Invite Friends & Earn",
//                     Icons.person_add, const InviteFriendsScreen(),
//                     subText: "You get ₹100 for every friend"),
//                 _buildListItem(context, "AJIO Wallet",
//                     Icons.account_balance_wallet, const WalletScreen(),
//                     subText: "Add Gift Card | Manage rewards and refunds"),
//                 _buildListItem(context, "Saved Cards", Icons.credit_card,
//                     const SavedCardsScreen()),
//                 _buildListItem(context, "My Rewards", Icons.card_giftcard,
//                     const RewardsScreen()),
//                 _buildListItem(context, "Address", Icons.location_on,
//                     const AddressScreen()),
//                 _buildListItem(context, "Notifications", Icons.notifications,
//                     const NotificationsScreen()),
//                 _buildListItem(context, "Return Creation Demo",
//                     Icons.replay_circle_filled, const ReturnDemoScreen()),
//                 _buildListItem(context, "How To Return", Icons.help_outline,
//                     const HowToReturnScreen()),
//                 _buildListItem(context, "How Do I Redeem My Coupon?",
//                     Icons.discount, const RedeemCouponScreen()),
//                 const SizedBox(height: 20),
//                 Center(
//                   child: ElevatedButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (context) => Login()),
//                       );
//                     },
//                     style: ElevatedButton.styleFrom(
//                       // Style move to correct position
//                       backgroundColor: Colors.white,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                         side: const BorderSide(color: Colors.grey),
//                       ),
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 50, vertical: 12),
//                     ),
//                     child: const Text(
//                       "Logout",
//                       style: TextStyle(color: Colors.black, fontSize: 16),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Center(
//                   child: ElevatedButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (context) => Login()),
//                       );
//                     },
//                     style: ElevatedButton.styleFrom(
//                       // Style move to correct position
//                       backgroundColor: Colors.white,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(5),
//                         side: const BorderSide(color: Colors.grey),
//                       ),
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 120, vertical: 14),
//                     ),
//                     child: const Text(
//                       "Become a Tailor",
//                       style: TextStyle(
//                         color: Colors.black,
//                         fontWeight: FontWeight.w400,
//                         fontSize: 16,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//               ],
//             )
//           : const Center(child: CircularProgressIndicator()),
//       bottomNavigationBar: BottomNavigationBar(
//         type: BottomNavigationBarType.fixed,
//         backgroundColor: Colors.white,
//         selectedItemColor: Colors.black,
//         unselectedItemColor: Colors.grey,
//         iconSize: 24,
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Store'),
//           BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Message'),
//           BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'TRNDx'),
//           BottomNavigationBarItem(
//               icon: Icon(Icons.shopping_cart), label: 'Order'),
//           BottomNavigationBarItem(
//               icon: Icon(Icons.account_circle), label: 'Account'),
//         ],
//         onTap: (index) {
//           switch (index) {
//             case 0:
//               Navigator.pushReplacement(context,
//                   MaterialPageRoute(builder: (context) => const Homepage()));
//               break;
//             case 1:
//               Navigator.pushReplacement(context,
//                   MaterialPageRoute(builder: (context) => const ChatScreen()));
//               break;
//             case 2:
//               Navigator.pushReplacement(context,
//                   MaterialPageRoute(builder: (context) => const PostList()));
//               break;
//             case 3:
//               Navigator.pushReplacement(context,
//                   MaterialPageRoute(builder: (context) => Orderpage()));
//               break;
//             case 4:
//               Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(
//                       builder: (context) => const AccountScreen()));
//               break;
//           }
//         },
//       ),
//     );
//   }

//   Widget _buildListItem(
//       BuildContext context, String title, IconData icon, Widget page,
//       {String? subText}) {
//     return ListTile(
//       leading: Icon(icon, color: Colors.black),
//       title: Text(title, style: const TextStyle(fontSize: 16)),
//       subtitle: subText != null
//           ? Text(subText,
//               style: const TextStyle(fontSize: 12, color: Colors.grey))
//           : null,
//       trailing:
//           const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
//       onTap: () {
//         _navigateTo(context, page);
//       },
//     );
//   }

//   void _openPage(Widget page) {
//     Navigator.push(context, MaterialPageRoute(builder: (context) => page));
//   }
// }

// /// *🔹 Dummy Screens for Navigation*
// class EditProfileScreen extends StatelessWidget {
//   const EditProfileScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar(title: Text("Edit Profile")),
//         body: Center(child: Text("Edit Profile Page")));
//   }
// }

// class OrderScreen extends StatelessWidget {
//   const OrderScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar(title: Text("My Orders")),
//         body: Center(child: Text("Orders Page")));
//   }
// }

// class CustomerCareScreen extends StatelessWidget {
//   const CustomerCareScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar(title: Text("Customer Care")),
//         body: Center(child: Text("Customer Care Page")));
//   }
// }

// class InviteFriendsScreen extends StatelessWidget {
//   const InviteFriendsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar(title: Text("Invite Friends")),
//         body: Center(child: Text("Invite Friends Page")));
//   }
// }

// class WalletScreen extends StatelessWidget {
//   const WalletScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar(title: Text("AJIO Wallet")),
//         body: Center(child: Text("Wallet Page")));
//   }
// }

// class SavedCardsScreen extends StatelessWidget {
//   const SavedCardsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar(title: Text("Saved Cards")),
//         body: Center(child: Text("Saved Cards Page")));
//   }
// }

// class RewardsScreen extends StatelessWidget {
//   const RewardsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar(title: Text("My Rewards")),
//         body: Center(child: Text("Rewards Page")));
//   }
// }

// class AddressScreen extends StatelessWidget {
//   const AddressScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar(title: Text("Address")),
//         body: Center(child: Text("Address Page")));
//   }
// }

// class NotificationsScreen extends StatelessWidget {
//   const NotificationsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar(title: Text("Notifications")),
//         body: Center(child: Text("Notifications Page")));
//   }
// }

// class ReturnDemoScreen extends StatelessWidget {
//   const ReturnDemoScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar(title: Text("Return Creation Demo")),
//         body: Center(child: Text("Return Demo Page")));
//   }
// }

// class HowToReturnScreen extends StatelessWidget {
//   const HowToReturnScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar(title: Text("How To Return")),
//         body: Center(child: Text("How To Return Page")));
//   }
// }

// class RedeemCouponScreen extends StatelessWidget {
//   const RedeemCouponScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar(title: Text("Redeem Coupon")),
//         body: Center(child: Text("Redeem Coupon Page")));
//   }
// }
