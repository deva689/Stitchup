// lib/utils/time_formatter.dart
import 'package:intl/intl.dart';

String formatViewedTime(DateTime viewedAt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final viewedDate = DateTime(viewedAt.year, viewedAt.month, viewedAt.day);

  if (viewedDate == today) {
    return DateFormat('h:mm a').format(viewedAt); // Today
  } else if (viewedDate == yesterday) {
    return 'Yesterday, ${DateFormat('h:mm a').format(viewedAt)}';
  } else {
    return ''; // Outside 24 hours — shouldn't happen with stories
  }
}
