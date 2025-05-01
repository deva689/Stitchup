import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:stitchup/ChatScreen/ContactPage.dart';
import 'package:stitchup/models/ChatModel.dart';
import 'package:stitchup/ChatScreen/ChatDetailScreen.dart';
import 'package:stitchup/widgets/StoriesWidget.dart';

class ChatScreen extends StatefulWidget {
  final String currentUserId;

  const ChatScreen({super.key, required this.currentUserId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  Widget build(BuildContext context) {
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
            onPressed: () {
              // TODO: Implement search
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: StoriesWidget(currentUserId: widget.currentUserId),
          ), // ✅ Correct usage          ),
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .where('participants', arrayContains: widget.currentUserId)
                    .orderBy('lastMessage.timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final chatDocs = snapshot.data!.docs;

                  if (chatDocs.isEmpty) {
                    return const Center(child: Text("No chats yet."));
                  }

                  return ListView.builder(
                    itemCount: chatDocs.length,
                    itemBuilder: (context, index) {
                      final doc = chatDocs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final chatModel = ChatModel.fromMap(data, doc.id);

                      final otherUserId = chatModel.participants.firstWhere(
                        (id) => id != widget.currentUserId,
                        orElse: () => '',
                      );

                      if (otherUserId.isEmpty ||
                          chatModel.lastMessage == null) {
                        return const SizedBox.shrink();
                      }

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(otherUserId)
                            .get(),
                        builder: (context, userSnapshot) {
                          if (!userSnapshot.hasData ||
                              !userSnapshot.data!.exists) {
                            return const SizedBox.shrink();
                          }

                          final userData =
                              userSnapshot.data!.data() as Map<String, dynamic>;

                          return ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 8),
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundImage: userData['photoUrl'] != null &&
                                      userData['photoUrl'].toString().isNotEmpty
                                  ? NetworkImage(userData['photoUrl'])
                                  : null,
                              child: userData['photoUrl'] == null ||
                                      userData['photoUrl'].toString().isEmpty
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(
                              userData['username'] ?? 'Unknown',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              chatModel.lastMessage?.text ?? '',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            trailing: Text(
                              chatModel.lastMessage?.timestamp != null
                                  ? _formatTime(
                                      chatModel.lastMessage!.timestamp)
                                  : '',
                              style: const TextStyle(fontSize: 12),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatDetailScreen(
                                    currentUserId: widget.currentUserId,
                                    receiverUserId: otherUserId,
                                    receiverName:
                                        userData['username'] ?? 'Unknown',
                                    receiverPhotoUrl: userData['photoUrl'],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
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

  String _formatTime(Timestamp timestamp) {
    final dt = timestamp.toDate();
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }
}
