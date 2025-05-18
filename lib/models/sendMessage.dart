import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> sendMessage({
  required String chatId,
  required String senderId,
  required String receiverId,
  required String messageText,
}) async {
  final timestamp = Timestamp.now();

  final messageData = {
    'text': messageText,
    'timestamp': timestamp,
    'senderId': senderId,
    'seenBy': [senderId], // message is seen by sender by default
  };

  // Add message to 'messages' subcollection
  await FirebaseFirestore.instance
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .add(messageData);

  // Update parent chat document
  await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
    'lastMessage': messageData,
    'unreadCount.$receiverId': FieldValue.increment(1),
    'unreadCount.$senderId': 0,
  });
}
