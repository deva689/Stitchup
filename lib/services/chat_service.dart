import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

class ChatService {
  /// ✅ Sends an image message to Firestore and uploads image to Firebase Storage
  static Future<void> sendImageMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required File imageFile,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final storage = FirebaseStorage.instance;

      final messageId = firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc()
          .id;

      final timestamp = Timestamp.now();
      final timeStr = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = path.extension(imageFile.path); // .jpg or .png
      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';

      // ✅ Build unique filename
      final fileName = '${timeStr}_$senderId$fileExtension';

      // ✅ Upload image to Firebase Storage
      final imageRef =
          storage.ref().child('chat_images').child(chatId).child(fileName);

      await imageRef.putFile(
        imageFile,
        SettableMetadata(contentType: mimeType),
      );

      final imageUrl = await imageRef.getDownloadURL();

      // ✅ Build image message data
      final messageData = {
        'id': messageId,
        'senderId': senderId,
        'receiverId': receiverId,
        'timestamp': timestamp,
        'type': 'image',
        'imageUrl': imageUrl,
        'message': '',
        'isDelivered': false,
        'isRead': false,
        'seenBy': [senderId],
        'reactions': {},
      };

      // ✅ Save message to Firestore
      await firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set(messageData);

      // ✅ Update lastMessage metadata in chat document
      await firestore.collection('chats').doc(chatId).set({
        'lastMessage': {
          'text': '[Image]',
          'imageUrl': imageUrl,
          'timestamp': timestamp,
          'type': 'image',
          'senderId': senderId,
          'isDelivered': false,
          'isRead': false,
        },
        'participants': [senderId, receiverId],
        'updatedAt': timestamp,
      }, SetOptions(merge: true));
    } catch (e) {
      print('❌ Error sending image message: $e');
      rethrow;
    }
  }
}
