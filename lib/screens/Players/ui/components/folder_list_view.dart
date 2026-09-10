import 'package:flutter/material.dart';
import 'flat_list_view.dart';
class FolderView extends StatelessWidget {
  const FolderView({super.key});
  @override
  Widget build(BuildContext context) => const FlatListView(folders: true);
}
