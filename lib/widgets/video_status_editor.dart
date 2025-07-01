import 'dart:io';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:stitchup/models/emoji_overlay.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import 'package:video_trimmer/video_trimmer.dart';
import 'package:file_picker/file_picker.dart';

class VideoStatusEditor extends StatefulWidget {
  final File video;
  final File filePath;
  final bool isVideo;
  final String currentUserId;
  final File bgMedia;

  const VideoStatusEditor({
    super.key,
    required this.filePath,
    required this.isVideo,
    required this.currentUserId,
    required this.video,
    required this.bgMedia,
  });

  @override
  State<VideoStatusEditor> createState() => _VideoStatusEditorState();
}

class _VideoStatusEditorState extends State<VideoStatusEditor> {
  List<Stroke> strokes = [];
  Stroke? currentStroke;
  List<Widget> overlays = [];
  Color selectedColor = Colors.white;
  double strokeWidth = 4.0;
  bool isDrawing = false;
  bool showEmojiPicker = false;
  String caption = '';
  File? croppedImage;
  String? selectedMusic;
  bool isSaved = false;
  bool isEditingEmoji = false; // 🆕
  bool isMovingEmoji = false; // 🔥 true => only emoji+delete icon show
  List<Map<String, dynamic>> matchedUsers = [];
  bool isLoading = true;
  bool highlightMode = false; // ✅ Correct: false means highlight is off
  bool get isVideo => widget.isVideo;
  File? bgVideo; // this is in your state
  File? selectedFile; // For image or video file
  String selectedFont = 'Roboto'; // Default font name
  TextAlign textAlign = TextAlign.center;
  Color highlightColor = Colors.transparent;

