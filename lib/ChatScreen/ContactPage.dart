import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stitchup/ChatScreen/MessageScreen.dart' as screen1;

class ContactsOnStitchUp extends StatefulWidget {
  const ContactsOnStitchUp({super.key});

  @override
  State<ContactsOnStitchUp> createState() => _ContactsOnStitchUpState();
}

class _ContactsOnStitchUpState extends State<ContactsOnStitchUp> {
  List<Map<String, dynamic>> matchedUsers = [];
  List<Map<String, String>> unmatchedContacts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadContacts();
  }

  Future<void> loadContacts() async {
    setState(() => isLoading = true);
    await fetchMatchedContacts();
    await fetchUnregisteredContacts();
    setState(() => isLoading = false);
  }

  String normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10 ? digits.substring(digits.length - 10) : '';
  }

  Future<List<Map<String, String>>> getLocalContactNumbers() async {
    List<Map<String, String>> contactList = [];

    if (!await Permission.contacts.isGranted) {
      final result = await Permission.contacts.request();
      if (!result.isGranted) return [];
    }

    final hasPermission = await FlutterContacts.requestPermission();
    if (!hasPermission) return [];

    final contacts = await FlutterContacts.getContacts(withProperties: true);

    for (var contact in contacts) {
      for (var phone in contact.phones) {
        final normalized = normalizePhone(phone.number);
        if (normalized.isNotEmpty) {
          contactList.add({
            'name': contact.displayName,
            'phone': normalized,
          });
        }
      }
    }

    return contactList;
  }

  Future<void> fetchMatchedContacts() async {
    final localContacts = await getLocalContactNumbers();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final currentUserPhone = normalizePhone(currentUser.phoneNumber ?? '');
    final localPhones = localContacts.map((e) => e['phone']!).toList();

    final snapshot = await FirebaseFirestore.instance.collection('users').get();

    List<Map<String, dynamic>> matched = [];
    Set<String> matchedPhoneSet = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final uid = doc.id;

      final firestorePhone =
          normalizePhone(data['phone'] ?? data['normalizedPhone'] ?? '');

      if (firestorePhone.isEmpty ||
          firestorePhone == currentUserPhone ||
          !localPhones.contains(firestorePhone)) continue;

      matched.add({
        'uid': uid,
        'name': data['name'] ?? 'Unknown',
        'phone': firestorePhone,
        'photo': data['profileUrl'] ?? '',
        'isOnline': data['isOnline'] ?? false,
      });

      matchedPhoneSet.add(firestorePhone);
    }

    final unmatched = localContacts
        .where((c) => !matchedPhoneSet.contains(c['phone']))
        .toList();

    matchedUsers = matched;
    unmatchedContacts = unmatched;
  }

  Future<void> fetchUnregisteredContacts() async {
    final localContacts = await getLocalContactNumbers();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final currentUserPhone = normalizePhone(currentUser.phoneNumber ?? '');
    final snapshot = await FirebaseFirestore.instance.collection('users').get();

    Set<String> registeredPhones = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final firestorePhone = normalizePhone(data['phone'] ?? '');
      if (firestorePhone.isNotEmpty) {
        registeredPhones.add(firestorePhone);
      }
    }

    final unregistered = localContacts
        .where((c) =>
            !registeredPhones.contains(c['phone']) &&
            c['phone'] != currentUserPhone)
        .toList();

    unmatchedContacts = unregistered;
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
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Select contact", style: TextStyle(fontSize: 16)),
            Text("${matchedUsers.length} contacts",
                style: const TextStyle(
                    fontSize: 12, color: Color.fromARGB(255, 37, 37, 37))),
          ],
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Search logic
            },
          ),
          PopupMenuButton<String>(
            color: Colors.white,
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              // Handle each menu action
              switch (value) {
                case 'settings':
                  // Navigate to Contact Settings
                  break;
                case 'invite':
                  // Handle Invite a Friend
                  break;
                case 'contacts':
                  // Navigate to Contacts
                  break;
                case 'refresh':
                  // Refresh action
                  break;
                case 'help':
                  // Help section
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'settings',
                child: Text('Contact settings'),
              ),
              const PopupMenuItem<String>(
                value: 'invite',
                child: Text('Invite a friend'),
              ),
              const PopupMenuItem<String>(
                value: 'contacts',
                child: Text('Contacts'),
              ),
              const PopupMenuItem<String>(
                value: 'refresh',
                child: Text('Refresh'),
              ),
              const PopupMenuItem<String>(
                value: 'help',
                child: Text('Help'),
              ),
            ],
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                ...matchedUsers.map((user) {
                  final receiverId = user['uid'];
                  final chatId = generateChatId(currentUserId, receiverId);
                  final profileUrl = user['photo'];

                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: profileUrl.isNotEmpty
                          ? CachedNetworkImageProvider(
                              profileUrl.replaceFirst('?updated=', '&updated='))
                          : null,
                      child: profileUrl.isEmpty
                          ? Text(
                              (user['name'] ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            )
                          : null,
                    ),
                    title: Text(user['name']),
                    subtitle: Text(user['phone']),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => screen1.Messagescreen(
                            chatId: chatId,
                            receiverId: receiverId,
                            receiverName: user['name'],
                            profileUrl: profileUrl,
                          ),
                        ),
                      );
                    },
                  );
                }),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    "Invite to StitchUp",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                ListView.builder(
                  itemCount: unmatchedContacts.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final contact = unmatchedContacts[index];
                    final contactName = contact['name'] ?? 'Unknown';
                    final contactPhone = contact['phone'] ?? '';

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 2),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.grey[300],
                        child: Text(
                          contactName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      title: Text(contactName),
                      subtitle: Text(contactPhone),
                      trailing: TextButton(
                        onPressed: () {
                          Share.share(
                            'Hey! Join me on StitchUp for the best tailoring experience! Download here: https://play.google.com/store/apps/details?id=com.stitchup.app',
                          );
                        },
                        child: const Text(
                          "Invite",
                          style: TextStyle(color: Color(0xFF2C4152)),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}
