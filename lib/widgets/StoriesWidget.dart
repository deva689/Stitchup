import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitchup/models/buildStatusData.dart';
import 'package:stitchup/widgets/MyStatusScreen.dart';

class StoriesWidget extends StatefulWidget {
  final String currentUserId;
  final List<Map<String, dynamic>> contactsWithStories;
  final File? localPreviewFile;
  final String? profileImageUrl;
  final bool isUploading;
  final double uploadProgress;
  final List<String> contactUIDs; // <-- Add this line
  final List<Map<String, dynamic>> stories;
  final Function(String userId) onStoryTap;
  final Map<String, String> localContactNames;

  const StoriesWidget({
    super.key,
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
  State<StoriesWidget> createState() => _StoriesWidgetState();
}

class _StoriesWidgetState extends State<StoriesWidget> {
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
  late String currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = widget.currentUserId;
    loadProfileImage();
    listenToStoryChanges(); // 🔥 Start real-time listener
  }

  /// Safe sanitizer to ensure only valid URLs are used
  String sanitizeUrl(String? url) {
    return (url != null && url.startsWith('http')) ? url : '';
  }

  /// Loads and caches the current user's profile image.
  Future<void> loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUrl = prefs.getString('cached_profile_url');
    if (cachedUrl != null && cachedUrl.isNotEmpty) {
      setState(() => profileImageUrl = cachedUrl);
    }

    // Then proceed to fetch fresh version
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final url = sanitizeUrl(userDoc.data()?['profileUrl']);
    if (mounted && url.isNotEmpty) {
      setState(() => profileImageUrl = url);
      await prefs.setString('cached_profile_url', url);
    }
  }

