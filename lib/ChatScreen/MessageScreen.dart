// Full WhatsApp-like chat screen with Voice Notes, Emoji Reactions, and Recording Indicator

import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart'
    show Config, EmojiPicker;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stitchup/Chat_camera/CameraScreen.dart';
import 'package:stitchup/Chat_camera/Chat_Camera.dart';
import 'package:stitchup/models/message_model.dart';
import 'package:stitchup/services/chat_service.dart';

class Messagescreen extends StatefulWidget {
  final String chatId;
  final String receiverId;
  final String receiverName;
  final String profileUrl;
  final String? voiceUrl;
  final Map<String, String>? reactions;

  const Messagescreen({
    Key? key,
    required this.chatId,
    required this.receiverId,
    required this.receiverName,
    required this.profileUrl,
    this.voiceUrl,
    this.reactions,
  }) : super(key: key);

  @override
  State<Messagescreen> createState() => _MessagescreenState();
}

class _MessagescreenState extends State<Messagescreen>
    with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String currentUserId;
  Timer? _offlineTimer;
  bool _isTyping = false;
  late DateTime timestamp;
  Timer? _typingDebounce;
  Map<String, dynamic>? receiverUserData;
  final ValueNotifier<bool> _isTypingNotifier = ValueNotifier(false);
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  String? _voiceFilePath;
  bool _isRecording = false;
  late List<CameraDescription> _cameras;
  bool showEmojiPicker = false;
  final FocusNode _focusNode = FocusNode();
  late String chatId;
  late String receiverId;

  @override
  void initState() {
    super.initState();
    chatId = widget.chatId;
    receiverId = widget.receiverId;

    currentUserId = _auth.currentUser!.uid;
    WidgetsBinding.instance.addObserver(this);
    _setOnline();
    _markMessagesAsDelivered();
    _initTypingListener(); // Use this instead of direct listener
    _fetchReceiverUserData(); // ✅ Add this
    _messageController.addListener(() {
      final isTypingNow = _messageController.text.trim().isNotEmpty;
      if (isTypingNow != _isTyping) {
        setState(() {
          _isTyping = isTypingNow;
        });
      }
    });
    availableCameras().then((cameras) {
      setState(() {
        _cameras = cameras;
      });
    });
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() => showEmojiPicker = false);
      }
    });
  }

  @override
  void dispose() {
    _setOffline();
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    _offlineTimer?.cancel();
    _updateTypingStatus('');
    _setRecordingStatus(false);
    _typingDebounce?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setOnline();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _startOfflineTimer();
    }
  }

  void _setOnline() {
    _offlineTimer?.cancel();
    _firestore.collection('users').doc(currentUserId).update({
      'isOnline': true,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  void _startOfflineTimer() {
    _offlineTimer?.cancel();
    _offlineTimer = Timer(const Duration(minutes: 3), _setOffline);
  }

  void _setOffline() {
    _firestore.collection('users').doc(currentUserId).update({
      'isOnline': false,
      'lastSeen': DateTime.now(),
    });
  }

  void _fetchReceiverUserData() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.receiverId)
        .get();

    if (doc.exists) {
      setState(() {
        receiverUserData = doc.data();
      });
    }
  }

  void _initTypingListener() {
    _messageController.addListener(() {
      final isUserTyping = _messageController.text.trim().isNotEmpty;

      if (_isTyping != isUserTyping) {
        _isTyping = isUserTyping;

        _debounceTypingStatusUpdate(isUserTyping);
      }
    });
  }

  void _debounceTypingStatusUpdate(bool isTyping) {
    _typingDebounce?.cancel();

    // Only update Firestore if the user has been idle for 1.2 seconds
    _typingDebounce = Timer(const Duration(milliseconds: 1200), () {
      _firestore.collection('users').doc(currentUserId).update({
        'isTypingTo': isTyping ? widget.receiverId : '',
      });
    });
  }

  void _updateTypingStatus(String value) {
    final isTyping = value.trim().isNotEmpty;
    _typingDebounce?.cancel(); // Cancel any pending debounce

    _firestore.collection('users').doc(currentUserId).update({
      'isTypingTo': isTyping ? widget.receiverId : '',
    });

    _isTyping = isTyping;
  }

  void _setRecordingStatus(bool isRecording) {
    _firestore.collection('users').doc(currentUserId).update({
      'isRecordingTo': isRecording ? widget.receiverId : '',
    });
  }

  void _handleTyping() {
    final isUserTyping = _messageController.text.trim().isNotEmpty;
    if (_isTyping != isUserTyping) {
      setState(() {
        _isTyping = isUserTyping;
      });

      // Optional: Firestore update
      _firestore.collection('users').doc(currentUserId).update({
        'isTypingTo': isUserTyping ? widget.receiverId : '',
      });
    }
  }

  void _markMessagesAsDelivered() async {
    final snapshot = await _firestore
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('isDelivered', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.update({'isDelivered': true});
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final trimmedText = text.trim();
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final chatRef = _firestore.collection('chats').doc(widget.chatId);
    final messageRef = chatRef.collection('messages').doc();
    final messageId = messageRef.id;

    final messageData = {
      'id': messageId,
      'text': trimmedText,
      'senderId': currentUserId,
      'receiverId': widget.receiverId,
      'timestamp': FieldValue.serverTimestamp(),
      'seenBy': [currentUserId],
      'isDelivered': false,
      'isRead': false,
      'type': 'text',
    };

    // 🔹 Save message
    await messageRef.set(messageData);

    // 🔹 Fetch actual saved message with timestamp from Firestore
    final savedMessage = await messageRef.get();
    final savedTimestamp = savedMessage['timestamp'] as Timestamp?;

    // 🔹 Get chat participants
    final chatSnapshot = await chatRef.get();
    List<String> participants = [currentUserId, widget.receiverId];
    Timestamp? createdAt;

    if (chatSnapshot.exists) {
      final chatData = chatSnapshot.data()!;
      participants =
          List<String>.from(chatData['participants'] ?? participants);
      createdAt = chatData['createdAt'];
    }

    // 🔹 Update unread count
    final Map<String, int> unreadCounts = {};
    for (final uid in participants) {
      unreadCounts[uid] = uid == currentUserId ? 0 : 1;
    }

    // 🔹 Update chat document with actual timestamp
    await chatRef.set({
      'participants': participants,
      'users': participants,
      'createdAt': createdAt ?? Timestamp.now(),
      'lastMessage': {
        'id': messageId,
        'text': trimmedText,
        'senderId': currentUserId,
        'receiverId': widget.receiverId,
        'timestamp': savedTimestamp ?? Timestamp.now(),
        'seenBy': [currentUserId],
        'isDelivered': false,
        'isRead': false,
        'type': 'text',
      },
      'unreadCounts': unreadCounts,
    }, SetOptions(merge: true));

    // 🔹 UI cleanup
    _messageController.clear();
    if (_isTyping) {
      setState(() => _isTyping = false);
    }
    _isTypingNotifier.value = false;
    _handleTyping(); // Reset typing status
    _setRecordingStatus(false); // Reset recording status
    // 🔹 Scroll to bottom after UI frame
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startRecording() async {
    await Permission.microphone.request();
    final dir = await getTemporaryDirectory();
    _voiceFilePath = '${dir.path}/voice_note.aac';
    await _recorder.openRecorder();
    await _recorder.startRecorder(toFile: _voiceFilePath, codec: Codec.aacADTS);
    setState(() => _isRecording = true);
    _setRecordingStatus(true);
  }

  Future<void> _stopRecordingAndSend() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    await _recorder.stopRecorder();
    setState(() => _isRecording = false);
    _setRecordingStatus(false);
    final file = File(_voiceFilePath!);

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('voice_notes/${DateTime.now().millisecondsSinceEpoch}.aac');
    await storageRef.putFile(file);
    final voiceUrl = await storageRef.getDownloadURL();

    final messageRef = _firestore
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc();

    final timestamp = FieldValue.serverTimestamp();

    await messageRef.set({
      'id': messageRef.id,
      'senderId': currentUserId,
      'receiverId': widget.receiverId,
      'message': '',
      'voiceUrl': voiceUrl,
      'timestamp': timestamp,
      'seenBy': [currentUserId],
      'type': 'voice',
    });

    final chatDoc = _firestore.collection('chats').doc(widget.chatId);
    final chatSnapshot = await chatDoc.get();
    final chatData = chatSnapshot.data();

    if (chatData != null) {
      final participants = List<String>.from(chatData['participants'] ?? []);
      final Map<String, int> newUnreadCounts = {};

      for (final uid in participants) {
        newUnreadCounts[uid] = uid == currentUserId ? 0 : 1;
      }

      await chatDoc.set({
        'participants': participants,
        'users': participants,
        'lastMessage': {
          'id': messageRef.id,
          'text': '',
          'voiceUrl': voiceUrl,
          'timestamp': timestamp,
          'senderId': currentUserId,
          'seenBy': [currentUserId],
          'type': 'voice',
        },
        'unreadCounts': newUnreadCounts,
        'createdAt': chatData['createdAt'] ?? timestamp,
      }, SetOptions(merge: true));
    }
  }

  String getWhatsAppStatusText({
    required bool isOnline,
    required DateTime? lastSeen,
    required String isTypingTo,
    String? isRecordingTo,
  }) {
    if (isRecordingTo == currentUserId) return 'recording voice...';
    if (isTypingTo == currentUserId) return 'typing...';
    if (isOnline) return 'online';
    if (lastSeen == null) return 'offline';

    final now = DateTime.now();
    final diff = now.difference(lastSeen);
    final time = DateFormat.jm().format(lastSeen);

    if (diff.inDays == 0) {
      return 'last seen today at $time';
    } else if (diff.inDays == 1) {
      return 'last seen yesterday at $time';
    } else {
      final date = DateFormat('dd/MM/yyyy').format(lastSeen);
      return 'last seen on $date at $time';
    }
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 2) {
      return 'just now';
    } else if (difference.inMinutes < 120) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    } else {
      return '${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
    }
  }

  Stream<List<QueryDocumentSnapshot>> _messageStream() {
    return _firestore
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  void _toggleReaction(String messageId, String emoji) async {
    final userRef = _auth.currentUser!.uid;
    final messageRef = _firestore
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc(messageId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(messageRef);
      final data = snapshot.data() as Map<String, dynamic>;
      final reactions = Map<String, String>.from(data['reactions'] ?? {});

      if (reactions[userRef] == emoji) {
        reactions.remove(userRef);
      } else {
        reactions[userRef] = emoji;
      }

      transaction.update(messageRef, {'reactions': reactions});
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: true,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(244, 255, 255, 255),
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          titleSpacing: 0,
          toolbarHeight: 60,
          title: Row(
            children: [
              // Profile Picture
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey[300],
                backgroundImage: receiverUserData != null &&
                        receiverUserData!['profileUrl'] != null &&
                        receiverUserData!['profileUrl'].toString().isNotEmpty
                    ? NetworkImage(receiverUserData!['profileUrl'])
                    : null,
                child: (receiverUserData == null ||
                        receiverUserData!['profileUrl'] == null ||
                        receiverUserData!['profileUrl'].toString().isEmpty)
                    ? Text(
                        (receiverUserData?['name'] ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),

              const SizedBox(width: 12),

              // Name & Status
              Expanded(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.receiverId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Loading...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Connecting...',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      );
                    }

                    final userData =
                        snapshot.data!.data() as Map<String, dynamic>;
                    final isOnline = userData['isOnline'] ?? false;
                    final lastSeen =
                        (userData['lastSeen'] as Timestamp?)?.toDate();
                    final isTypingTo = userData['isTypingTo'] ?? '';
                    final isRecordingTo = userData['isRecordingTo'] ?? '';
                    final userName = userData['name'] ?? 'Unknown';
                    final currentUserId =
                        FirebaseAuth.instance.currentUser!.uid;

                    String statusText = 'offline';
                    if (isOnline) {
                      if (isRecordingTo == currentUserId) {
                        statusText = 'recording voice...';
                      } else if (isTypingTo == currentUserId) {
                        statusText = 'typing...';
                      } else {
                        statusText = 'online';
                      }
                    } else if (lastSeen != null) {
                      statusText = 'last seen ${_formatLastSeen(lastSeen)}';
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          statusText,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.black),
              onPressed: () {
                // TODO: Show popup menu
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(widget.chatId)
                    .collection('messages')
                    .orderBy('timestamp', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No messages yet."));
                  }

                  final messages = snapshot.data!.docs;

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length,
                    padding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    itemBuilder: (context, index) {
                      final map =
                          messages[index].data() as Map<String, dynamic>;

                      late final MessageModel msg;
                      try {
                        msg = MessageModel.fromMap(map);
                      } catch (e) {
                        print("❌ Error parsing message: $e");
                        return const Text("Invalid message data");
                      }

                      final isMe = msg.senderId == currentUserId;
                      final reactions =
                          Map<String, String>.from(msg.reactions ?? {});

                      // Update delivery and read status for received messages
                      if (!isMe) {
                        if (!msg.isDelivered) {
                          messages[index]
                              .reference
                              .update({'isDelivered': true});
                          if (index == messages.length - 1) {
                            FirebaseFirestore.instance
                                .collection('chats')
                                .doc(widget.chatId)
                                .update({'lastMessage.isDelivered': true});
                          }
                        }
                        if (!msg.isRead) {
                          messages[index].reference.update({'isRead': true});
                        }
                      }

                      return GestureDetector(
                        onLongPress: () =>
                            _toggleReaction(messages[index].id, '❤️'),
                        child: Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 1, horizontal: 8),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.75,
                                ),
                                decoration: BoxDecoration(
                                  color: msg.type == 'image'
                                      ? Colors.transparent
                                      : const Color(0xFFCCD9E3),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(12),
                                    topRight: const Radius.circular(12),
                                    bottomLeft: Radius.circular(isMe ? 12 : 0),
                                    bottomRight: Radius.circular(isMe ? 0 : 12),
                                  ),
                                ),

                                // TEXT MESSAGE LAYOUT
                                child: msg.type == 'text'
                                    ? Builder(
                                        builder: (context) {
                                          final isShort =
                                              msg.message.length <= 15;

                                          if (isShort) {
                                            // ✅ Short message – INLINE time & tick
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      msg.message,
                                                      softWrap: true,
                                                      style: const TextStyle(
                                                        color: Colors.black87,
                                                        fontSize: 16,
                                                        height: 1.4,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    DateFormat('h:mm a')
                                                        .format(msg.timestamp),
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Color(0xFF7A7A7A),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Icon(
                                                    msg.isRead
                                                        ? Icons.done_all
                                                        : msg.isDelivered
                                                            ? Icons.done_all
                                                            : Icons.check,
                                                    size: 16,
                                                    color: msg.isRead
                                                        ? Colors.blue
                                                        : Colors.grey.shade600,
                                                  ),
                                                ],
                                              ),
                                            );
                                          } else {
                                            // ✅ Long message – TIME BELOW in bottom-right
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    msg.message,
                                                    softWrap: true,
                                                    overflow:
                                                        TextOverflow.visible,
                                                    textAlign: TextAlign.start,
                                                    style: const TextStyle(
                                                      color: Colors.black87,
                                                      fontSize: 16,
                                                      height: 1.4,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Align(
                                                    alignment:
                                                        Alignment.bottomRight,
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          DateFormat('h:mm a')
                                                              .format(msg
                                                                  .timestamp),
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 11,
                                                            color: Color(
                                                                0xFF7A7A7A),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        Icon(
                                                          msg.isRead
                                                              ? Icons.done_all
                                                              : msg.isDelivered
                                                                  ? Icons
                                                                      .done_all
                                                                  : Icons.check,
                                                          size: 16,
                                                          color: msg.isRead
                                                              ? Colors.blue
                                                              : Colors.grey
                                                                  .shade600,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }
                                        },
                                      )

                                    // IMAGE MESSAGE LAYOUT
                                    : Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: CachedNetworkImage(
                                              imageUrl: msg.imageUrl!,
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.6,
                                              height: 300,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  const Center(
                                                child: Padding(
                                                  padding: EdgeInsets.all(20),
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                              ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      const Icon(Icons.error),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 6,
                                            right: 8,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.black45,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    DateFormat('h:mm a')
                                                        .format(msg.timestamp),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Icon(
                                                    msg.isRead
                                                        ? Icons.done_all
                                                        : msg.isDelivered
                                                            ? Icons.done_all
                                                            : Icons.check,
                                                    size: 14,
                                                    color: msg.isRead
                                                        ? Colors.blue
                                                        : Colors.white
                                                            .withOpacity(0.7),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                              ),

                              // REACTIONS (below message bubble)
                              if (reactions.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 12,
                                    right: 12,
                                    top: 2,
                                    bottom: 4,
                                  ),
                                  child: Text(
                                    reactions.values.join(' '),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Message input container
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Emoji Icon
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: 10, left: 10),
                            child: GestureDetector(
                              onTap: () {
                                FocusScope.of(context)
                                    .unfocus(); // Hide keyboard
                                setState(() {
                                  showEmojiPicker = !showEmojiPicker;
                                });
                              },
                              child: SvgPicture.asset(
                                'assets/icons/Emoji.svg',
                                width: 24,
                                height: 24,
                                color: const Color(0xFF5C5D5F),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // TextField
                          Expanded(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                minHeight: 24,
                                maxHeight: 120, // up to 5 lines
                              ),
                              child: TextField(
                                controller: _messageController,
                                minLines: 1,
                                maxLines: 5,
                                keyboardType: TextInputType.multiline,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF1C1C1C),
                                ),
                                decoration: const InputDecoration(
                                  isCollapsed: true,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 10),
                                  hintText: "Message",
                                  hintStyle:
                                      TextStyle(color: Color(0xFF5C5D5F)),
                                  border: InputBorder.none,
                                ),
                                onChanged: (value) {
                                  _isTypingNotifier.value =
                                      value.trim().isNotEmpty;
                                },
                              ),
                            ),
                          ),

                          const SizedBox(width: 6),

                          // Attachment Icon
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GestureDetector(
                              onTap: () {
                                // Attachment tap action
                              },
                              child: SvgPicture.asset(
                                'assets/icons/attach_file.svg',
                                width: 24,
                                height: 24,
                                color: Color(0xFF5C5D5F),
                              ),
                            ),
                          ),

                          if (showEmojiPicker)
                            SizedBox(
                              height: 250,
                              child: EmojiPicker(
                                onEmojiSelected: (category, emoji) {
                                  _messageController.text += emoji.emoji;
                                  _messageController.selection =
                                      TextSelection.fromPosition(
                                    TextPosition(
                                        offset: _messageController.text.length),
                                  );
                                },
                                config: Config(),
                              ),
                            ),

                          const SizedBox(width: 16),

                          // Camera + Send/Mic
                          ValueListenableBuilder<bool>(
                            valueListenable: _isTypingNotifier,
                            builder: (context, isTyping, _) {
                              return Row(
                                children: [
                                  if (!isTyping)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          bottom: 10, right: 16),
                                      child: GestureDetector(
                                        onTap: () async {
                                          if (_cameras.isNotEmpty) {
                                            final imagePath =
                                                await Navigator.push<String>(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => CameraScreen(
                                                  cameras: _cameras,
                                                  chatId: widget.chatId,
                                                  receiverId: widget.receiverId,
                                                  receiverName:
                                                      widget.receiverName,
                                                  profileUrl: widget.profileUrl,
                                                ),
                                              ),
                                            );

                                            if (imagePath != null &&
                                                imagePath.isNotEmpty) {
                                              final senderId = FirebaseAuth
                                                  .instance.currentUser!.uid;

                                              await ChatService
                                                  .sendImageMessage(
                                                chatId: widget.chatId,
                                                senderId: senderId,
                                                receiverId: widget.receiverId,
                                                imageFile: File(imagePath),
                                              );

                                              print(
                                                  '✅ Image sent to chat from: $imagePath');
                                            } else {
                                              print(
                                                  '⚠️ No image returned from camera');
                                            }
                                          } else {
                                            print('❌ No cameras found');
                                          }
                                        },
                                        child: SvgPicture.asset(
                                          'assets/icons/photo_camera.svg',
                                          width: 24,
                                          height: 24,
                                          color: const Color(0xFF5C5D5F),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Send or Mic button
                  ValueListenableBuilder<bool>(
                    valueListenable: _isTypingNotifier,
                    builder: (context, isTyping, _) {
                      return Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2C4152),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            isTyping
                                ? Icons.send
                                : (_isRecording ? Icons.stop : Icons.mic),
                            color: Colors.white,
                          ),
                          onPressed: isTyping
                              ? () => _sendMessage(_messageController.text)
                              : (_isRecording
                                  ? _stopRecordingAndSend
                                  : _startRecording),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
