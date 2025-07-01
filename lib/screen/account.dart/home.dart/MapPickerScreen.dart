// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geocoding/geocoding.dart';

// class MapPickerScreen extends StatefulWidget {
//   final LatLng initialPosition;
//   final Function(String) onAddressSelected;

//   const MapPickerScreen({
//     required this.initialPosition,
//     required this.onAddressSelected,
//   });

//   @override
//   State<MapPickerScreen> createState() => _MapPickerScreenState();
// }

// class _MapPickerScreenState extends State<MapPickerScreen> {
//   late GoogleMapController _controller;
//   late LatLng _currentPosition;

//   @override
//   void initState() {
//     super.initState();
//     _currentPosition = widget.initialPosition;
//   }

//   Future<void> _onMapTapped(LatLng latLng) async {
//     setState(() {
//       _currentPosition = latLng;
//     });
//   }

//   Future<void> _confirmAddress() async {
//     List<Placemark> placemarks = await placemarkFromCoordinates(
//       _currentPosition.latitude,
//       _currentPosition.longitude,
//     );
//     String address =
//         "${placemarks.first.name}, ${placemarks.first.locality}, ${placemarks.first.postalCode}";
//     widget.onAddressSelected(address);
//     Navigator.pop(context);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Pick Location")),
//       body: Stack(
//         children: [
//           GoogleMap(
//             initialCameraPosition: CameraPosition(
//               target: _currentPosition,
//               zoom: 16,
//             ),
//             onMapCreated: (controller) => _controller = controller,
//             onTap: _onMapTapped,
//             markers: {
//               Marker(markerId: MarkerId("current"), position: _currentPosition),
//             },
//           ),
//           Positioned(
//             bottom: 20,
//             left: 20,
//             right: 20,
//             child: ElevatedButton(
//               onPressed: _confirmAddress,
//               child: Text("Enter This Location"),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
