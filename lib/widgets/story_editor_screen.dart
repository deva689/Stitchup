import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:stitchup/widgets/emoji_overlay.dart';

class StoryEditorScreen extends StatefulWidget {
  final File image;
  final File file;
  final bool isVideo;
  final String currentUserId;

  const StoryEditorScreen({
    super.key,
    required this.file,
    required this.isVideo,
    required this.currentUserId,
    required this.image,
  });

  @override
  State<StoryEditorScreen> createState() => _StoryEditorScreenState();
}

class _StoryEditorScreenState extends State<StoryEditorScreen> {
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

  void _openTextEditor() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TextEditorScreen()),
    );
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

  Future<void> _pickMusic() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null) {
      setState(() {
        selectedMusic = result.files.single.name;
      });
    }
  }

  Future<void> _cropImage() async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: widget.image.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
      ],
    );

    if (cropped != null) {
      setState(() {
        croppedImage = File(cropped.path);
      });
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
    final bgImage = croppedImage ?? widget.image;
    double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset:
          false, // Keyboard open aanaalum body resize agakudadhu
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.file(bgImage, fit: BoxFit.contain),
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
                        onPressed: () {
                          // After saving story / uploading / anything
                          Navigator.pop(context); // Close editor
                        },
                      ),
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
                      builder: (context) => StoryEditorScreen(
                        file: widget.file,
                        isVideo: widget.isVideo,
                        currentUserId: widget.currentUserId,
                        image: widget.image,
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
                      if (!showEmojiPicker) // ✅ Only show when emoji picker not open
                        _iconBtn(Icons.music_note, _pickMusic),
                      if (!showEmojiPicker) // ✅ Only show when emoji picker not open
                        _iconBtn(Icons.crop_rotate_rounded, _cropImage),
                      if (!showEmojiPicker) // ✅ Only show when emoji picker not open
                        _iconBtn(Icons.emoji_emotions_outlined, () {
                          setState(() => showEmojiPicker = !showEmojiPicker);
                        }),
                      if (!showEmojiPicker) // ✅ Only show when emoji picker not open
                        _iconBtn(Icons.text_fields_rounded, _openTextEditor),
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
  final bool isEmoji;

  const DraggableResizableText({
    super.key,
    required this.text,
    this.isEmoji = false,
  });

  @override
  State<DraggableResizableText> createState() => _DraggableResizableTextState();
}

class _DraggableResizableTextState extends State<DraggableResizableText> {
  Offset position = const Offset(100, 100);
  double scale = 1.0;
  double previousScale = 1.0;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onScaleStart: (details) {
          previousScale = scale;
        },
        onScaleUpdate: (details) {
          setState(() {
            scale = (previousScale * details.scale).clamp(0.5, 4.0);
            if (details.scale == 1.0) {
              position += details.focalPointDelta;
            }
          });
        },
        child: Transform(
          transform: Matrix4.identity()..scale(scale),
          alignment: Alignment.center,
          child: Text(
            widget.text,
            style: TextStyle(
              fontSize: widget.isEmoji ? 40 : 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class TextEditorScreen extends StatefulWidget {
  const TextEditorScreen({super.key});

  @override
  State<TextEditorScreen> createState() => _TextEditorScreenState();
}

class _TextEditorScreenState extends State<TextEditorScreen>
    with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  File? bgImage;

  Color selectedColor = Colors.white;
  TextAlign textAlign = TextAlign.center;
  String selectedFont = 'Roboto';

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

  double hue = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (_focusNode.hasFocus) {
      _focusNode.unfocus();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leadingWidth: 90,
          leading: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: TextButton(
              onPressed: () {
                Navigator.pop(context, {
                  'text': _controller.text,
                  'color': selectedColor,
                  'font': selectedFont,
                  'align': textAlign,
                });
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: null,
              ),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: const Text(
                  "Done",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Container(
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
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white24,
                ),
                child: IconButton(
                  icon: const Icon(Icons.text_fields,
                      color: Colors.white, size: 18),
                  onPressed: () {},
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Stack(
            children: [
              if (bgImage != null)
                Positioned.fill(
                  child: Image.file(
                    bgImage!,
                    fit: BoxFit.contain,
                  ),
                ),
              Align(
                alignment: Alignment.center,
                child: SingleChildScrollView(
                  reverse: true,
                  physics: const NeverScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height * 0.6,
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      textAlign: textAlign,
                      style: getFontStyle(selectedFont, selectedColor, 40)
                          .copyWith(fontWeight: FontWeight.bold),
                      cursorColor: selectedColor,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Add Text',
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Color Picker
              Positioned(
                right: 16,
                top: MediaQuery.of(context).size.height * 0.04,
                child: GestureDetector(
                  onVerticalDragUpdate: (details) {
                    double height = 200;
                    double y = details.localPosition.dy.clamp(0.0, height);
                    setState(() {
                      if (y < height * 0.2) {
                        double value = y / (height * 0.2);
                        selectedColor =
                            HSVColor.fromAHSV(1, 0, 0, value).toColor();
                      } else {
                        double hueY = (y - height * 0.2) / (height * 0.8);
                        double hue = hueY * 360;
                        selectedColor =
                            HSVColor.fromAHSV(1, hue, 1, 1).toColor();
                      }
                    });
                  },
                  child: Container(
                    width: 12,
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

              // Font picker stays above keyboard
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
                            color: isSelected
                                ? Colors.white24
                                : Colors.transparent,
                          ),
                          child: Center(
                            child: Center(
                              child: Text(
                                'Aa',
                                style: getFontStyle(font, Colors.white, 16),
                              ),
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
        ),
      ),
    );
  }
}
