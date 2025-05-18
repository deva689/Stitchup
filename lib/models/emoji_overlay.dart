import 'package:flutter/material.dart';

class EmojiOverlayStateful extends StatefulWidget {
  final String emoji;
  final Offset initialPosition;
  final VoidCallback onDelete;
  final VoidCallback onDragStart;
  final VoidCallback onDragEnd;

  const EmojiOverlayStateful({
    super.key,
    required this.emoji,
    required this.initialPosition,
    required this.onDelete,
    required this.onDragStart,
    required this.onDragEnd,
  });

  @override
  State<EmojiOverlayStateful> createState() => _EmojiOverlayStatefulState();
}

class _EmojiOverlayStatefulState extends State<EmojiOverlayStateful> {
  late Offset position;
  double scale = 1.0;
  double baseScale = 1.0;
  Offset? initialFocalPoint;
  bool isDragging = false; // ✅ added

  @override
  void initState() {
    super.initState();
    position = widget.initialPosition;
  }

  bool _isOverDeleteArea(Offset pos) {
    return pos.dx < 120 && pos.dy < 180; // 🔥 Delete area boundary
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onScaleStart: (details) {
          baseScale = scale;
          initialFocalPoint = details.focalPoint;
          isDragging = true;
          widget.onDragStart(); // 👉 Inform parent dragging started
        },
        onScaleUpdate: (details) {
          setState(() {
            scale = (baseScale * details.scale).clamp(0.5, 6.0);

            if (details.scale == 1.0 && initialFocalPoint != null) {
              position += details.focalPoint - initialFocalPoint!;
              initialFocalPoint = details.focalPoint;
            }
          });
        },
        onScaleEnd: (details) {
          setState(() {
            isDragging = false; // ✅ added missing
          });

          if (_isOverDeleteArea(position)) {
            widget.onDelete(); // 👉 If over delete, remove emoji
          }

          widget.onDragEnd(); // 👉 Inform parent dragging ended
        },
        child: Transform.scale(
          scale: scale,
          child: Text(
            widget.emoji,
            style: const TextStyle(
              fontSize: 80,
            ),
          ),
        ),
      ),
    );
  }
}
