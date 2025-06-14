// Full WhatsApp-like chat screen with Voice Notes, Emoji Reactions, and Recording Indicator

import 'dart:async';
import 'dart:io';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/message_model.dart';

class Messagescreen extends StatefulWidget {
  final String chatId;
  final String receiverId;
  final String receiverName;
  final String profileUrl;
  final String? voiceUrl; // nullable
  final Map<String, String>? reactions; // for emoji reactions

  const Messagescreen({
    super.key,
    required this.chatId,
    required this.receiverId,
    required this.receiverName,
    required this.profileUrl,
    this.voiceUrl,
    this.reactions,
  });

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

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  String? _voiceFilePath;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    currentUserId = _auth.currentUser!.uid;
    WidgetsBinding.instance.addObserver(this);
    _setOnline();
    _markMessagesAsDelivered();
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

  void _updateTypingStatus(String value) {
    final isTyping = value.isNotEmpty;
    if (isTyping != _isTyping) {
      _isTyping = isTyping;
      _firestore.collection('users').doc(currentUserId).update({
        'isTypingTo': isTyping ? widget.receiverId : '',
      });
    }
  }

  void _setRecordingStatus(bool isRecording) {
    _firestore.collection('users').doc(currentUserId).update({
      'isRecordingTo': isRecording ? widget.receiverId : '',
    });
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
    _updateTypingStatus('');

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

  void _toggleReaction(String messageId, String emoji) {
    final userRef = _auth.currentUser!.uid;
    final messageRef = _firestore
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc(messageId);

    messageRef.get().then((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final reactions = Map<String, String>.from(data['reactions'] ?? {});
      if (reactions[userRef] == emoji) {
        reactions.remove(userRef);
      } else {
        reactions[userRef] = emoji;
      }
      messageRef.update({'reactions': reactions});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(244, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[300],
              backgroundImage: NetworkImage(widget.profileUrl),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.receiverId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Text(
                      'Loading...',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    );
                  }

                  final userData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  final isOnline = userData['isOnline'] ?? false;
                  final lastSeen =
                      (userData['lastSeen'] as Timestamp?)?.toDate();
                  final isTypingTo = userData['isTypingTo'] ?? '';
                  final isRecordingTo = userData['isRecordingTo'] ?? '';
                  final profilePic = userData['profilePic'] ?? '';
                  final userName = userData['name'] ?? 'Unknown';

                  String statusText = 'offline';
                  if (isOnline) {
                    if (isRecordingTo ==
                        FirebaseAuth.instance.currentUser!.uid) {
                      statusText = 'recording voice...';
                    } else if (isTypingTo ==
                        FirebaseAuth.instance.currentUser!.uid) {
                      statusText = 'typing...';
                    } else {
                      statusText = 'online';
                    }
                  } else if (lastSeen != null) {
                    statusText = 'last seen ${_formatLastSeen(lastSeen)}';
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        statusText,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
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
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Show popup menu
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<QueryDocumentSnapshot>>(
              stream: _messageStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No messages yet."));
                }

                final messages = snapshot.data!;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController
                        .jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  itemBuilder: (context, index) {
                    final msg = MessageModel.fromMap(
                        messages[index].data() as Map<String, dynamic>);
                    final isMe = msg.senderId == currentUserId;
                    final reactions =
                        Map<String, String>.from(msg.reactions ?? {});

                    if (!isMe && !msg.isRead) {
                      messages[index].reference.update({'isRead': true});
                    }

                    return GestureDetector(
                      onLongPress: () => _toggleReaction(
                          messages[index].id, '❤️'), // or emoji picker
                      child: Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                color:
                                    isMe ? Colors.green[300] : Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: msg.voiceUrl != null && msg.voiceUrl != ''
                                  ? Icon(Icons.play_arrow)
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            msg.message,
                                            style: TextStyle(
                                              color: isMe
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateFormat('hh:mm a')
                                              .format(msg.timestamp),
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: Color.fromARGB(
                                                  255, 232, 232, 232)),
                                        ),
                                        const SizedBox(width: 4),
                                        if (isMe)
                                          Icon(
                                            msg.isRead
                                                ? Icons.done_all
                                                : msg.isDelivered
                                                    ? Icons.done_all
                                                    : Icons.check,
                                            size: 18,
                                            color: msg.isRead
                                                ? Colors.blue
                                                : Colors.white70,
                                          ),
                                      ],
                                    ),
                            ),
                            if (reactions.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onChanged: _updateTypingStatus,
                    decoration: const InputDecoration(
                      hintText: "Type a message",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (!_isRecording)
                  IconButton(
                    icon: const Icon(Icons.mic),
                    onPressed: _startRecording,
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.stop),
                    onPressed: _stopRecordingAndSend,
                  ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(_messageController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
