import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:stitchup/screen/account.dart/TRNdX/ComposePostScreen.dart';

class XFeedScreen extends StatefulWidget {
  const XFeedScreen({Key? key}) : super(key: key);

  @override
  State<XFeedScreen> createState() => _XFeedScreenState();
}

class _XFeedScreenState extends State<XFeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Position? _currentPosition;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = position;
    });
  }

  Stream<List<DocumentSnapshot>> _getPostsStream() {
    final query = FirebaseFirestore.instance
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots();

    return query.asyncMap((snapshot) async {
      if (_tabController.index == 1 || _currentPosition == null) {
        return snapshot.docs;
      }

      // Filter by 10 km using GeoPoint
      final nearby = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('location') && data['location'] is GeoPoint) {
          final GeoPoint point = data['location'];
          final distance = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            point.latitude,
            point.longitude,
          );
          return distance <= 10000; // 10 km
        }
        return false;
      }).toList();

      return nearby;
    });
  }

  void _showPostDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Post something"),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: "What's happening?",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final text = controller.text.trim();
              final user = _auth.currentUser;
              if (text.isNotEmpty && user != null && _currentPosition != null) {
                await FirebaseFirestore.instance.collection('posts').add({
                  'text': text,
                  'timestamp': Timestamp.now(),
                  'uid': user.uid,
                  'location': GeoPoint(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                  ),
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Post"),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final text = data['text'] ?? '';
    final timestamp = data['timestamp'] as Timestamp?;
    final time = timestamp != null
        ? TimeOfDay.fromDateTime(timestamp.toDate()).format(context)
        : 'Unknown time';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 10),
                Text(
                  time,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 2,
        title:
            const Text("X Feed", style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          tabs: const [
            Tab(text: "10 km"),
            Tab(text: "India"),
          ],
        ),
      ),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<DocumentSnapshot>>(
              stream: _getPostsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No posts available"));
                }

                final posts = snapshot.data!;
                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) => _buildPostCard(posts[index]),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ComposePostScreen()),
          );
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
    );
  }
}
