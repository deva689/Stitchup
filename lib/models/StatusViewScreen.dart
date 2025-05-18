// File: status_view_screen.dart
import 'package:flutter/material.dart';

class StatusViewScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(userName),
        leading: CircleAvatar(
          backgroundImage: NetworkImage(profileImage),
        ),
      ),
      body: PageView.builder(
        itemCount: statusList.length,
        itemBuilder: (context, index) {
          final status = statusList[index];
          return Center(
            child: Image.network(status['url']), // Adjust for video if needed
          );
        },
      ),
    );
  }
}
