import 'package:sornaz/components/app_top_bar_direction.dart';
import 'package:flutter/material.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';

class NotationTopBar extends StatelessWidget implements PreferredSizeWidget {
  const NotationTopBar({
    super.key,
    required this.editor,
    required this.signedIn,
    required this.data,
    required this.command,
  });
  final bool editor, signedIn;
  final Map<String, dynamic> data;
  final ValueChanged<String> command;
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) => AppTopBarDirection(
    child: AppBar(
      title: Text(
        socialText(context, 'نت نویسی', 'Notation'),
        style: const TextStyle(fontSize: 18),
      ),
      leading: BackButton(onPressed: () => command('back')),
      titleSpacing: 0,
      actions: !editor
          ? null
          : [
              if (data['editable'] == true)
                IconButton(
                  tooltip: socialText(context, 'ذخیره', 'Save'),
                  onPressed: () => command('save'),
                  icon: const Icon(Icons.save_outlined),
                ),
              IconButton(
                tooltip: socialText(context, 'پخش / مکث', 'Play / pause'),
                onPressed: () => command('play'),
                icon: Icon(
                  data['playing'] == true ? Icons.pause : Icons.play_arrow,
                ),
              ),
              if (data['editable'] == true)
                IconButton(
                  tooltip: socialText(context, 'ویرایش', 'Edit'),
                  onPressed: () => command('metadata'),
                  icon: const Icon(Icons.edit_outlined),
                ),
            ],
    ),
  );
}
