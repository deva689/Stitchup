import 'dart:async';
import 'dart:io';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
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
  Timer? _debounceTimer;
  StreamSubscription<QuerySnapshot>? _storySubscription;
  final Map<String, Map<String, dynamic>> _userCache = {};
  Map<String, Map<String, dynamic>> userDataMap = {};
  Set<String> selectedChats = {};
  String? myProfileUrl;
  String? selectedChatId;
  TextEditingController controller = TextEditingController();
  Function(String)? onChanged;
  bool isTextEmpty = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        isTextEmpty = _searchController.text.isEmpty;
      });
    });
  }

  @override
  void dispose() {
    _storySubscription?.cancel();
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void triggerFetchStories() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 10), () {});
  }

  String sanitizeUrl(String url) {
    final parts = url.split('?');
    if (parts.length < 3) return url;
    return '${parts[0]}?${parts[1]}'; // removes '?updated=...'
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

    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    final difference = today.difference(messageDate).inDays;

    if (difference == 0) {
      return DateFormat('h:mm a').format(date); // today
    } else if (difference == 1) {
      return 'Yesterday';
    } else {
      return DateFormat('dd/MM/yy').format(date); // older
    }
  }

  Future<void> fetchMyProfile() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUserId)
        .get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        myProfileUrl = data['profileUrl'] ?? '';
      });
    }
  }

  void toggleSelection(String chatId) {
    setState(() {
      if (selectedChats.contains(chatId)) {
        selectedChats.remove(chatId);
      } else {
        selectedChats.add(chatId);
      }
    });
  }

  void clearSelection() {
    setState(() {
      selectedChats.clear();
      selectedChatId = null;
    });
  }

  ImageProvider getProfileImage(String? url) {
    if (url == null || url.isEmpty || !url.startsWith('http')) {
      return const AssetImage('assets/default_avatar.png');
    }
    return CachedNetworkImageProvider(url);
  }

  Future<void> deleteChat(String chatId) async {
    try {
      await FirebaseFirestore.instance.collection('chats').doc(chatId).delete();
      setState(() {
        selectedChatId = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting chat: $e')),
      );
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
      appBar: selectedChats.isEmpty
          ? AppBar(
              automaticallyImplyLeading: true,
              backgroundColor: Colors.white,
              elevation: 0,
              actionsIconTheme: const IconThemeData(color: Colors.black),
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
                  final userData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  final userName = userData['name'] ?? 'Unknown';
                  return Text(
                    userName,
                    style: const TextStyle(
                        color: Color.fromARGB(255, 0, 0, 0),
                        fontWeight: FontWeight.w600),
                  );
                },
              ),
              actions: [
                PopupMenuButton<String>(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  icon: const Icon(Icons.more_vert, color: Colors.black),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  color: Colors.white,
                  elevation: 1,
                  onSelected: (value) {
                    // Handle selection
                    debugPrint('Selected: $value');
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem(
                      value: 'New group',
                      child: Text('New group',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w400)),
                    ),
                    PopupMenuItem(
                      value: 'New broadcast',
                      child: Text('New broadcast',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w400)),
                    ),
                    PopupMenuItem(
                      value: 'Linked devices',
                      child: Text('Linked devices',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w400)),
                    ),
                    PopupMenuItem(
                      value: 'Starred',
                      child: Text('Starred',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w400)),
                    ),
                    PopupMenuItem(
                      value: 'Payments',
                      child: Text('Payments',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w400)),
                    ),
                    PopupMenuItem(
                      value: 'Read all',
                      child: Text('Read all',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w400)),
                    ),
                    PopupMenuItem(
                      value: 'Settings',
                      child: Text('Settings',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w400)),
                    ),
                  ],
                ),
              ],
            )
          : AppBar(
              backgroundColor: Color(0xFF00A884), // WhatsApp green
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: clearSelection,
              ),
              title: Text(
                "${selectedChats.length}", // number of selected chats
                style: const TextStyle(color: Colors.white),
              ),
              actions: [
                const Icon(Icons.push_pin_outlined, color: Colors.white),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                  onPressed: () {
                    if (selectedChatId != null) {
                      deleteChat(selectedChatId!);
                    }
                  },
                ),
                const SizedBox(width: 12),
                const Icon(Icons.notifications_off_outlined,
                    color: Colors.white),
                const SizedBox(width: 12),
                const Icon(Icons.archive_outlined, color: Colors.white),
                const SizedBox(width: 8),
              ],
            ),
      body: CustomScrollView(
        slivers: [
          /// 🟡 Stories Section
          SliverToBoxAdapter(
            child: SizedBox(
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
          ),

          /// 🟡 Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
              child: Stack(
                children: [
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
                        hintText: '',
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  if (isTextEmpty)
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.only(
                            left: 48, right: 48, bottom: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Search for contacts',
                            style:
                                TextStyle(color: Colors.black54, fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          /// 🟡 Header Title
          SliverToBoxAdapter(
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Message",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),

          /// 🔵 Chat List
          SliverFillRemaining(
            hasScrollBody: true,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('participants', arrayContains: widget.currentUserId)
                  .orderBy('lastMessage.timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No chats found.'));
                }

                final chatDocs = snapshot.data!.docs;
                final otherUserIds = chatDocs
                    .map((doc) {
                      final participants =
                          List<String>.from(doc['participants'] ?? []);
                      return participants.firstWhere(
                          (id) => id != widget.currentUserId,
                          orElse: () => '');
                    })
                    .where((id) => id.isNotEmpty)
                    .toSet()
                    .toList();

                return FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .where(FieldPath.documentId, whereIn: otherUserIds)
                      .get(),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final userDataMap = {
                      for (var doc in userSnapshot.data!.docs)
                        doc.id: doc.data() as Map<String, dynamic>
                    };

                    return ListView.builder(
                      itemCount: chatDocs.length,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final chatDoc = chatDocs[index];
                        final data = chatDoc.data() as Map<String, dynamic>;
                        final participants =
                            List<String>.from(data['participants'] ?? []);
                        final otherUserId = participants.firstWhere(
                            (id) => id != widget.currentUserId,
                            orElse: () => '');

                        if (!userDataMap.containsKey(otherUserId))
                          return const SizedBox();

                        final userData = userDataMap[otherUserId]!;
                        final lastMessage = data['lastMessage'] ?? {};
                        final messageText = lastMessage['text'] ?? '';
                        final senderId = lastMessage['senderId'] ?? '';
                        final isSentByCurrentUser =
                            senderId == widget.currentUserId;
                        final timestamp =
                            lastMessage['timestamp'] as Timestamp?;
                        final seenBy =
                            List<String>.from(lastMessage['seenBy'] ?? []);
                        final isSeen = seenBy.contains(widget.currentUserId);
                        final unreadCounts = data['unreadCounts'] ?? {};
                        final unreadCount =
                            unreadCounts[widget.currentUserId]?.toInt() ?? 0;
                        final profileUrl = sanitizeUrl(userData['profileUrl']);

                        bool isSelected = selectedChats.contains(chatDoc.id);

                        return ListTile(
                          selected: isSelected,
                          selectedTileColor: const Color(
                              0xFFE6F4EA), // light green when selected
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),

                          onTap: () async {
                            if (selectedChats.isNotEmpty) {
                              setState(() {
                                isSelected
                                    ? selectedChats.remove(chatDoc.id)
                                    : selectedChats.add(chatDoc.id);
                                selectedChatId = chatDoc.id;
                              });
                            } else {
                              await FirebaseFirestore.instance
                                  .collection('chats')
                                  .doc(chatDoc.id)
                                  .update({
                                'lastMessage.seenBy': FieldValue.arrayUnion(
                                    [widget.currentUserId]),
                                'unreadCounts.${widget.currentUserId}': 0,
                              });

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Messagescreen(
                                    chatId: chatDoc.id,
                                    receiverId: userData['uid'],
                                    receiverName: userData['name'] ?? 'Unknown',
                                    profileUrl: userData['photoUrl'] ?? '',
                                  ),
                                ),
                              );
                            }
                          },

                          onLongPress: () {
                            setState(() {
                              if (isSelected) {
                                selectedChats.remove(chatDoc.id);
                                selectedChatId = null;
                              } else {
                                selectedChats.add(chatDoc.id);
                                selectedChatId = chatDoc.id;
                              }
                            });
                          },

                          leading: Stack(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.grey[300],
                                backgroundImage: (profileUrl.isNotEmpty &&
                                        profileUrl.startsWith('http') &&
                                        Uri.tryParse(profileUrl)
                                                ?.hasAbsolutePath ==
                                            true)
                                    ? CachedNetworkImageProvider(profileUrl)
                                    : null,
                                child: profileUrl.isEmpty
                                    ? Text(
                                        (userData['name'] ?? 'U')[0]
                                            .toUpperCase(),
                                        style: const TextStyle(
                                            color: Colors.white),
                                      )
                                    : null,
                              ),
                              if (isSelected)
                                const Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.green,
                                    child: Icon(Icons.check,
                                        color: Colors.white, size: 16),
                                  ),
                                ),
                            ],
                          ),

                          title: Text(
                            userData['name'] ?? userData['phone'] ?? 'Unknown',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.black,
                            ),
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
                                      : Colors.grey,
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
                                      fontWeight: FontWeight.bold,
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF2C4152),

        heroTag: null, // disables hero animation
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ContactsOnStitchUp()),
          );
        },
        child:
            const Icon(Icons.contacts_outlined, color: Colors.white, size: 24),
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
    final usersRef = firestore.collection('users');
    final chatRef = firestore.collection('chats').doc(chatId);
    final messageRef = chatRef.collection('messages').doc(); // Auto ID
    final messageId = messageRef.id;
    final timestamp = FieldValue.serverTimestamp();

    try {
      // 1️⃣ Fetch sender and receiver data for participantDetails
      final senderSnap = await usersRef.doc(senderId).get();
      final receiverSnap = await usersRef.doc(receiverId).get();

      final senderData = senderSnap.data() ?? {};
      final receiverData = receiverSnap.data() ?? {};

      final senderName = senderData['name'] ?? 'Unknown';
      final senderProfileUrl = senderData['profileUrl'] ?? '';
      final receiverName = receiverData['name'] ?? 'Unknown';
      final receiverProfileUrl = receiverData['profileUrl'] ?? '';

      final messageData = {
        'id': messageId,
        'text': text,
        'senderId': senderId,
        'timestamp': timestamp,
        'seenBy': [senderId],
        'type': 'text',
      };

      final batch = firestore.batch();

      // 2️⃣ Add message to subcollection
      batch.set(messageRef, messageData);

      // 3️⃣ Update chat document (for chat list UI)
      batch.set(
        chatRef,
        {
          'participants': [senderId, receiverId],
          'createdAt': timestamp,
          'lastMessage': messageData,
          'unreadCounts': {
            senderId: 0,
            receiverId: FieldValue.increment(1),
          },
          'participantDetails': {
            senderId: {
              'name': senderName,
              'profileUrl': senderProfileUrl,
            },
            receiverId: {
              'name': receiverName,
              'profileUrl': receiverProfileUrl,
            },
          },
        },
        SetOptions(merge: true),
      );

      // 4️⃣ Commit all
      await batch.commit();
    } catch (e) {
      debugPrint('❌ sendMessage error: $e');
    }
  }
}
