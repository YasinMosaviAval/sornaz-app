import 'package:flutter/material.dart';

class BrowserNotationHost extends StatelessWidget {
  const BrowserNotationHost({
    super.key,
    required this.token,
    required this.userId,
    this.initialDraft,
    this.onDraftSaved,
  });
  final String token;
  final int userId;
  final Map<String, dynamic>? initialDraft;
  final ValueChanged<Map<String, dynamic>?>? onDraftSaved;
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
