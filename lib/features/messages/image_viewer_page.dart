import 'package:flutter/material.dart';

class ChatImageViewerPage extends StatelessWidget {
  const ChatImageViewerPage({super.key, required this.imageUrl});
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}