  /// Normalizes a phone number to last 10 digits (standard for Indian-style numbers).
  String normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10 ? digits.substring(digits.length - 10) : '';
  }

  /// Normalize and fetch local contacts with phone-to-name mapping.
  Future<Map<String, String>> getPhoneToNameMap() async {
    final phoneToName = <String, String>{};

    if (!await Permission.contacts.isGranted) {
      final result = await Permission.contacts.request();
      if (!result.isGranted) return {};
    }

    final hasPermission = await FlutterContacts.requestPermission();
    if (!hasPermission) return {};

    try {
      final contacts = await FlutterContacts.getContacts(withProperties: true);
      for (var contact in contacts) {
        for (var phone in contact.phones) {
          final normalized = normalizePhone(phone.number);
          if (normalized.isNotEmpty) {
            phoneToName[normalized] = contact.displayName;
          }
        }
      }
    } catch (e) {
      debugPrint("❌ Error reading contacts: $e");
    }

    return phoneToName;
  }

  /// Fetch stories of the current user and contacts (local + chat users).
  Future<void> fetchContactsStories() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final cutoff = now.subtract(const Duration(hours: 24));
      final currentUid = user.uid;
      final normalizedMyPhone = normalizePhone(user.phoneNumber ?? '');

      // Step 1: Get all chat partner UIDs
      final chatSnapshot = await firestore
          .collection('chats')
          .where('participants', arrayContains: currentUid)
          .get();

      final chatPartnerUIDs = chatSnapshot.docs
          .expand((doc) => List<String>.from(doc['participants']))
          .where((id) => id != currentUid)
          .toSet();

      // Step 2: Map local phone numbers to names
      final phoneToNameMap = await getPhoneToNameMap();

      // Step 3: Get all user profiles from Firestore
      final usersSnapshot = await firestore.collection('users').get();
      final uidToLocalName = <String, String>{};
      final phoneToUid = <String, String>{};

      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        final phone =
            normalizePhone(data['phone'] ?? data['normalizedPhone'] ?? '');
        if (phone.isNotEmpty && phone != normalizedMyPhone) {
          phoneToUid[phone] = doc.id;
          if (phoneToNameMap.containsKey(phone)) {
            uidToLocalName[doc.id] = phoneToNameMap[phone]!;
          }
        }
      }

      final contactUIDs = phoneToUid.values.toSet();
      final storyUIDs = {...chatPartnerUIDs, ...contactUIDs, currentUid};

      // Step 4: Check each user’s story status
      final userStories = <Map<String, dynamic>>[];

      for (final uid in storyUIDs) {
        final storySnap = await firestore
            .collection('stories')
            .doc(uid)
            .collection('items')
            .where('uploadedAt', isGreaterThan: cutoff)
            .get();

        if (storySnap.docs.isNotEmpty) {
          final latest = storySnap.docs
              .map((d) => d.data()['uploadedAt'])
              .whereType<Timestamp>()
              .reduce((a, b) => a.compareTo(b) > 0 ? a : b);

          userStories.add({'userId': uid, 'uploadedAt': latest});
        }
      }

      // Step 5: Batch fetch corresponding user profiles
      final enrichedStories = <Map<String, dynamic>>[];

      for (var i = 0; i < userStories.length; i += 10) {
        final batchIds =
            userStories.skip(i).take(10).map((e) => e['userId']).toList();

        final usersBatch = await firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: batchIds)
            .get();

        for (final doc in usersBatch.docs) {
          final data = doc.data();
          final uid = doc.id;

          enrichedStories.add({
            'userId': uid,
            'username': data['username'] ?? '',
            'localName': uidToLocalName[uid] ?? '',
            'photoUrl': sanitizeUrl(data['profileUrl']),
            'uploadedAt':
                userStories.firstWhere((s) => s['userId'] == uid)['uploadedAt'],
          });
        }
      }

      // Step 6: Separate current user's story and contact stories
      final myStory = enrichedStories.firstWhere(
        (s) => s['userId'] == currentUid,
        orElse: () => {},
      );

      final contactStories =
          enrichedStories.where((s) => s['userId'] != currentUid).toList();

      // Step 7: Update UI (real-time efficient)
      setState(() {
        contactsWithStories = enrichedStories;
        otherStories = contactStories;
        myPhotoUrl = myStory['photoUrl'];
        hasUploadedStory = myStory['uploadedAt'] != null &&
            (myStory['uploadedAt'] as Timestamp).toDate().isAfter(cutoff);
      });
    } catch (e) {
      debugPrint('❌ Error fetching stories: $e');
    }
  }

  void listenToStoryChanges() async {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    if (user == null) return;

    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    final normalizedMyPhone = normalizePhone(user.phoneNumber ?? '');

    final phoneToNameMap = await getPhoneToNameMap();
    final usersSnapshot = await firestore.collection('users').get();
    final uidToLocalName = <String, String>{};
    final phoneToUid = <String, String>{};

    for (var doc in usersSnapshot.docs) {
      final data = doc.data();
      final phone =
          normalizePhone(data['phone'] ?? data['normalizedPhone'] ?? '');
      if (phone.isNotEmpty && phone != normalizedMyPhone) {
        phoneToUid[phone] = doc.id;
        if (phoneToNameMap.containsKey(phone)) {
          uidToLocalName[doc.id] = phoneToNameMap[phone]!;
        }
      }
    }

    final storyDocRef = firestore.collection('stories');

    _storySubscription?.cancel(); // Cancel old listener
    _storySubscription = storyDocRef.snapshots().listen((_) async {
      final now = DateTime.now();
      final cutoff = now.subtract(const Duration(hours: 24));
      final storyUIDs = phoneToUid.values.toSet()..add(user.uid);

      final userStories = <Map<String, dynamic>>[];

      for (final uid in storyUIDs) {
        final storySnap = await firestore
            .collection('stories')
            .doc(uid)
            .collection('items')
            .where('uploadedAt', isGreaterThan: cutoff)
            .get();

        if (storySnap.docs.isNotEmpty) {
          final latest = storySnap.docs
              .map((d) => d.data()['uploadedAt'])
              .whereType<Timestamp>()
              .reduce((a, b) => a.compareTo(b) > 0 ? a : b);

          userStories.add({'userId': uid, 'uploadedAt': latest});
        }
      }

      final enrichedStories = <Map<String, dynamic>>[];
      for (var i = 0; i < userStories.length; i += 10) {
        final batchIds =
            userStories.skip(i).take(10).map((e) => e['userId']).toList();

        final usersBatch = await firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: batchIds)
            .get();

        for (final doc in usersBatch.docs) {
          final data = doc.data();
          final uid = doc.id;

          enrichedStories.add({
            'userId': uid,
            'username': data['username'] ?? '',
            'localName': uidToLocalName[uid] ?? '',
            'photoUrl': sanitizeUrl(data['profileUrl']),
            'uploadedAt':
                userStories.firstWhere((s) => s['userId'] == uid)['uploadedAt'],
          });
        }
      }

      final myStory = enrichedStories.firstWhere(
        (s) => s['userId'] == currentUserId,
        orElse: () => {},
      );

      final contactStories =
          enrichedStories.where((s) => s['userId'] != currentUserId).toList();

      if (mounted) {
        setState(() {
          contactsWithStories = enrichedStories;
          otherStories = contactStories;
          myPhotoUrl = myStory['photoUrl'];
          hasUploadedStory = myStory['uploadedAt'] != null &&
              (myStory['uploadedAt'] as Timestamp).toDate().isAfter(cutoff);
        });
      }
    });
  }

  Future<void> _pickMediaAndUpload(ImageSource source, bool isVideo) async {
    final picker = ImagePicker();
    final pickedFile = isVideo
        ? await picker.pickVideo(source: source)
        : await picker.pickImage(source: source);

    if (pickedFile == null) return;

    setState(() {
      isUploading = true;
      uploadProgress = 0.0;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final uid = user.uid;
      final timestamp = DateTime.now();
      final extension = path.extension(pickedFile.path);
      final fileName = '${timestamp.millisecondsSinceEpoch}$extension';

      final ref =
          FirebaseStorage.instance.ref('status').child(uid).child(fileName);

      final uploadTask = ref.putFile(File(pickedFile.path));

      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        setState(() => uploadProgress = progress);
      });

      await uploadTask;
      final downloadUrl = await ref.getDownloadURL();

      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final userData = userDoc.data();
      if (userData == null) throw Exception("User data not found");

      final uploadedAt = Timestamp.fromDate(timestamp);

      final statusData = {
        ...buildStatusData(
          url: downloadUrl,
          caption: '',
          selectedColor: Colors.white,
          selectedFont: 'Roboto',
          textAlign: TextAlign.center,
          highlightMode: false,
          highlightColor: Colors.transparent,
        ),
        'uploadedAt': uploadedAt,
        'uid': uid,
        'username': userData['name'] ?? '',
        'profileUrl': sanitizeUrl(userData['profileUrl']),
        'isVideo': isVideo,
        'filePath': ref.fullPath,
      };

      final statusRef =
          FirebaseFirestore.instance.collection('stories').doc(uid);
      await statusRef.collection('items').add(statusData);

      // Optional expiry cleanup trigger (client-side)
      Timer(const Duration(hours: 24), () {
        if (mounted) {
          setState(() => hasUploadedStory = false);
        }
      });

      setState(() {
        isUploading = false;
        uploadProgress = 0.0;
        hasUploadedStory = true;
      });

      fetchContactsStories(); // or reload with real-time listener
    } catch (e) {
      debugPrint('❌ Upload error: $e');

      setState(() {
        isUploading = false;
        uploadProgress = 0.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to upload status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showMediaPickerSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Pick Image'),
              onTap: () {
                Navigator.pop(context);
                _pickMediaAndUpload(ImageSource.gallery, false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Pick Video'),
              onTap: () {
                Navigator.pop(context);
                _pickMediaAndUpload(ImageSource.gallery, true);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void openStoryViewer(BuildContext context, String userId) {
    final hasStory = contactsWithStories.any((s) => s['userId'] == userId);
    if (hasStory) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MyStatusScreen(userId: userId)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(hours: 24));
    ImageProvider imageProvider;

    try {
      if (localPreviewFile != null) {
        imageProvider = FileImage(localPreviewFile!);
      } else if ((profileImageUrl ?? '').isNotEmpty) {
        imageProvider = CachedNetworkImageProvider(profileImageUrl!);
      } else {
        imageProvider = const AssetImage('assets/default_avatar.png');
      }
    } catch (e) {
      print('⚠️ Error loading image: $e');
      imageProvider = const AssetImage('assets/default_avatar.png');
    }

    final otherStories = contactsWithStories
        .where((story) =>
            story['userId'] != widget.currentUserId &&
            (story['uploadedAt'] as Timestamp?)?.toDate().isAfter(cutoff) ==
                true)
        .toList();

    final Map<String, dynamic>? myStory =
        contactsWithStories.cast<Map<String, dynamic>?>().firstWhere(
              (story) => story?['userId'] == widget.currentUserId,
              orElse: () => null,
            );

    final uploadedAt = myStory != null && myStory['uploadedAt'] is Timestamp
        ? (myStory['uploadedAt'] as Timestamp).toDate()
        : null;

    final isMyStoryActive = uploadedAt != null && uploadedAt.isAfter(cutoff);
    final photoUrl = myStory?['photoUrl'];

    return Column(
      children: [
        SizedBox(
          height: 88,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 1 + otherStories.length,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                // My Status Bubble
                return Padding(
                  padding: const EdgeInsets.only(right: 10, top: 2),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (isMyStoryActive) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MyStatusScreen(
                                    userId: widget.currentUserId),
                              ),
                            );
                          } else {
                            _showMediaPickerSheet();
                          }
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 64,
                              height: 64,
                              child: isUploading
                                  ? CircularProgressIndicator(
                                      strokeWidth: 3,
                                      value: uploadProgress,
                                      valueColor: const AlwaysStoppedAnimation(
                                          Color(0xFF111B21)),
                                      backgroundColor: Colors.grey.shade300,
                                    )
                                  : isMyStoryActive
                                      ? CircularProgressIndicator(
                                          strokeWidth: 3,
                                          value: 1.0,
                                          valueColor:
                                              const AlwaysStoppedAnimation(
                                                  Color(0xFF111B21)),
                                          backgroundColor: Colors.grey.shade300,
                                        )
                                      : DottedBorder(
                                          customPath: (size) => Path()
                                            ..addOval(Rect.fromLTWH(
                                                0, 0, size.width, size.height)),
                                          dashPattern: [4, 3],
                                          color: Colors.grey,
                                          strokeWidth: 1.5,
                                          borderType: BorderType.Circle,
                                          padding: const EdgeInsets.all(6),
                                          child: const SizedBox(
                                              width: 64, height: 64),
                                        ),
                            ),
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: imageProvider,
                              backgroundColor: Colors.grey[300],
                            ),
                            if (!isMyStoryActive)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.blue,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.add,
                                      size: 14, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text("Add Story", style: TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              }

              // Contact Stories
              final storyUser = otherStories[index - 1];
              final photoUrl = storyUser['photoUrl'] as String?;
              final localName = storyUser['localName'] ?? 'User';

              return Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () =>
                          openStoryViewer(context, storyUser['userId']),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.purple, Colors.orange],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: ClipOval(
                              child: (photoUrl != null && photoUrl.isNotEmpty)
                                  ? CachedNetworkImage(
                                      imageUrl: photoUrl,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          const Center(
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2)),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.person, size: 40),
                                    )
                                  : const Icon(Icons.person, size: 40),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    SizedBox(
                      width: 70,
                      child: Text(
                        localName,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        )
      ],
    );
  }
}
