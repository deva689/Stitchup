// import 'package:flutter/material.dart';
// import 'package:flutter_google_maps_webservices/places.dart';

// const kGoogleApiKey = "AIzaSyBGDXy5ERMMbou89SP7NLw3M4MQk_L2olM";

// class LocationSearchDelegate extends SearchDelegate<String> {
//   final GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: kGoogleApiKey);

//   @override
//   String get searchFieldLabel => "Search your area...";

//   @override
//   List<Widget>? buildActions(BuildContext context) {
//     return [
//       if (query.isNotEmpty)
//         IconButton(
//           icon: Icon(Icons.clear),
//           onPressed: () => query = '',
//         ),
//     ];
//   }

//   @override
//   Widget? buildLeading(BuildContext context) {
//     return IconButton(
//       icon: Icon(Icons.arrow_back),
//       onPressed: () => close(context, ''),
//     );
//   }

//   @override
//   Widget buildResults(BuildContext context) {
//     return Container(); // We return result on tap itself in suggestions.
//   }

//   @override
//   Widget buildSuggestions(BuildContext context) {
//     if (query.isEmpty) {
//       return Center(child: Text("Start typing to search..."));
//     }

//     return FutureBuilder<PlacesAutocompleteResponse>(
//       future: _places.autocomplete(query),
//       builder: (context, snapshot) {
//         if (!snapshot.hasData)
//           return Center(child: CircularProgressIndicator());

//         final suggestions = snapshot.data!.predictions;

//         return ListView.builder(
//           itemCount: suggestions.length,
//           itemBuilder: (context, index) {
//             final suggestion = suggestions[index];
//             return ListTile(
//               title: Text(suggestion.description ?? ""),
//               onTap: () {
//                 close(context, suggestion.description ?? "");
//               },
//             );
//           },
//         );
//       },
//     );
//   }
// }
