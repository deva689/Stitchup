import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class ComposePostScreen extends StatefulWidget {
  const ComposePostScreen({Key? key}) : super(key: key);

  @override
  State<ComposePostScreen> createState() => _ComposePostScreenState();
}

class _ComposePostScreenState extends State<ComposePostScreen> {
  final TextEditingController _controller = TextEditingController();
  bool isPosting = false;

  Future<void> _submitPost() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => isPosting = true);

    final user = FirebaseAuth.instance.currentUser;
    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    await FirebaseFirestore.instance.collection('posts').add({
      'text': text,
      'timestamp': Timestamp.now(),
      'uid': user?.uid,
      'location': GeoPoint(position.latitude, position.longitude),
    });

    setState(() => isPosting = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final userPhoto = FirebaseAuth.instance.currentUser?.photoURL;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: isPosting ? null : _submitPost,
            child: const Text("Post", style: TextStyle(fontSize: 16)),
          )
        ],
      ),
      body: Column(
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage:
                      userPhoto != null ? NetworkImage(userPhoto) : null,
                  child: userPhoto == null ? const Icon(Icons.person) : null,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.public, size: 16, color: Colors.blue),
                    SizedBox(width: 4),
                    Text("Everyone", style: TextStyle(color: Colors.blue)),
                    Icon(Icons.arrow_drop_down, color: Colors.blue),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _controller,
              maxLines: null,
              style: const TextStyle(fontSize: 20),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: "What's happening?",
              ),
            ),
          ),
          const Spacer(),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: const [
                Icon(Icons.image, color: Colors.blue),
                SizedBox(width: 20),
                Icon(Icons.gif_box_outlined, color: Colors.blue),
                SizedBox(width: 20),
                Icon(Icons.poll, color: Colors.blue),
                SizedBox(width: 20),
                Icon(Icons.location_on, color: Colors.blue),
                SizedBox(width: 20),
                Icon(Icons.circle_outlined, color: Colors.blue),
                SizedBox(width: 20),
                Icon(Icons.add_circle_outline, color: Colors.blue),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
