import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:stitchup/screen/account.dart/ChatScreen/ChatScreen.dart';
import 'package:stitchup/screen/account.dart/Accountscreen.dart';
import 'package:stitchup/widgets/MyStatusScreen.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final StreamController<List<User>> _controller = StreamController.broadcast();
  String? profileImageUrl;
  List<Map<String, dynamic>> contactsWithStories = [];
  bool isUploading = false;
  double uploadProgress = 0.0;
  File? localPreviewFile;

  List<String> yourFetchedContactUIDsFromFirestore = []; // your list of UIDs
  bool hasUploadedStory = false;
  String? myPhotoUrl;
  bool isImageReady = false;
  List<Map<String, dynamic>> stories = [];
  bool isStoryLoading = false;
  bool isStoryUploading = false;
  Map<String, String> localContactNames = {};

  String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  User? user; // 👈 This is needed!

  bool isTextEmpty = true;
  bool _streamBound = false;

  int selectedFilterIndex = 0;
  final List<String> filters = [
    'TOP RATED',
    'NEAR ME',
    'AVAILABLE',
    'FAMILIAR'
  ];

  String? currentAddress = "Fetching location...";
  String? locality = "";
  String? city = "";
  Position? currentPosition;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    _checkPermissionAndGetLocation();

    _searchController.addListener(() {
      setState(() {
        isTextEmpty = _searchController.text.isEmpty;
      });
    });

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    //     systemNavigationBarColor: Colors.white,
    //     systemNavigationBarIconBrightness: Brightness.dark,
    //     statusBarColor: Colors.transparent,
    //     statusBarIconBrightness: Brightness.dark,
    //   ));
    // });
  }

  void loadUsers() {
    if (!_streamBound) {
      final stream = FirebaseFirestore.instance.collection('users').snapshots();
      _controller.addStream(stream as Stream<List<User>>);
      _streamBound = true;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionAndGetLocation();
    }
  }

  Future<void> _checkPermissionAndGetLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          currentAddress =
              "Permission permanently denied. Please enable it in settings.";
        });
        return;
      }

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

        if (!serviceEnabled) {
          if (!mounted) return;
          setState(() {
            currentAddress = "Location services are disabled.";
          });
          return;
        }

        await _getLocation(); // ✅ Safe call
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        currentAddress = "Error checking permission: $e";
      });
    }
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

  Future<void> _getLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        final formattedAddress = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.postalCode,
        ].where((e) => e != null && e.isNotEmpty).join(", ");

        setState(() {
          currentAddress = formattedAddress;
          locality = place.subLocality ?? "";
          city = place.locality ?? "";
          currentPosition = position;
        });
      } else {
        setState(() {
          currentAddress = "Unable to fetch address.";
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        currentAddress = "Error fetching location: $e";
      });
    }
  }

  void onFilterTap(int index) {
    setState(() {
      selectedFilterIndex = index;
    });

    switch (filters[index]) {
      case 'TOP RATED':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => Placeholder()));
        break;
      case 'NEAR ME':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const Placeholder()));
        break;
      case 'AVAILABLE':
        Navigator.push(context, MaterialPageRoute(builder: (_) => SearchBar()));
        break;
      case 'FAMILIAR':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const AccountScreen()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar icons
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Home icon + Location info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const SizedBox(height: 1),
                            Transform.rotate(
                                angle: 0.7, // rotate to mimic the style
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const Placeholder()),
                                    );
                                  },
                                  child: Icon(
                                    Icons.navigation_rounded,
                                    color: Color(0xFFFF6600), // Orange
                                    size: 26,
                                  ),
                                )),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const Placeholder()),
                                );
                              },
                              child: Text(
                                locality ?? "Locating...",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const Placeholder()),
                                );
                              },
                              child: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 20,
                                  color: Colors.black54),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Padding(
                          padding:
                              const EdgeInsets.only(left: 8), // Align with text

                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const Placeholder()),
                              );
                            },
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const Placeholder()),
                                );
                              },
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const Placeholder()),
                                  );
                                },
                                child: Text(
                                  currentAddress ?? "Fetching location...",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black54,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.favorite_border),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_none),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.shopping_bag_outlined),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Swiggy-style Address Row
              Stack(
                children: [
                  // Search Field
                  SizedBox(
                    height: 54,
                    width: double.infinity,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: const Icon(Icons.mic),
                        filled: true,
                        fillColor: const Color(0xFFF3F4F6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        hintText: '', // real hint from animation
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),

                  // Animated Hint Text
                  if (isTextEmpty)
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.only(
                            left: 48, right: 48, bottom: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Search for ',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(
                                height: 20,
                                child: AnimatedTextKit(
                                  animatedTexts: [
                                    TyperAnimatedText('"Shirt specialist"',
                                        speed: Duration(milliseconds: 60),
                                        textStyle: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 14)),
                                    TyperAnimatedText('"Pant specialist"',
                                        speed: Duration(milliseconds: 60),
                                        textStyle: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 14)),
                                    TyperAnimatedText('"Kurtis specialist"',
                                        speed: Duration(milliseconds: 60),
                                        textStyle: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 14)),
                                    TyperAnimatedText('"Blouse specialist"',
                                        speed: Duration(milliseconds: 60),
                                        textStyle: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 14)),
                                  ],
                                  isRepeatingAnimation: true,
                                  repeatForever: true,
                                  pause: Duration(milliseconds: 1000),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  const Text(
                    "WHAT'S IN YOUR SEWING ?",
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Divider(
                      color: Colors.grey.shade400, // light professional color
                      thickness: 1, // thickness of the line
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 16,
              ),
              const Text("MEN", style: TextStyle(fontWeight: FontWeight.w400)),
              const SizedBox(height: 6),
              _buildCategoryRow(['Shirts', 'Pants', 'Kurtas', 'Ethnic wear']),

              const SizedBox(height: 10),
              const Text("Women",
                  style: TextStyle(fontWeight: FontWeight.w400)),
              const SizedBox(height: 6),
              _buildCategoryRow(['Shirts', 'Pants', 'Kurti', 'Blouse']),

              const SizedBox(height: 20),

              // Filter Chips Scroll
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(filters.length, (index) {
                    final isSelected = selectedFilterIndex == index;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: GestureDetector(
                        onTap: () => onFilterTap(index),
                        child: Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color:
                                isSelected ? Colors.black : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                          child: Text(
                            filters[index],
                            style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: FontWeight.w400,
                                fontSize: 12),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 20),

              const Text("Top dressmaker to explore",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),

              // Dressmaker list
              // Row(
              //   children: [
              //     _buildDressmakerCard(
              //         "Porel dressmaker",
              //         "Ethnic wear, blouse",
              //         "Chithalapakkam 1.1 km",
              //         4.3,
              //         "1.9k"),

              //     const SizedBox(width: 12),
              //     _buildDressmakerCard( "Ava tailor shop",
              //         "kurtas, kurta & more", "Selaiyur 1.1 km", 4.6, "3.1k"),
              //   ],
              // )
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildCategoryRow(List<String> titles) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: titles.map((title) {
      return Column(
        children: [
          CircleAvatar(radius: 25, backgroundColor: Colors.grey.shade300),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 12)),
        ],
      );
    }).toList(),
  );
}

Widget _buildDressmakerCard(String image, String name, String desc,
    String location, double rating, String reviews) {
  return Expanded(
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dummy image box
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              image: DecorationImage(
                image: AssetImage(image),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.star, size: 14, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text("$rating", style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text("($reviews)",
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(desc,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(location,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          )
        ],
      ),
    ),
  );
}
