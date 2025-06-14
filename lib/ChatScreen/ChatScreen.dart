import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stitchup/ChatScreen/ContactPage.dart';
import 'package:stitchup/ChatScreen/MessageScreen.dart';
import 'package:stitchup/models/StatusViewScreen.dart';
import 'package:stitchup/widgets/StoriesWidget.dart';

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final List<Map<String, dynamic>> contactsWithStories;
  final File? localPreviewFile;
  final String? profileImageUrl;
  final bool isUploading;
  final double uploadProgress;
  final List<String> contactUIDs;
  final List<Map<String, dynamic>> stories;
  final Function(String userId) onStoryTap;
  final Map<String, String> localContactNames;

  const ChatScreen({
    Key? key,
    required this.currentUserId,
    required this.contactsWithStories,
    required this.localPreviewFile,
    required this.profileImageUrl,
    required this.isUploading,
    required this.uploadProgress,
    required this.contactUIDs,
    required this.stories,
    required this.onStoryTap,
    required this.localContactNames,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  File? localPreviewFile;
  String? profileImageUrl;
  bool isUploading = false;
  double uploadProgress = 0.0;
  bool hasUploadedStory = false;
  String? myPhotoUrl;
  List<Map<String, dynamic>> contactsWithStories = [];
  List<Map<String, dynamic>> otherStories = [];
  late String currentUserId;
  bool _isFetchingStories = false;
  Timer? _debounceTimer;
  StreamSubscription<QuerySnapshot>? _storySubscription;
  final Map<String, Map<String, dynamic>> _userCache = {};
  bool _isFetchingUsers = false;

  @override
  void dispose() {
    _storySubscription?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void triggerFetchStories() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 10), () {});
  }

  String sanitizeUrl(String? url) {
    return (url != null && url.startsWith('http')) ? url : '';
  }

  Future<void> fetchUsersIfNeeded(List<String> userIds) async {
    final missingUserIds =
        userIds.where((id) => !_userCache.containsKey(id)).toList();

    if (missingUserIds.isEmpty || _isFetchingUsers) return;

    _isFetchingUsers = true;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId,
              whereIn: missingUserIds.take(10).toList())
          .get();

      for (var doc in snapshot.docs) {
        _userCache[doc.id] = doc.data();
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('⚠️ User fetch error: $e');
    } finally {
      _isFetchingUsers = false;
    }
  }

  Future<void> markMessageAsSeen(
      {required String chatId, required String currentUserId}) async {
    final firestore = FirebaseFirestore.instance;
    final chatRef = firestore.collection('chats').doc(chatId);

    try {
      final chatSnap =
          await chatRef.get(const GetOptions(source: Source.server));
      final chatData = chatSnap.data();
      if (chatData == null) return;

      final lastMessage = chatData['lastMessage'] as Map<String, dynamic>?;
      if (lastMessage == null) return;

      final messageId = lastMessage['id'] as String?;
      if (messageId == null) return;

      final seenByList = List<String>.from(lastMessage['seenBy'] ?? []);
      if (seenByList.contains(currentUserId)) return;

      final batch = firestore.batch();

      batch.update(chatRef, {
        'lastMessage.seenBy': FieldValue.arrayUnion([currentUserId]),
        'unreadCounts.$currentUserId': 0,
      });

      final messageRef = chatRef.collection('messages').doc(messageId);
      batch.update(messageRef, {
        'seenBy': FieldValue.arrayUnion([currentUserId]),
      });

      await batch.commit();
    } catch (e) {
      debugPrint("❌ markMessageAsSeen error: $e");
    }
  }

  String formatTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays >= 1) {
      return "${date.day}/${date.month}/${date.year}";
    } else {
      return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    ImageProvider imageProvider;
    try {
      if (widget.localPreviewFile != null) {
        imageProvider = FileImage(widget.localPreviewFile!);
      } else if ((widget.profileImageUrl ?? '').isNotEmpty) {
        imageProvider = CachedNetworkImageProvider(widget.profileImageUrl!);
      } else {
        imageProvider = const AssetImage('assets/default_avatar.png');
      }
    } catch (e) {
      print('⚠️ Error loading image: $e');
      imageProvider = const AssetImage('assets/default_avatar.png');
    }

    return Scaffold(
      backgroundColor: Colors.white,
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
                  color: Colors.black, fontWeight: FontWeight.w600),
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
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.10 > 100
                ? 100
                : MediaQuery.of(context).size.height * 0.10,
            child: StoriesWidget(
              currentUserId: currentUserId,
              onStoryTap: (userId) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StatusViewScreen(
                      statusList: [
                        {
                          'type': 'image',
                          'url': 'https://example.com/story1.jpg'
                        },
                        {'type': 'text', 'text': 'Hello from day 2!'},
                      ],
                      userName: 'John Doe',
                      profileImage: 'https://example.com/profile.jpg',
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Message",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Icon(Icons.menu, color: Colors.black),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('participants', arrayContains: currentUserId)
                  .orderBy('lastMessage.timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No chats found.'));
                }

                final chatDocs = snapshot.data!.docs;
                final otherUserIds = chatDocs
                    .map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final participants =
                          List<String>.from(data['participants'] ?? []);
                      return participants.firstWhere(
                          (id) => id != currentUserId,
                          orElse: () => '');
                    })
                    .where((id) => id.isNotEmpty)
                    .toSet()
                    .toList();

                fetchUsersIfNeeded(otherUserIds);

                return ListView.builder(
                  itemCount: chatDocs.length,
                  itemBuilder: (context, index) {
                    final chatDoc = chatDocs[index];
                    final data = chatDoc.data() as Map<String, dynamic>;
                    final participants =
                        List<String>.from(data['participants'] ?? []);
                    final otherUserId = participants.firstWhere(
                        (id) => id != currentUserId,
                        orElse: () => '');

                    final userData = _userCache[otherUserId];
                    if (userData == null) return const SizedBox();

                    final lastMessage = data['lastMessage'] ?? {};
                    final messageText = lastMessage['text'] ?? '';
                    final senderId = lastMessage['senderId'] ?? '';
                    final isSentByCurrentUser = senderId == currentUserId;
                    final timestamp = lastMessage['timestamp'] as Timestamp?;
                    final seenBy =
                        List<String>.from(lastMessage['seenBy'] ?? []);
                    final isSeen = seenBy.contains(currentUserId);

                    final unreadCounts = data['unreadCounts'] ?? {};
                    final unreadCount =
                        unreadCounts[currentUserId]?.toInt() ?? 0;
                    final profileUrl = sanitizeUrl(userData['profileUrl']);

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
                        });

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Messagescreen(
                              chatId: chatDoc.id,
                              receiverId: otherUserId,
                              receiverName: userData['name'] ?? 'Unknown',
                              profileUrl: userData['photoUrl'] ?? '',
                            ),
                          ),
                        );
                      },
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: profileUrl.isNotEmpty
                            ? CachedNetworkImageProvider(profileUrl)
                            : null,
                        child: profileUrl.isEmpty
                            ? Text(
                                (userData['name'] ?? 'U')[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              )
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
                              color:
                                  unreadCount > 0 ? Colors.green : Colors.grey,
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
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null, // disables hero animation
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ContactsOnStitchUp()),
          );
        },
        child: const Icon(Icons.chat),
      ),
    );
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

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final chatRef = firestore.collection('chats').doc(chatId);
    final messageRef = chatRef.collection('messages').doc(); // Auto ID
    final messageId = messageRef.id;

    final timestamp = FieldValue.serverTimestamp();

    final messageData = {
      'id': messageId,
      'text': text,
      'senderId': senderId,
      'timestamp': timestamp,
      'seenBy': [senderId],
      'type': 'text',
    };

    final batch = firestore.batch();

    // 1️⃣ Add message to subcollection
    batch.set(messageRef, messageData);

    // 2️⃣ Update chat document (required fields for ChatListScreen)
    batch.set(
        chatRef,
        {
          'participants': [senderId, receiverId],
          'users': [senderId, receiverId], // optional
          'createdAt': timestamp,
          'lastMessage': messageData, // includes timestamp
          'unreadCounts': {
            senderId: 0,
            receiverId: FieldValue.increment(1),
          },
        },
        SetOptions(merge: true));

    // 3️⃣ Commit all
    await batch.commit();
  }
}
