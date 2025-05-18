import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/message_model.dart';

// Initialize a FirebaseFunctions instance
final FirebaseFunctions functions = FirebaseFunctions.instance;

class Messagescreen extends StatefulWidget {
  final String chatId;
  final String receiverId;
  final String receiverName;
  final String profileUrl;
  final String? voiceUrl; // nullable
  final Map<String, String>? reactions; // for emoji reactions
  final String senderName; // Add this!

  const Messagescreen({
    super.key,
    required this.chatId,
    required this.receiverId,
    required this.receiverName,
    required this.profileUrl,
    this.voiceUrl,
    this.reactions,
    required this.senderName, // Add this!
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

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  String? _voiceFilePath;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();

    // Get current user ID
    currentUserId = _auth.currentUser!.uid;

    // Add lifecycle observer if needed
    WidgetsBinding.instance.addObserver(this);

    // Set user online status
    _setOnline();

    // Mark messages as delivered
    _markMessagesAsDelivered();

    // Save the device token for push notifications
    _saveDeviceToken();

    // Listen for FCM token refresh and update Firestore
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _firestore.collection('users').doc(currentUserId).update({
        'fcmToken': newToken,
      });
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
    final timestamp = FieldValue.serverTimestamp();

    try {
      // 1. Save message to Firestore
      final messageRef = _firestore
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .doc();

      await messageRef.set({
        'text': trimmedText,
        'senderId': currentUserId,
        'receiverId': widget.receiverId,
        'message': trimmedText,
        'timestamp': timestamp,
        'seenBy': [currentUserId],
        'isRead': false,
        'isDelivered': true,
        'reactions': {}, // Initialize empty reactions map
      });

      // 2. Update lastMessage and unreadCounts in chat doc
      final chatDoc = _firestore.collection('chats').doc(widget.chatId);
      final chatSnapshot = await chatDoc.get();

      if (chatSnapshot.exists) {
        final chatData = chatSnapshot.data()!;
        final participants = List<String>.from(chatData['participants'] ?? []);
        final Map<String, int> newUnreadCounts = {};

        for (final uid in participants) {
          newUnreadCounts[uid] = uid == currentUserId
              ? 0
              : (chatData['unreadCounts']?[uid] ?? 0) + 1;
        }

        await chatDoc.update({
          'lastMessage': {
            'text': trimmedText,
            'timestamp': timestamp,
            'senderId': currentUserId,
            'seenBy': [currentUserId],
          },
          'unreadCounts': newUnreadCounts,
        });
      }

      // 3. Send Push Notification to receiver if token exists
      final receiverDoc =
          await _firestore.collection('users').doc(widget.receiverId).get();
      final fcmToken = receiverDoc.data()?['fcmToken'];

      if (fcmToken != null && fcmToken.isNotEmpty) {
        await sendPushNotification(
          token: fcmToken,
          title: widget.senderName ?? "New Message",
          body: trimmedText,
        );
      }

      // 4. Clear input and reset typing status
      _messageController.clear();
      _updateTypingStatus('');

      // 5. Scroll chat list to bottom smoothly
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      debugPrint("Error sending message: $e");
      // Optionally, show a SnackBar or Toast for the error
    }
  }

  Future<void> _saveDeviceToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null && currentUserId != null) {
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _firestore.collection('users').doc(currentUserId).update({
          'fcmToken': newToken,
        });
      });
      await _firestore.collection('users').doc(currentUserId).update({
        'fcmToken': token,
      });
    } else {
      debugPrint("❌ Failed to get FCM token");
    }
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
    await _recorder.stopRecorder();
    setState(() => _isRecording = false);
    _setRecordingStatus(false);
    final file = File(_voiceFilePath!);

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('voice_notes/${DateTime.now().millisecondsSinceEpoch}.aac');
    await storageRef.putFile(file);
    final voiceUrl = await storageRef.getDownloadURL();

    await _firestore
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
      'senderId': currentUserId,
      'receiverId': widget.receiverId,
      'message': '',
      'voiceUrl': voiceUrl,
      'timestamp': DateTime.now(),
      'isDelivered': false,
      'isRead': false,
    });
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

  Future<void> sendPushNotification({
    required String token,
    required String title,
    required String body,
  }) async {
    try {
      final callable = functions.httpsCallable('sendPushNotification');
      final result = await callable.call(<String, dynamic>{
        'token': token,
        'title': title,
        'body': body,
        'chatId': widget.chatId,
      });

      if (!(result.data['success'] as bool)) {
        debugPrint('FCM Function error: ${result.data['error']}');
      }
    } catch (e) {
      debugPrint('Error calling cloud function: $e');
    }
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
                  final profilePic = userData['profilePic'] ??
                      'https://via.placeholder.com/150';
                  final userName = userData['name'] ?? 'Unknown';

                  String statusText = 'Offline';

                  if (isOnline) {
                    if (isRecordingTo ==
                        FirebaseAuth.instance.currentUser!.uid) {
                      statusText = 'recording voice...';
                    } else if (isTypingTo ==
                        FirebaseAuth.instance.currentUser!.uid) {
                      statusText = 'typing...';
                    } else {
                      statusText = 'Online';
                    }
                  } else if (lastSeen != null) {
                    statusText = 'last seen ${_formatLastSeen(lastSeen)}';
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.receiverName,
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 17,
                              fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis),
                      Text(
                        getWhatsAppStatusText(
                          isOnline: isOnline,
                          lastSeen: lastSeen,
                          isTypingTo: isTypingTo,
                          isRecordingTo: isRecordingTo,
                        ),
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
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
                                        const SizedBox(width: 6),
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
