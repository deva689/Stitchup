import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stitchup/ChatScreen/ContactPage.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stitchup/ChatScreen/MessageScreen.dart';
import 'package:stitchup/widgets/StoriesWidget.dart';

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final List<Map<String, dynamic>> contactsWithStories;
  final File? localPreviewFile;
  final String? profileImageUrl;
  final bool isUploading;
  final double uploadProgress;

  final Map<String, String>? localContactNames; // assuming map of uid -> name
  final List<String>? contactUIDs; // list of contact user ids
  final List<dynamic>?
      stories; // your story objects list (adjust type as needed)
  final Function(String userId)?
      onStoryTap; // callback for story tap, passing userId
  final List<QueryDocumentSnapshot> chatDocs;

  const ChatScreen({
    super.key,
    required this.currentUserId,
    required this.contactsWithStories,
    required this.localPreviewFile,
    required this.profileImageUrl,
    required this.isUploading,
    required this.uploadProgress,
    required this.localContactNames,
    required this.contactUIDs,
    required this.stories,
    required this.onStoryTap,
    required this.chatDocs,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  File? localPreviewFile;
  String? profileImageUrl;
  bool isUploading = false;
  double uploadProgress = 0.0;
  List<String> yourFetchedContactUIDsFromFirestore = []; // your list of UIDs
  bool hasUploadedStory = false;
  String? myPhotoUrl;
  List<Map<String, dynamic>> contactsWithStories = [];
  StreamSubscription<QuerySnapshot>? _storySubscription;
  Timer? _debounceTimer;
  List<Map<String, dynamic>> otherStories = []; // ✅ Add this line
  List<String> contactUIDs = []; // example
  List<Map<String, dynamic>> stories = [];
  final ValueChanged<String> onStoryTap = (String userId) {};
  Map<String, String> localContactNames = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late String currentUserId = 'yourCurrentUserIdHere'; // replace accordingly

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser!.uid;

    // Load user profile and contacts stories in parallel
    WidgetsBinding.instance.addPostFrameCallback((_) {});
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _storySubscription?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Normalizes a phone number to last 10 digits (standard Indian-style).
  String normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10 ? digits.substring(digits.length - 10) : '';
  }

  Future<void> markMessageAsSeenAndSort(String chatId) async {
    final firestore = FirebaseFirestore.instance;
    final chatRef = firestore.collection('chats').doc(chatId);

    try {
      final chatSnap =
          await chatRef.get(const GetOptions(source: Source.server));
      final chatData = chatSnap.data();

      if (chatData == null || chatData['lastMessage'] == null) return;

      final lastMessage = chatData['lastMessage'];
      final String messageId = lastMessage['id'];
      final List<dynamic> seenByList = lastMessage['seenBy'] ?? [];

      if (seenByList.contains(currentUserId)) return;

      final batch = firestore.batch();

      batch.update(chatRef, {
        'lastMessage.seenBy': FieldValue.arrayUnion([currentUserId]),
        'unreadCounts.$currentUserId': 0,
        'lastUpdated': FieldValue.serverTimestamp(), // ✅ update this
      });

      final messageRef = chatRef.collection('messages').doc(messageId);
      batch.update(messageRef, {
        'seenBy': FieldValue.arrayUnion([currentUserId]),
      });

      await batch.commit();
    } catch (e) {
      debugPrint("❌ markMessageAsSeenAndSort error: $e");
    }
  }

  List<QueryDocumentSnapshot> filterAndSortChats({
    required String query,
    required List<QueryDocumentSnapshot> chatDocs,
  }) {
    final lowerQuery = query.toLowerCase();

    final startsWithMatches = <QueryDocumentSnapshot>[];
    final containsMatches = <QueryDocumentSnapshot>[];

    for (var doc in chatDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final participants = List<String>.from(data['participants'] ?? []);
      final otherUserId = participants.firstWhere(
        (id) => id != widget.currentUserId,
        orElse: () => '',
      );
      if (otherUserId.isEmpty) continue;

      final localName =
          widget.localContactNames?[otherUserId]?.toLowerCase() ?? '';
      final fallbackName = otherUserId.toLowerCase();

      final fullName = localName.isNotEmpty ? localName : fallbackName;

      if (fullName.startsWith(lowerQuery)) {
        startsWithMatches.add(doc);
      } else if (fullName.contains(lowerQuery)) {
        containsMatches.add(doc);
      }
    }

    // Sort both lists by lastMessage.timestamp
    int compareByTimestamp(QueryDocumentSnapshot a, QueryDocumentSnapshot b) {
      final timeA = (a.data() as Map<String, dynamic>)['lastMessage']
          ?['timestamp'] as Timestamp?;
      final timeB = (b.data() as Map<String, dynamic>)['lastMessage']
          ?['timestamp'] as Timestamp?;

      if (timeA == null && timeB == null) return 0;
      if (timeA == null) return 1;
      if (timeB == null) return -1;

      return timeB.compareTo(timeA);
    }

    startsWithMatches.sort(compareByTimestamp);
    containsMatches.sort(compareByTimestamp);

    return [...startsWithMatches, ...containsMatches];
  }

  List<QueryDocumentSnapshot> sortByLastMessage(
      List<QueryDocumentSnapshot> chats) {
    final sorted = List<QueryDocumentSnapshot>.from(chats);
    sorted.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;

      final timeA = (dataA['lastMessage']
          as Map<String, dynamic>?)?['timestamp'] as Timestamp?;
      final timeB = (dataB['lastMessage']
          as Map<String, dynamic>?)?['timestamp'] as Timestamp?;

      if (timeA == null && timeB == null) return 0;
      if (timeA == null) return 1;
      if (timeB == null) return -1;
      return timeB.compareTo(timeA);
    });
    return sorted;
  }

  Future<Map<String, Map<String, dynamic>>> buildUserMap(
    List<String> userIds,
  ) async {
    Map<String, Map<String, dynamic>> userMap = {};

    for (String uid in userIds) {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        userMap[uid] = {
          'displayName': data['name'] ?? '',
          'phoneNumber': data['phone'] ?? '',
        };
      }
    }

    return userMap;
  }

  @override
  Widget build(BuildContext context) {
    final chatsToDisplay = _searchQuery.isEmpty
        ? sortByLastMessage(widget.chatDocs)
        : filterAndSortChats(query: _searchQuery, chatDocs: widget.chatDocs);

    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
          title: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(widget.currentUserId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Text('Loading...',
                    style: TextStyle(color: Colors.black));
              }

              final userData = snapshot.data!.data() as Map<String, dynamic>;
              final userName = userData['name'] ?? 'Unknown';

              return Text(
                userName,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.black),
              onPressed: () {},
            ),
          ],
        ),
        body: Column(children: [
          Row(
            children: [
              Expanded(
                child: StoriesWidget(
                  currentUserId: currentUserId,
                  contactsWithStories: contactsWithStories,
                  localPreviewFile: localPreviewFile,
                  profileImageUrl: profileImageUrl,
                  isUploading: isUploading,
                  uploadProgress: uploadProgress,
                  contactUIDs: contactUIDs, // <--- these must be defined!
                  stories: stories,
                  onStoryTap: onStoryTap,
                  localContactNames: localContactNames,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Message",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                Icon(Icons.menu, color: Colors.black),
              ],
            ),
          ),
          SizedBox(height: 10),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey.shade600),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 16),
                      autocorrect: false,
                      autofocus: false,
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration.collapsed(
                        hintText: 'Search by name or number',
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.trim();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('participants', arrayContains: currentUserId)
                  .orderBy('lastUpdated', descending: true) // ✅ Use lastUpdated
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No chats found.'));
                }

                List<QueryDocumentSnapshot> chatDocs = snapshot.data!.docs;

                if (_searchQuery.isNotEmpty) {
                  chatDocs = filterAndSortChats(
                    query: _searchQuery,
                    chatDocs: chatDocs,
                  );
                }

                return ListView.builder(
                  itemCount: chatDocs.length,
                  itemBuilder: (context, index) {
                    final chatDoc = chatDocs[index];
                    final data = chatDoc.data() as Map<String, dynamic>;

                    final participants =
                        List<String>.from(data['participants'] ?? []);
                    final otherUserId = participants.firstWhere(
                      (id) => id != currentUserId,
                      orElse: () => '',
                    );
                    if (otherUserId.isEmpty) return const SizedBox();

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(otherUserId)
                          .get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData ||
                            !userSnapshot.data!.exists) {
                          return const SizedBox();
                        }

                        final userData =
                            userSnapshot.data!.data() as Map<String, dynamic>;

                        final lastMessage = data['lastMessage'] ?? {};
                        final messageText = lastMessage['text'] ?? '';
                        final senderId = lastMessage['senderId'] ?? '';
                        final isSentByCurrentUser = senderId == currentUserId;
                        final timestamp =
                            lastMessage['timestamp'] as Timestamp?;
                        final seenBy =
                            List<String>.from(lastMessage['seenBy'] ?? []);
                        final isSeen = seenBy.contains(otherUserId);

                        final unreadCounts = Map<String, dynamic>.from(
                            data['unreadCounts'] ?? {});
                        final unreadCount =
                            unreadCounts[currentUserId]?.toInt() ?? 0;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          onTap: () async {
                            await FirebaseFirestore.instance
                                .collection('chats')
                                .doc(chatDoc.id)
                                .update({
                              'lastMessage.seenBy':
                                  FieldValue.arrayUnion([currentUserId]),
                              'unreadCounts.$currentUserId': 0,
                              'lastUpdated':
                                  FieldValue.serverTimestamp(), // ✅ Update
                            });

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Messagescreen(
                                  chatId: chatDoc.id,
                                  receiverId: userData['uid'] ?? otherUserId,
                                  receiverName: userData['name'] ?? 'Unknown',
                                  profileUrl: userData['photoUrl'] ?? '',
                                  senderName: userData['name'] ?? 'Unknown',
                                ),
                              ),
                            );
                          },
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundImage: userData['photoUrl'] != null
                                ? NetworkImage(userData['photoUrl'])
                                : null,
                            child: userData['photoUrl'] == null
                                ? const Icon(Icons.person, size: 24)
                                : null,
                          ),
                          title: Text(
                            userData['name'] ?? userData['phone'] ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Row(
                            children: [
                              if (isSentByCurrentUser)
                                Icon(
                                  isSeen ? Icons.done_all : Icons.check,
                                  size: 18,
                                  color: isSeen ? Colors.blue : Colors.grey,
                                ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  messageText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: unreadCount > 0
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: unreadCount > 0
                                        ? Colors.black
                                        : Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                timestamp != null ? formatTime(timestamp) : '',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: unreadCount > 0
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: unreadCount > 0
                                      ? Colors.green
                                      : Colors.grey[600],
                                ),
                              ),
                              if (unreadCount > 0)
                                Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$unreadCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          )
        ]),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ContactsOnStitchUp()),
            );
          },
          child: const Icon(Icons.chat),
        ));
  }

  String formatTime(Timestamp timestamp) {
    final time = timestamp.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(time.year, time.month, time.day);

    if (messageDay == today) {
      return DateFormat.jm().format(time); // 5:30 PM
    } else {
      return DateFormat('MMM d').format(time); // May 18
    }
  }
}

