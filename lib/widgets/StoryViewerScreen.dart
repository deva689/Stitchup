import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitchup/utils/time_formatter.dart';
import 'package:video_player/video_player.dart';

class StatusViewScreen extends StatefulWidget {
  final List<Map<String, dynamic>> statusList;
  final String userName;
  final String profileImage;

  const StatusViewScreen({
    super.key,
    required this.statusList,
    required this.userName,
    required this.profileImage,
  });

  @override
  State<StatusViewScreen> createState() => _StatusViewScreenState();
}

class _StatusViewScreenState extends State<StatusViewScreen> {
  late PageController _pageController;
  VideoPlayerController? _videoController;
  int _currentIndex = 0;
  double _progress = 0.0;
  Timer? _timer;
  bool _isPaused = false;
  Duration _currentDuration = Duration.zero;
  Duration _progressDuration = Duration.zero;
  String profileImageUrl = '';
  File? localPreviewFile;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    profileImageUrl = widget.profileImage; // Use this first

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMedia(0);
      SharedPreferences.getInstance().then((prefs) {
        final cachedUrl = prefs.getString('cached_profile_url');
        if (cachedUrl != null && cachedUrl.isNotEmpty) {
          setState(() {
            profileImageUrl = cachedUrl;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _loadMedia(int index) async {
    _timer?.cancel();
    _videoController?.dispose();

    setState(() {
      _progress = 0;
      _currentIndex = index;
      _isPaused = false;
    });

    final status = widget.statusList[index];
    final isVideo = status['isVideo'] == true;

    if (isVideo) {
      _videoController = VideoPlayerController.network(status['url']);
      await _videoController!.initialize();
      final videoDuration = _videoController!.value.duration;
      _currentDuration = videoDuration.inSeconds > 30
          ? const Duration(seconds: 30)
          : videoDuration;

      _videoController!.play();
      _videoController!.setLooping(false);
    } else {
      _currentDuration = const Duration(seconds: 10);
    }

    _startProgressTimer();
  }

  void _startProgressTimer() {
    _progressDuration = Duration.zero;
    const tickRate = Duration(milliseconds: 50);

    _timer = Timer.periodic(tickRate, (timer) {
      if (_isPaused) return;

      _progressDuration += tickRate;
      double newProgress =
          _progressDuration.inMilliseconds / _currentDuration.inMilliseconds;

      if (newProgress >= 1.0) {
        timer.cancel();
        if (_currentIndex < widget.statusList.length - 1) {
          _pageController.nextPage(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeIn);
        } else {
          Navigator.of(context).pop();
        }
      }

      setState(() {
        _progress = newProgress.clamp(0.0, 1.0);
      });
    });
  }

  void _pauseStatus() {
    setState(() => _isPaused = true);
    _videoController?.pause();
  }

  void _resumeStatus() {
    setState(() => _isPaused = false);
    _videoController?.play();
  }

  String timeAgo(DateTime timestamp) {
    final duration = DateTime.now().difference(timestamp);
    if (duration.inMinutes < 1) return 'Just now';
    if (duration.inMinutes < 60) return '${duration.inMinutes} minutes ago';
    if (duration.inHours < 24) return '${duration.inHours} hours ago';
    return '${duration.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.statusList[_currentIndex];
    final caption = status['caption'] ?? '';
    final timestamp = status['timestamp'] as DateTime?;
    final views = status['views'] ?? [];
    final isVideo = status['isVideo'] == true;

    ImageProvider imageProvider;

    try {
      if (localPreviewFile != null) {
        imageProvider = FileImage(localPreviewFile!);
      } else if (profileImageUrl.isNotEmpty) {
        imageProvider = CachedNetworkImageProvider(profileImageUrl);
      } else {
        imageProvider = const AssetImage('assets/default_avatar.png');
      }
    } catch (e) {
      print('⚠️ Error loading image: $e');
      imageProvider = const AssetImage('assets/default_avatar.png');
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          Navigator.of(context).pop(); // Exit on tap
        },
        onLongPressStart: (_) => _pauseStatus(),
        onLongPressEnd: (_) => _resumeStatus(),
        onTapDown: (_) => _pauseStatus(),
        onTapUp: (_) => _resumeStatus(),
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              physics:
                  const NeverScrollableScrollPhysics(), // Prevent manual swipe
              itemCount: widget.statusList.length,
              itemBuilder: (context, index) {
                final item = widget.statusList[index];
                final isVideo = item['isVideo'] == true;

                return Center(
                  child: isVideo
                      ? (_videoController != null &&
                              _videoController!.value.isInitialized)
                          ? AspectRatio(
                              aspectRatio: _videoController!.value.aspectRatio,
                              child: VideoPlayer(_videoController!),
                            )
                          : const CircularProgressIndicator()
                      : Image.network(
                          item['url'],
                          fit: BoxFit.contain,
                        ),
                );
              },
            ),

            // Progress bar
            Positioned(
              top: 52,
              left: 0,
              right: 0,
              height: 2,
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),

            // User info
            Positioned(
              top: 58,
              left: 0,
              right: 11,
              child: Row(
                children: [
                  const BackButton(color: Colors.white),
                  CircleAvatar(
                    backgroundImage: imageProvider,
                    backgroundColor: Colors.grey[300],
                  ),
                  const SizedBox(width: 11),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "My status",
                        style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                      if (timestamp != null)
                        Text(
                          timeAgo(timestamp),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.more_vert, color: Colors.white),
                ],
              ),
            ),

            // Caption
            if (caption.isNotEmpty)
              Positioned(
                bottom: 90,
                left: 16,
                right: 16,
                child: Text(
                  caption,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    shadows: [Shadow(blurRadius: 5, color: Colors.black)],
                  ),
                ),
              ),

            Positioned(
              bottom: 38,
              left: 4,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      backgroundColor: Colors.white,
                      builder: (_) => ViewedBySheet(
                        views: views.cast<Map<String, dynamic>>(), // ✅ Fix here
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.remove_red_eye_outlined,
                          size: 24, color: Colors.white),
                      const SizedBox(width: 2),
                      Text(
                        '${views.length}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ViewedBySheet extends StatelessWidget {
  final List<Map<String, dynamic>> views;

  const ViewedBySheet({required this.views, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100, // Light grey header background
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Viewed by ${views.length}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const Icon(Icons.more_vert, size: 22, color: Colors.black54),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Viewer list or empty message
          Expanded(
            child: views.isEmpty
                ? const Center(
                    child: Text(
                      'No views yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: views.length,
                    itemBuilder: (context, index) {
                      final view = views[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage: view['profileUrl'] != null
                                ? NetworkImage(view['profileUrl'])
                                : null,
                            child: view['profileUrl'] == null
                                ? const Icon(Icons.person,
                                    size: 26, color: Colors.white70)
                                : null,
                          ),
                          title: Text(
                            view['name'] ?? 'Unknown',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                          subtitle: Text(
                            formatViewedTime(view['viewedAt']),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          trailing: const Icon(Icons.more_vert,
                              size: 20, color: Colors.grey),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
