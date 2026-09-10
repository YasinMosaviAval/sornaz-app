import 'package:flutter/material.dart';
class BrowserNotationHost extends StatelessWidget {
  const BrowserNotationHost({super.key, required this.token, required this.userId});
  final String token;
  final int userId;
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