Map<String, dynamic> buildStatusData({
  required String url,
  required String caption,
  required Color selectedColor,
  required String selectedFont,
  required TextAlign textAlign,
  required bool highlightMode,
  required Color highlightColor,
}) {
  return {
    'url': url,
    'caption': caption,
    'selectedColor': selectedColor.value, // Store as int for Firestore
    'selectedFont': selectedFont,
    'textAlign': textAlign.index, // Store enum as int
    'highlightMode': highlightMode,
    'highlightColor': highlightColor.value, // Store as int
  };
}

// Optional: Sort default (non-search) chat list by last message time
List<QueryDocumentSnapshot> sortByLastMessage(
    List<QueryDocumentSnapshot> chats) {
  final sorted = List<QueryDocumentSnapshot>.from(chats);
  sorted.sort((a, b) {
    final dataA = a.data()! as Map<String, dynamic>;
    final dataB = b.data()! as Map<String, dynamic>;
    final timeA = dataA['lastMessage']?['timestamp'] as Timestamp?;
    final timeB = dataB['lastMessage']?['timestamp'] as Timestamp?;

    if (timeA == null && timeB == null) return 0;
    if (timeA == null) return 1;
    if (timeB == null) return -1;

    return timeB.compareTo(timeA);
  });
  return sorted;
}
