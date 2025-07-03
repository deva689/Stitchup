import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:stitchup/screen/account.dart/ChatScreen/ChatScreen.dart';
import 'package:stitchup/screen/account.dart/TRNdX/TRNDX.dart';
import 'package:stitchup/screen/account.dart/Accountscreen.dart';
import 'package:stitchup/screen/account.dart/home.dart/homepage.dart';
import 'package:stitchup/screen/account.dart/orderscreen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const Homepage(),
    ChatScreen(
      currentUserId: FirebaseAuth.instance.currentUser!.uid,
      contactsWithStories: [],
      localPreviewFile: null,
      profileImageUrl: '',
      isUploading: false, // ✅ should be a bool, not null
      uploadProgress: 0.0, // ✅ should be a double, not null
      contactUIDs: [],
      stories: [],
      onStoryTap: (String userId) {
        // Handle story tap
      },
      localContactNames: {},
    ),
    const XFeedScreen(),
    Orderpage(),
    const AccountScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.white,
        splashColor: Colors.white,
      ),
      child: Scaffold(
        backgroundColor: Color(0XFFFFFFFF),
        body: IndexedStack(index: _selectedIndex, children: _screens),
        bottomNavigationBar: SafeArea(
          top: false, // only care about bottom
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Color(0XFFF5F5F5),
                  width: 1,
                ),
              ),
            ),
            child: BottomNavigationBar(
              backgroundColor: Color(0XFFFFFFFF),
              type: BottomNavigationBarType.fixed,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              selectedItemColor: const Color(0xffFF5104),
              unselectedItemColor: const Color(0xFF404764),
              selectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Symbols.home, size: 24, weight: 500),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Symbols.message, size: 24, weight: 500),
                  label: 'Chat',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Symbols.owl, size: 24, weight: 500),
                  label: 'TRNDX',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Symbols.add_shopping_cart, size: 24, weight: 500),
                  label: 'Order',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Symbols.person, size: 24, weight: 500),
                  label: 'Account',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
