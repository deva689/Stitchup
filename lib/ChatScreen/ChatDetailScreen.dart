import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatDetailScreen extends StatefulWidget {
  final String currentUserId;
  final String receiverUserId;
  final String receiverName;
  final String? receiverPhotoUrl;

  const ChatDetailScreen({
    super.key,
    required this.currentUserId,
    required this.receiverUserId,
    required this.receiverName,
    this.receiverPhotoUrl,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String get chatId {
    final ids = [widget.currentUserId, widget.receiverUserId];
    ids.sort();
    return ids.join("_");
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final timestamp = Timestamp.now();

    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
    final messageRef = chatRef.collection('messages').doc();

    await chatRef.set({
      'participants': [widget.currentUserId, widget.receiverUserId],
      'lastMessage': {
        'text': text,
        'timestamp': timestamp,
        'senderId': widget.currentUserId,
      }
    }, SetOptions(merge: true));

    await messageRef.set({
      'text': text,
      'timestamp': timestamp,
      'senderId': widget.currentUserId,
      'receiverId': widget.receiverUserId,
    });

    _messageController.clear();

    // Scroll to the latest message
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              CircleAvatar(
                backgroundImage: widget.receiverPhotoUrl != null
                    ? NetworkImage(widget.receiverPhotoUrl!)
                    : null,
                child: widget.receiverPhotoUrl == null
                    ? const Icon(Icons.person)
                    : null,
              ),
              const SizedBox(width: 8),
              Text(widget.receiverName),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(chatId)
                    .collection('messages')
                    .orderBy('timestamp')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data!.docs;

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg =
                          messages[index].data() as Map<String, dynamic>;
                      final isMe = msg['senderId'] == widget.currentUserId;
                      return Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blue[100] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(msg['text'] ?? ''),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration:
                          const InputDecoration(hintText: 'Type a message'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
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
