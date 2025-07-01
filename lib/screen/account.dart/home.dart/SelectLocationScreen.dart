// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:stitchup/home.dart/LocationSearchDelegate.dart';
// import 'package:stitchup/home.dart/MapPickerScreen.dart';

// class SelectLocationScreen extends StatefulWidget {
//   const SelectLocationScreen({super.key});

//   @override
//   State<SelectLocationScreen> createState() => _SelectLocationScreenState();
// }

// class _SelectLocationScreenState extends State<SelectLocationScreen> {
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
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         title: const Text(
//           "Enter your area or apartment name",
//           style: TextStyle(fontSize: 20),
//         ),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             TextField(
//               readOnly: true,
//               onTap: openSearch,
//               decoration: InputDecoration(
//                 hintText: 'Try JP Nagar, Siri Gardenia, etc.',
//                 prefixIcon: Icon(Icons.search),
//                 border:
//                     OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//               ),
//             ),
//             const SizedBox(height: 20),
//             ListTile(
//               leading: Icon(Icons.navigation, color: Colors.orange),
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
//             const SizedBox(height: 10),
//             const Text("SAVED ADDRESSES",
//                 style: TextStyle(fontWeight: FontWeight.bold)),
//             const SizedBox(height: 10),
//             ...savedAddresses.map((address) => addressTile(address)),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget addressTile(String address) {
//     return ListTile(
//       leading: Icon(Icons.location_on, color: Colors.black),
//       title: Row(
//         children: [
//           Expanded(child: Text(address)),
//           if (selectedAddress == address)
//             Container(
//               margin: EdgeInsets.only(left: 8),
//               padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//               decoration: BoxDecoration(
//                 color: Colors.green.shade100,
//                 borderRadius: BorderRadius.circular(4),
//               ),
//               child: Text("CURRENTLY SELECTED", style: TextStyle(fontSize: 10)),
//             ),
//         ],
//       ),
//       onTap: () => selectAddress(address),
//     );
//   }
// }
