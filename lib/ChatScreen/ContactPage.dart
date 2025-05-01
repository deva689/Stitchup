import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stitchup/ChatScreen/MessageScreen.dart' as screen1;

class ContactsOnStitchUp extends StatefulWidget {
  const ContactsOnStitchUp({super.key});

  @override
  State<ContactsOnStitchUp> createState() => _ContactsOnStitchUpState();
}

class _ContactsOnStitchUpState extends State<ContactsOnStitchUp> {
  List<Map<String, dynamic>> matchedUsers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMatchedContacts();
  }

  String normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10 ? digits.substring(digits.length - 10) : '';
  }

  Future<List<String>> getLocalContactNumbers() async {
    Set<String> phoneSet = {};

    if (!await Permission.contacts.isGranted) {
      final result = await Permission.contacts.request();
      if (!result.isGranted) return [];
    }

    try {
      final hasPermission = await FlutterContacts.requestPermission();
      if (!hasPermission) return [];

      final contacts = await FlutterContacts.getContacts(withProperties: true);

      for (var contact in contacts) {
        for (var phone in contact.phones) {
          final normalized = normalizePhone(phone.number);
          if (normalized.isNotEmpty) {
            phoneSet.add(normalized);
          }
        }
      }

      return phoneSet.toList();
    } catch (e) {
      debugPrint("❌ Error getting contacts: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getMatchedUsers(
      List<String> localPhones) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    final currentUserPhone = normalizePhone(currentUser.phoneNumber ?? '');
    List<Map<String, dynamic>> matched = [];

    final snapshot = await FirebaseFirestore.instance.collection('users').get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final uid = doc.id;

      final firestorePhone =
          normalizePhone(data['phone'] ?? data['normalizedPhone'] ?? '');
      if (firestorePhone.isEmpty || firestorePhone == currentUserPhone) {
        continue;
      }

      if (localPhones.contains(firestorePhone)) {
        matched.add({
          'uid': uid,
          'name': data['name'] ?? 'Unknown',
          'phone': firestorePhone,
          'photo': data['profileUrl'] ?? '',
          'isOnline': data['isOnline'] ?? false,
          'lastSeen': data['lastSeen'],
          'isTypingTo': data['isTypingTo'] ?? '',
        });
      }
    }

    return matched;
  }

  Future<void> fetchMatchedContacts() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    final localNumbers = await getLocalContactNumbers();
    final users = await getMatchedUsers(localNumbers);

    if (!mounted) return; // <-- check again before calling setState

    setState(() {
      matchedUsers = users;
      isLoading = false;
    });
  }

  String generateChatId(String id1, String id2) {
    return id1.hashCode <= id2.hashCode ? '${id1}_$id2' : '${id2}_$id1';
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Select Contact", style: TextStyle(fontSize: 16)),
            Text("${matchedUsers.length} found on StitchUp",
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchMatchedContacts,
          ),
        ],
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : matchedUsers.isEmpty
              ? const Center(child: Text("No matched contacts found"))
              : ListView.builder(
                  itemCount: matchedUsers.length,
                  itemBuilder: (context, index) {
                    final user = matchedUsers[index];
                    final receiverId = user['uid'];
                    final receiverName = user['name'];
                    final profileUrl = user['photo'];

                    final chatId = generateChatId(currentUserId, receiverId);

                    return ListTile(
                      leading: profileUrl.isNotEmpty
                          ? CircleAvatar(
                              backgroundImage:
                                  CachedNetworkImageProvider(profileUrl),
                            )
                          : const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(receiverName),
                      subtitle: Text(user['phone']),
                      onTap: () {
                        if (receiverId.isEmpty || currentUserId.isEmpty) return;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => screen1.Messagescreen(
                              chatId: chatId,
                              receiverId: receiverId,
                              receiverName: receiverName,
                              profileUrl: profileUrl,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