  late VideoPlayerController _controller;
  bool _isVideoInitialized = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    selectedFile = widget.filePath;
    fetchMatchedContacts();
    if (widget.isVideo) {
      _controller = VideoPlayerController.file(widget.bgMedia)
        ..initialize().then((_) {
          setState(() {
            _isVideoInitialized = true;
            _controller.setLooping(true);
            _controller.play();
          });
        });
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (widget.isVideo) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _openTextEditor(File imageFile) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TextEditorScreen(bgImage: imageFile),
      ),
    );

    if (result != null) {
      final String text = result['text'] ?? '';
      final Color textColor = result['textColor'] ?? Colors.white;
      final String fontFamily = result['fontFamily'] ?? 'Roboto';
      final TextAlign align = result['textAlign'] ?? TextAlign.center;
      final int highlightMode = result['highlightMode'] ?? 0;
      final Color highlightColor =
          result['highlightColor'] ?? Colors.transparent;

      setState(() {
        overlays.add(
          DraggableResizableText(
            text: text,
            textColor: textColor,
            fontFamily: fontFamily,
            textAlign: textAlign,
            highlightMode: highlightMode,
            highlightColor: highlightColor,
          ),
        );
      });
    }
  }

  String normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10 ? digits.substring(digits.length - 10) : '';
  }

  Future<List<String>> getLocalContactNumbers() async {
    Set<String> phoneSet = {};

    if (!await Permission.contacts.isGranted) {
      final result = await Permission.contacts.request();
      if (!result.isGranted) return [];
    }

    try {
      final hasPermission = await FlutterContacts.requestPermission();
      if (!hasPermission) return [];

      final contacts = await FlutterContacts.getContacts(withProperties: true);

      for (var contact in contacts) {
        for (var phone in contact.phones) {
          final normalized = normalizePhone(phone.number);
          if (normalized.isNotEmpty) {
            phoneSet.add(normalized);
          }
        }
      }

      return phoneSet.toList();
    } catch (e) {
      debugPrint("❌ Error getting contacts: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getMatchedUsers(
      List<String> localPhones) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    final currentUserPhone = normalizePhone(currentUser.phoneNumber ?? '');
    List<Map<String, dynamic>> matched = [];

    final snapshot = await FirebaseFirestore.instance.collection('users').get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final uid = doc.id;

      final firestorePhone =
          normalizePhone(data['phone'] ?? data['normalizedPhone'] ?? '');
      if (firestorePhone.isEmpty || firestorePhone == currentUserPhone) {
        continue;
      }

      if (localPhones.contains(firestorePhone)) {
        matched.add({
          'uid': uid,
          'name': data['name'] ?? 'Unknown',
          'phone': firestorePhone,
          'photo': data['profileUrl'] ?? '',
          'isOnline': data['isOnline'] ?? false,
          'lastSeen': data['lastSeen'],
          'isTypingTo': data['isTypingTo'] ?? '',
        });
      }
    }

    return matched;
  }

  Future<void> fetchMatchedContacts() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    final localNumbers = await getLocalContactNumbers();
    final users = await getMatchedUsers(localNumbers);

    if (!mounted) return; // <-- check again before calling setState

    setState(() {
      matchedUsers = users;
      isLoading = false;
    });
  }

  String generateChatId(String id1, String id2) {
    return id1.hashCode <= id2.hashCode ? '${id1}_$id2' : '${id2}_$id1';
  }

  void _addEmojiOverlay(String emoji) {
    overlays.add(
      EmojiOverlayStateful(
        emoji: emoji,
        initialPosition: Offset(
          MediaQuery.of(context).size.width / 2 - 25,
          MediaQuery.of(context).size.height / 2 - 25,
        ),
        onDelete: () {
          setState(() {
            overlays.removeLast();
            isEditingEmoji = false; // ✅ After delete, allow adding again!
          });
        },
        onDragStart: () {
          setState(() {
            isMovingEmoji = true;
          });
        },
        onDragEnd: () {
          setState(() {
            isMovingEmoji = false;
          });
        },
      ),
    );
    setState(() {});
  }

  // void _pickMusic() async {
  //   final selectedAudioUrl = await Navigator.push(
  //     context,
  //     MaterialPageRoute(builder: (_) => PixabayAudioListScreen()),
  //   );

  //   if (selectedAudioUrl != null) {
  //     // Use the audio URL, for example:
  //     print('Selected audio URL: $selectedAudioUrl');
  //     // You can set it to a variable or pass it to a player
  //   }
  // }

  Future<void> pickFile() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        selectedFile = File(picked.path);
      });
    }
  }

  // Future<void> _cropImage() async {
  //   final cropped = await ImageCropper().cropImage(
  //     sourcePath: widget.bgMedia.path, // ✅ must be an image file
  //     compressFormat: ImageCompressFormat.jpg,
  //     compressQuality: 90,
  //     uiSettings: [
  //       AndroidUiSettings(
  //         toolbarTitle: 'Crop Image',
  //         toolbarColor: Colors.black,
  //         toolbarWidgetColor: Colors.white,
  //         initAspectRatio: CropAspectRatioPreset.original,
  //         lockAspectRatio: false,
  //         aspectRatioPresets: [
  //           CropAspectRatioPreset.original,
  //           CropAspectRatioPreset.square,
  //           CropAspectRatioPreset.ratio3x2,
  //           CropAspectRatioPreset.ratio4x3,
  //           CropAspectRatioPreset.ratio16x9,
  //         ],
  //       ),
  //     ],
  //   );

  //   if (cropped != null) {
  //     setState(() {
  //       croppedImage = File(cropped.path); // ✅ Update image after crop
  //     });
  //   }
  // }

  void _pickAndTrimVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null) {
      final videoFile = File(result.files.single.path!);

      final trimmedPath = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoTrimmerScreen(videoFile: videoFile),
        ),
      );

      if (trimmedPath != null) {
        // Play preview or upload to Firebase
        print("Trimmed video path: $trimmedPath");
      }
    }
  }

  void _openColorPicker() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Pick Color"),
        content: BlockPicker(
          pickerColor: selectedColor,
          onColorChanged: (color) {
            setState(() {
              selectedColor = color;
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _toggleDrawMode() {
    setState(() {
      isDrawing = !isDrawing;
      if (!isDrawing) {
        // Drawing done
        isSaved = true; // <-- paste here!
        showEmojiPicker = false;
      }
    });
  }

  void _undoLastStroke() {
    if (strokes.isNotEmpty) {
      setState(() {
        strokes.removeLast();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgImage = croppedImage ?? widget.video;
    double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset:
          false, // Keyboard open aanaalum body resize agakudadhu
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: widget.isVideo
                ? (_isVideoInitialized
                    ? Center(
                        child: AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        ),
                      )
                    : const Center(
                        child: CircularProgressIndicator(color: Colors.white)))
                : Image.file(bgImage, fit: BoxFit.contain),
          ),

          Positioned.fill(
            child: InteractiveViewer(
              panEnabled: true,
              scaleEnabled: true,
              minScale: 1.0,
              maxScale: 5.0,
              child: Stack(
                children: [
                  // Drawing layer
                  Positioned.fill(
                    child: GestureDetector(
                      onPanStart: (details) {
                        if (!isDrawing) return;
                        RenderBox box = context.findRenderObject() as RenderBox;
                        Offset point =
                            box.globalToLocal(details.globalPosition);
                        setState(() {
                          currentStroke = Stroke(
                            points: [point],
                            color: selectedColor,
                            strokeWidth: strokeWidth,
                          );
                        });
                      },
                      onPanUpdate: (details) {
                        if (!isDrawing) return;
                        RenderBox box = context.findRenderObject() as RenderBox;
                        Offset point =
                            box.globalToLocal(details.globalPosition);
                        setState(() {
                          currentStroke?.points.add(point);
                        });
                      },
                      onPanEnd: (_) {
                        if (!isDrawing) return;
                        if (currentStroke != null) {
                          setState(() {
                            strokes.add(currentStroke!);
                            currentStroke = null;
                          });
                        }
                      },
                      child: CustomPaint(
                        painter: DrawingPainter(strokes, currentStroke),
                      ),
                    ),
                  ),

                  // Emoji overlays
                  ...overlays,
                ],
              ),
            ),
          ),

          // 🔥 Delete Icon (Show ONLY when moving emoji)
          if (isMovingEmoji)
            Positioned(
              top: 100,
              left: 10,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Color(0xFFE90039), // Same white background
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.delete,
                  size: 28,
                  color: Colors.white,
                ),
              ),
            ),

          // 🔥 Emoji Picker (When adding emoji - NOT during editing)
          if (showEmojiPicker && !isEditingEmoji)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: const Color.fromARGB(255, 0, 0, 0),
                height: MediaQuery.of(context).size.height * 0.970,
                child: Column(
                  children: [
                    // Top Bar inside Emoji Picker
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                          ), // ❌ Cancel Picker
                          onPressed: () {
                            setState(() {
                              showEmojiPicker = false;
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.emoji_emotions_outlined,
                              color: Colors.white, size: 24), // ✅ Emoji Picker
                          onPressed: () {
                            // (optional) Maybe refresh emoji picker etc
                          },
                        ),
                      ],
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.15,
                    ),
                    Expanded(
                      child: EmojiPicker(
                        onEmojiSelected: (category, emoji) {
                          _addEmojiOverlay(emoji.emoji);
                          setState(() {
                            showEmojiPicker = false;
                            isEditingEmoji = true; // ✅ Hiding all other UI
                          });
                        },
                        config: Config(
                          categoryViewConfig: CategoryViewConfig(
                            indicatorColor: Color(0xFF111B21),
                            iconColorSelected: Color(0xFF111B21),
                          ),
                          emojiViewConfig: EmojiViewConfig(
                            columns: 8,
                            emojiSizeMax: 32,
                            backgroundColor: Colors.white,
                          ),
                          bottomActionBarConfig: BottomActionBarConfig(
                            backgroundColor: Color(0xFF111B21),
                            buttonColor: Color(0xFF111B21),
                            // (config, state, showSearchView) => SizedBox(), // Placeholder for a custom widget or action
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          AnimatedPositioned(
            duration: const Duration(
                milliseconds: 100), // 100ms = very smooth and fast
            curve: Curves.easeInOut,
            bottom: keyboardHeight > 0 ? (keyboardHeight + 14) : 24,

            left: 10,
            right: 10,

            child: Row(
              children: [
                if (!showEmojiPicker) // ✅ Caption TextField only when emoji picker not open
                  Expanded(
                    child: TextField(
                      onChanged: (val) => caption = val,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Add a caption...",
                        hintStyle: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                        ),
                        filled: true,
                        fillColor: Color(0xFF111B21),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(85),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 20),
                      ),
                    ),
                  ),
                const SizedBox(width: 6),
                if (!showEmojiPicker) // ✅ Only show when emoji picker not open
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF2C4152),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: () async {
                            if (selectedFile == null) return;

                            Navigator.of(context)
                                .pop(); // Close the editor immediately

                            try {
                              final uid =
                                  FirebaseAuth.instance.currentUser!.uid;

                              final userDoc = await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(uid)
                                  .get();
                              final userData = userDoc.data();
                              if (userData == null)
                                throw Exception("User not found");

                              final extension =
                                  path.extension(selectedFile!.path);
                              final ref = FirebaseStorage.instance
                                  .ref('status')
                                  .child(uid)
                                  .child(
                                      '${DateTime.now().millisecondsSinceEpoch}$extension');

                              // ✅ Upload media
                              await ref.putFile(selectedFile!);
                              final url = await ref.getDownloadURL();

                              // ✅ Match viewers
                              final localNumbers =
                                  await getLocalContactNumbers();
                              final matchedUsers =
                                  await getMatchedUsers(localNumbers);
                              final viewers = matchedUsers
                                  .map((user) => user['uid'])
                                  .toList();

                              // ✅ Save to Firestore (one doc per status)
                              final statusId = const Uuid().v4(); // unique ID
                              await FirebaseFirestore.instance
                                  .collection('status')
                                  .doc(statusId)
                                  .set({
                                'userId': uid,
                                'statusId': statusId,
                                'mediaUrl': url,
                                'isVideo': isVideo,
                                'timestamp': Timestamp.now(),
                                'views': [], // initially no views
                                'viewers': viewers,
                                'caption': caption, // ✅ include your caption
                                'userName': userData['name'] ?? '',
                                'profileImageUrl':
                                    userData['profileImage'] ?? '',
                              });

                              // 🎉 Success!
                            } catch (e) {
                              print('❌ Error uploading status: $e');
                            }
                          }),
                    ),
                  ),
              ],
            ),
          ),
          if (!showEmojiPicker) // ✅ Only show when emoji picker not open
            Positioned(
              top: 40,
              left: 10,
              child: _iconBtn(Icons.close, () {
                if (isSaved || (strokes.isEmpty && overlays.isEmpty)) {
                  // Saved already OR no edits done (fresh screen)
                  Navigator.pop(context);
                } else {
                  // Editing started but not saved, reload StoryEditorScreen
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoStatusEditor(
                        bgMedia: bgImage,
                        filePath: widget.filePath,
                        isVideo: widget.isVideo,
                        currentUserId: widget.currentUserId,
                        video: widget.video,
                      ),
                    ),
                  );
                }
              }),
            ),
          Positioned(
            top: 40,
            right: 10,
            child: isDrawing
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isMovingEmoji)
                        _iconBtn(Icons.color_lens, _openColorPicker),
                      if (!isMovingEmoji)
                        _iconBtn(Icons.gesture, () {
                          setState(() {
                            // Cycle strokeWidth
                            if (strokeWidth == 4.0) {
                              strokeWidth = 8.0;
                            } else if (strokeWidth == 8.0) {
                              strokeWidth = 12.0;
                            } else {
                              strokeWidth = 4.0;
                            }

                            // ALSO update all previous strokes' width
                            for (var stroke in strokes) {
                              stroke.strokeWidth = strokeWidth;
                            }
                          });
                        }),
                      if (!isMovingEmoji) _iconBtn(Icons.undo, _undoLastStroke),
                      if (!isMovingEmoji) _iconBtn(Icons.done, _toggleDrawMode),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // if (!showEmojiPicker) // ✅ Only show when emoji picker not open
                      //   _iconBtn(Icons.music_note, _pickMusic),

                      if (!showEmojiPicker) // ✅ Only show when emoji picker not open
                        _iconBtn(Icons.emoji_emotions_outlined, () {
                          setState(() => showEmojiPicker = !showEmojiPicker);
                        }),
                      if (!showEmojiPicker) // ✅ Only show when emoji picker not open
                        _iconBtn(Icons.text_fields_rounded,
                            () => _openTextEditor(bgImage)),
                      if (!showEmojiPicker) // ✅ Only show when emoji picker not open
                        _iconBtn(Icons.edit, () {
                          _toggleDrawMode();
                          _openColorPicker();
                        }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

class Stroke {
  List<Offset> points;
  Color color;
  double strokeWidth;

  Stroke(
      {required this.points, required this.color, required this.strokeWidth});
}

class DrawingPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke? currentStroke;

  DrawingPainter(this.strokes, this.currentStroke);

  @override
  void paint(Canvas canvas, Size size) {
    for (var stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke.strokeWidth;

      for (int i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
      }
    }

    if (currentStroke != null) {
      final paint = Paint()
        ..color = currentStroke!.color
        ..strokeCap = StrokeCap.round
        ..strokeWidth = currentStroke!.strokeWidth;

      for (int i = 0; i < currentStroke!.points.length - 1; i++) {
        canvas.drawLine(
            currentStroke!.points[i], currentStroke!.points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class DraggableResizableText extends StatefulWidget {
  final String text;
  final Color textColor;
  final String fontFamily;
  final TextAlign textAlign;
  final int highlightMode;
  final Color highlightColor;
  final bool isEmoji;

  const DraggableResizableText({
    super.key,
    required this.text,
    required this.textColor,
    required this.fontFamily,
    required this.textAlign,
    required this.highlightMode,
    required this.highlightColor,
    this.isEmoji = false,
  });

  @override
  State<DraggableResizableText> createState() => _DraggableResizableTextState();
}

class _DraggableResizableTextState extends State<DraggableResizableText> {
  Offset position = const Offset(100, 100);
  double scale = 1.0;
  double previousScale = 1.0;
  Offset initialFocalPoint = Offset.zero;
  Offset initialPosition = Offset.zero;
  bool isDragging = false;
  bool isOverDelete = false;
  bool isDeleted = false;

  final GlobalKey textKey = GlobalKey(); // ✅ Required for position detection

  // Returns a safe Google Font or fallback
  TextStyle getSafeGoogleFont(
    String fontFamily,
    Color color,
    double fontSize,
    Color backgroundColor,
  ) {
    try {
      final fontMap = GoogleFonts.asMap();
      final normalizedKey = fontFamily.replaceAll(' ', '').toLowerCase();
      final matchedKey = fontMap.keys.firstWhere(
        (key) => key.replaceAll(' ', '').toLowerCase() == normalizedKey,
        orElse: () => 'roboto',
      );

      return GoogleFonts.getFont(
        matchedKey,
      ).copyWith(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        backgroundColor: backgroundColor,
      );
    } catch (e) {
      return TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        backgroundColor: backgroundColor,
      );
    }
  }

  // Check if text center is inside delete zone
  bool isInDeleteZone(Size screenSize) {
    final renderBox = textKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return false;

    final textPosition = renderBox.localToGlobal(Offset.zero);
    final textSize = renderBox.size;

    final textCenter = Offset(
      textPosition.dx + textSize.width / 2,
      textPosition.dy + textSize.height / 2,
    );

    const deleteIconSize = 56.0;
    const deleteIconTop = 100.0;
    const deleteIconLeft = 10.0;

    return textCenter.dx >= deleteIconLeft &&
        textCenter.dx <= deleteIconLeft + deleteIconSize &&
        textCenter.dy >= deleteIconTop &&
        textCenter.dy <= deleteIconTop + deleteIconSize;
  }

  @override
  Widget build(BuildContext context) {
    if (isDeleted) return const SizedBox(); // Hidden when deleted

    final screenSize = MediaQuery.of(context).size;
    final backgroundColor =
        widget.highlightMode == 0 ? Colors.transparent : widget.highlightColor;

    return Stack(
      children: [
        // Draggable Text
        Positioned(
          left: position.dx,
          top: position.dy,
          child: GestureDetector(
            onScaleStart: (details) {
              previousScale = scale;
              initialFocalPoint = details.focalPoint;
              initialPosition = position;
              setState(() {
                isDragging = true;
              });
            },
            onScaleUpdate: (details) {
              setState(() {
                scale = previousScale * details.scale;
                final Offset delta = details.focalPoint - initialFocalPoint;
                position = initialPosition + delta;
                isOverDelete = isInDeleteZone(screenSize);
              });
            },
            onScaleEnd: (details) {
              setState(() {
                if (isOverDelete) {
                  print("✅ Text dropped over delete icon.");
                  isDeleted = true;
                } else {
                  print("❌ Not in delete zone.");
                }
                isDragging = false;
                isOverDelete = false;
              });
            },
            child: Transform.scale(
              scale: scale,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Container(
                  key: textKey, // ✅ Needed for accurate delete detection
                  padding: const EdgeInsets.all(8.0),
                  constraints: BoxConstraints(
                    minWidth: 50,
                    maxWidth: MediaQuery.of(context).size.width - 40,
                  ),
                  child: Text(
                    widget.text,
                    textAlign: widget.textAlign,
                    softWrap: true,
                    maxLines: null,
                    overflow: TextOverflow.visible,
                    style: getSafeGoogleFont(
                      widget.fontFamily,
                      widget.textColor,
                      40 * scale,
                      backgroundColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Delete Icon (only shows while dragging)
        if (isDragging)
          Positioned(
            top: 100,
            left: 10,
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFE90039),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.delete,
                size: 28,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}

class TextEditorScreen extends StatefulWidget {
  final File bgImage;

  const TextEditorScreen({super.key, required this.bgImage});

  @override
  State<TextEditorScreen> createState() => _TextEditorScreenState();
}

class _TextEditorScreenState extends State<TextEditorScreen>
    with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Color selectedColor = Colors.white;
  TextAlign textAlign = TextAlign.center;
  String selectedFont = 'Roboto';
  String typedText = "H"; // Example, replace with your actual text variable
  String caption = '';
  int highlightMode = 0; // 0 = transparent, 1 = black, 2 = light white
  bool isHighlighted = false;

  bool isTextBackgroundEnabled = false;

  final List<String> fonts = [
    'Roboto',
    'Pacifico',
    'Lobster',
    'Oswald',
    'DancingScript',
    'OpenSans',
    'Raleway',
    'Poppins',
  ];

  TextStyle getFontStyle(String fontName, Color color, double fontSize) {
    switch (fontName) {
      case 'Pacifico':
        return GoogleFonts.pacifico(color: color, fontSize: fontSize);
      case 'Lobster':
        return GoogleFonts.lobster(color: color, fontSize: fontSize);
      case 'Oswald':
        return GoogleFonts.oswald(color: color, fontSize: fontSize);
      case 'DancingScript':
        return GoogleFonts.dancingScript(color: color, fontSize: fontSize);
      case 'OpenSans':
        return GoogleFonts.openSans(color: color, fontSize: fontSize);
      case 'Raleway':
        return GoogleFonts.raleway(color: color, fontSize: fontSize);
      case 'Poppins':
        return GoogleFonts.poppins(color: color, fontSize: fontSize);
      case 'Roboto':
      default:
        return GoogleFonts.roboto(color: color, fontSize: fontSize);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    Navigator.pop(context);
    return true;
  }

  Color getHighlightColor() {
    if (highlightMode == 1) {
      return Colors.black;
    } else if (highlightMode == 2) {
      return Colors.white.withOpacity(0.3); // light white
    } else {
      return Colors.transparent;
    }
  }

  Alignment getScreenAlignment() {
    switch (textAlign) {
      case TextAlign.left:
        return Alignment.centerLeft;
      case TextAlign.right:
        return Alignment.centerRight;
      case TextAlign.center:
      default:
        return Alignment.center;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Blurred background
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),
          ),

          // Media preview (video or image)
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.black,
              ),
              clipBehavior: Clip.hardEdge,
              // child: Builder(
              //   builder: (context) {
              //     if (widget.isVideo) {
              //       if (_isVideoInitialized) {
              //         return AspectRatio(
              //           aspectRatio: _controller.value.aspectRatio,
              //           child: VideoPlayer(_controller),
              //         );
              //       } else {
              //         return const Center(child: CircularProgressIndicator());
              //       }
              //     } else {
              // return Image.file(widget.bgMedia, fit: BoxFit.cover);
              //     }
              //  },
              //   ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.file(
                  widget.bgImage,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          ),

          // Custom AppBar over image
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Done button
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context, {
                          'text': _controller.text,
                          'textColor': selectedColor,
                          'fontFamily': selectedFont,
                          'textAlign': textAlign,
                          'highlightMode': highlightMode,
                          'highlightColor': getHighlightColor(),
                          'caption': caption, // ✅ ADD THIS LINE
                        });
                      },
                      child: const Text(
                        "Done",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: MediaQuery.of(context).size.width / 5),

                  // Align icon
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white24,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.format_align_center,
                          color: Colors.white, size: 18),
                      onPressed: () {
                        setState(() {
                          textAlign = textAlign == TextAlign.center
                              ? TextAlign.left
                              : textAlign == TextAlign.left
                                  ? TextAlign.right
                                  : TextAlign.center;
                        });
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Text background toggle icon
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white24,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.auto_fix_high,
                          color: Colors.white, size: 18),
                      onPressed: () {
                        setState(() {
                          highlightMode = (highlightMode + 1) % 3;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Center text field
          Align(
            alignment: Alignment.center,
            child: IntrinsicWidth(
              child: IntrinsicHeight(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  decoration: BoxDecoration(
                    color: getHighlightColor(),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    textAlign: textAlign,
                    style:
                        getFontStyle(selectedFont, selectedColor, 40).copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    cursorColor: selectedColor,
                    maxLines: null,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Add text',
                      hintStyle: TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255),
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Vertical color slider
          Positioned(
            right: 20,
            top: MediaQuery.of(context).size.height * 0.14,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                double height = 200;
                double y = details.localPosition.dy.clamp(0.0, height);
                setState(() {
                  if (y < height * 0.2) {
                    double value = y / (height * 0.2);
                    selectedColor = HSVColor.fromAHSV(1, 0, 0, value).toColor();
                  } else {
                    double hueY = (y - height * 0.2) / (height * 0.8);
                    double hue = hueY * 360;
                    selectedColor = HSVColor.fromAHSV(1, hue, 1, 1).toColor();
                  }
                });
              },
              child: Container(
                width: 10,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black,
                      Colors.white,
                      Colors.red,
                      Colors.orange,
                      Colors.yellow,
                      Colors.green,
                      Colors.cyan,
                      Colors.blue,
                      Colors.purple,
                      Colors.pink,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Font picker at bottom
          Positioned(
            bottom: MediaQuery.of(context).viewInsets.bottom + 10,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: fonts.length,
                itemBuilder: (context, index) {
                  final font = fonts[index];
                  final isSelected = selectedFont == font;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedFont = font;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 36,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? Colors.white24 : Colors.transparent,
                      ),
                      child: Center(
                        child: Text(
                          'Aa',
                          style: getFontStyle(font, Colors.white, 16),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VideoTrimmerScreen extends StatefulWidget {
  final File videoFile;

  const VideoTrimmerScreen({super.key, required this.videoFile});

  @override
  State<VideoTrimmerScreen> createState() => _VideoTrimmerScreenState();
}

class _VideoTrimmerScreenState extends State<VideoTrimmerScreen> {
  final Trimmer _trimmer = Trimmer();
  double _start = 0.0;
  double _end = 0.0;
  bool _isSaving = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    await _trimmer.loadVideo(videoFile: widget.videoFile);
    setState(() {});
  }

  void _saveTrimmedVideo() async {
    setState(() => _isSaving = true);

    await _trimmer.saveTrimmedVideo(
      startValue: _start,
      endValue: _end,
      onSave: (outputPath) {
        setState(() => _isSaving = false);
        Navigator.pop(context, outputPath); // return path
      },
    );
  }

  void _togglePlayback() async {
    bool playbackState = await _trimmer.videoPlaybackControl(
      startValue: _start,
      endValue: _end,
    );

    setState(() => _isPlaying = playbackState);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    VideoViewer(trimmer: _trimmer),
                    Positioned(
                      bottom: 80,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: IconButton(
                          icon: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 48,
                          ),
                          onPressed: _togglePlayback,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // TrimEditor(
              //   trimmer: _trimmer,
              //   viewerHeight: 60.0,
              //   viewerWidth: MediaQuery.of(context).size.width,
              //   maxVideoLength: const Duration(seconds: 30),
              //   onChangeStart: (value) => _start = value,
              //   onChangeEnd: (value) => _end = value,
              //   onChangePlaybackState: (isPlaying) {
              //     setState(() => _isPlaying = isPlaying);
              //   },
              // ),

              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Trim & Continue",
                          style: TextStyle(color: Colors.white)),
                  onPressed: _isSaving ? null : _saveTrimmedVideo,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),

          // Back button on top
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
