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
