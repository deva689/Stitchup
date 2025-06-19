import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stitchup/Chat_camera/Chat_Camera.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String chatId;
  final String receiverId;

  final String receiverName;
  final String profileUrl;

  const CameraScreen(
      {super.key,
      required this.cameras,
      required this.chatId,
      required this.receiverId,
      required this.receiverName,
      required this.profileUrl});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isRearCameraSelected = true;
  bool _isVideoMode = false;
  bool _isFlashOn = false;
  bool _isRecording = false;
  List<Map<String, dynamic>> _galleryMedia = [];
  Timer? _recordingTimer;
  int _recordingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _loadGalleryMedia();
    _initializeCamera();
  }

  void _initializeCamera() {
    _controller = CameraController(
      _isRearCameraSelected ? widget.cameras[0] : widget.cameras[1],
      ResolutionPreset.high, // 4:3 resolution
      enableAudio: true,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    _recordingTimer?.cancel();

    super.dispose();
  }

  void _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();
      final file = File(image.path);
      setState(() {
        _galleryMedia.insert(0, {'file': file, 'isVideo': false});
      });

      // Navigate to chat screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CameraChatScreen(
            filePath: File(image.path), // or File(video.path)
            isVideo: false, // or true if it's video
            currentUserId: 'yourUserIdHere', // 🔁 Replace dynamically
            image: File(image.path), // Optional preview
            receiverId: widget.receiverId, // Pass receiver ID
            receiverName: widget.receiverName, // Pass receiver name
            chatId: widget.chatId, // Pass chat ID
            profileUrl: widget.profileUrl, // Pass profile URL
          ),
        ),
      );
    } catch (e) {
      print('Error taking picture: $e');
    }
  }

  void _startVideoRecording() async {
    try {
      await _initializeControllerFuture;
      await _controller.startVideoRecording();

      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          _recordingSeconds++;
        });
      });
    } catch (e) {
      print('Recording start error: $e');
    }
  }

  void _stopVideoRecording() async {
    try {
      final video = await _controller.stopVideoRecording();
      final file = File(video.path);
      _recordingTimer?.cancel();
      setState(() {
        _isRecording = false;
        _galleryMedia.insert(0, {'file': file, 'isVideo': true});
      });

      // Navigate to chat screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CameraChatScreen(
            filePath: File(video.path), // or File(video.path)
            isVideo: false, // or true if it's video
            currentUserId: 'yourUserIdHere', // 🔁 Replace dynamically
            image: File(video.path), // Optional preview
            receiverId: widget.receiverId, // Pass receiver ID
            receiverName: widget.receiverName, // Pass receiver name
            chatId: widget.chatId, // Pass chat ID
            profileUrl: widget.profileUrl, // Pass profile URL
          ),
        ),
      );
    } catch (e) {
      print('Recording stop error: $e');
    }
  }

  void _switchCamera() {
    setState(() {
      _isRearCameraSelected = !_isRearCameraSelected;
      _initializeCamera();
    });
  }

  void _switchMode(bool isVideo) {
    setState(() {
      _isVideoMode = isVideo;
      _recordingSeconds = 0;
      _recordingTimer?.cancel();
      _isRecording = false;
    });
  }

  void _toggleFlash() async {
    if (!_controller.value.isInitialized) return;

    setState(() {
      _isFlashOn = !_isFlashOn;
    });

    await _controller.setFlashMode(
      _isFlashOn ? FlashMode.torch : FlashMode.off,
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _loadGalleryMedia() async {
    final photosPermission = await Permission.photos.request(); // iOS
    final storagePermission = await Permission.storage.request(); // Android

    if (!photosPermission.isGranted && !storagePermission.isGranted) {
      print("Gallery permission not granted");
      return;
    }

    try {
      final picker = ImagePicker();
      final XFile? media = await picker.pickImage(source: ImageSource.gallery);

      if (media == null) return;

      final file = File(media.path);

      setState(() {
        _galleryMedia.insert(0, {'file': file, 'isVideo': false});
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CameraChatScreen(
            filePath: File(media.path), // or File(video.path)
            isVideo: false, // or true if it's video
            currentUserId: 'yourUserIdHere', // 🔁 Replace dynamically
            image: File(media.path), // Optional preview
            receiverId: widget.receiverId, // Pass receiver ID
            receiverName: widget.receiverName, // Pass receiver name
            chatId: widget.chatId, // Pass chat ID
            profileUrl: widget.profileUrl, // Pass profile URL
          ),
        ),
      );
    } catch (e) {
      print("Error picking media: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final size = MediaQuery.of(context).size;
            final scale =
                1 / (_controller.value.aspectRatio * size.aspectRatio);

            return Stack(
              children: [
                // ✅ Full screen camera with correct aspect ratio
                Transform.scale(
                  scale: scale,
                  alignment: Alignment.center,
                  child: Center(
                    child: CameraPreview(_controller),
                  ),
                ),

                // ✅ Top bar
                Positioned(
                  top: 40,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 28),
                      ),
                      if (_isVideoMode)
                        Center(
                          child: Text(
                            _formatTime(_recordingSeconds),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      IconButton(
                        onPressed: _toggleFlash,
                        icon: Icon(
                          _isFlashOn ? Icons.flash_on : Icons.flash_off,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),

                // ✅ Bottom controls
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _modeButton("Video", _isVideoMode),
                          const SizedBox(width: 10),
                          _modeButton("Photo", !_isVideoMode),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.image,
                                color: Colors.white, size: 30),
                            onPressed: _loadGalleryMedia,
                          ),
                          GestureDetector(
                            onTap: _isVideoMode
                                ? (_isRecording
                                    ? _stopVideoRecording
                                    : _startVideoRecording)
                                : _takePicture,
                            child: Container(
                              width: 78,
                              height: 78,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black,
                                border:
                                    Border.all(color: Colors.white, width: 3.5),
                              ),
                              child: Center(
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _isRecording
                                        ? Colors.red
                                        : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.cameraswitch,
                                color: Colors.white, size: 30),
                            onPressed: _switchCamera,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return const Center(
                child: CircularProgressIndicator(color: Colors.white));
          }
        },
      ),
    );
  }

  Widget _modeButton(String label, bool selected) {
    return GestureDetector(
      onTap: () => _switchMode(label == "Video"),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
