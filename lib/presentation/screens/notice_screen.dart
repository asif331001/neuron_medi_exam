import 'package:flutter/material.dart';

class NoticeScreen extends StatelessWidget {
  const NoticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: const Center(
        child: Text(
          'Notice Screen',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}