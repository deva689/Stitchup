import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Map<String, dynamic> buildStatusData({
  required String url,
  required String caption,
  required Color selectedColor,
  required String selectedFont,
  required TextAlign textAlign,
  required bool highlightMode,
  required Color highlightColor,
}) {
  return {
    "type": "image",
    "url": url,
    "caption": caption,
    "textStyle": {
      "color": selectedColor.value,
      "fontFamily": selectedFont,
      "textAlign": textAlign.index,
      "highlightMode": highlightMode,
      "highlightColor": highlightColor.value,
    },
    "time": Timestamp.now(),
    "duration": 30,
  };
}
