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
    this.onOmr,
    this.showHelp = true,
  });
  final bool editor, signedIn;
  final bool showHelp;
  final Map<String, dynamic> data;
  final ValueChanged<String> command;
  final VoidCallback? onOmr;
  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    final editable = data['editable'] == true;
    final actions = <Widget>[
      if (editor &&
          (data['canWrite'] == true || editable) &&
          data['practiceDraft'] != true) ...[
        _action(
          Icons.add,
          'add-section',
          socialText(context, 'افزودن بخش', 'Add section'),
          true,
        ),
        _action(
          Icons.post_add,
          'add-part',
          socialText(context, 'افزودن پارت', 'Add part'),
          true,
        ),
      ],
      if (editor && editable) ...[
        _action(
          Icons.multitrack_audio,
          'tool-voices',
          socialText(context, 'صداها', 'Voices'),
          true,
        ),
        _action(
          Icons.view_week_outlined,
          'tool-measure',
          socialText(context, 'ابزار میزان', 'Measure tools'),
          true,
        ),
        _action(
          Icons.music_note_outlined,
          'tool-palette',
          socialText(context, 'ابزار نت', 'Notation tools'),
          true,
        ),
        _action(
          Icons.save_outlined,
          'save',
          data['practiceDraft'] == true
              ? socialText(context, 'ثبت در سؤال', 'Use in question')
              : socialText(context, 'ذخیره', 'Save'),
          true,
        ),
      ],
      if (editor && data['overview'] == true && data['canWrite'] == true)
        _action(
          Icons.save_outlined,
          'save',
          socialText(context, 'ذخیره', 'Save'),
          true,
        ),
      if (editor)
        _action(
          Icons.print_outlined,
          'print-preview',
          socialText(context, 'پیش‌نمایش چاپ / PDF', 'Print preview / PDF'),
          true,
        ),
      if (editor)
        _action(
          data['playing'] == true ? Icons.pause : Icons.play_arrow,
          'play',
          socialText(context, 'پخش / مکث', 'Play / pause'),
          true,
        ),
      if (editor && editable)
        _action(
          Icons.edit_outlined,
          'metadata',
          socialText(context, 'ویرایش', 'Edit'),
          true,
        ),
    ];
    return TooltipVisibility(
      visible: showHelp,
      child: AppTopBarDirection(
        child: AppBar(
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          title: editor
              ? Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: 40,
                        child: BackButton(onPressed: () => command('back')),
                      ),
                      Flexible(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 4,
                            children: actions,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Text(socialText(context, 'نت نویسی', 'Notation')),
          leading: editor ? null : BackButton(onPressed: () => command('back')),
        ),
      ),
    );
  }

  Widget _action(IconData icon, String name, String tooltip, bool enabled) =>
      SizedBox(
        width: 32,
        child: IconButton(
          constraints: const BoxConstraints.tightFor(width: 32, height: 40),
          padding: EdgeInsets.zero,
          tooltip: tooltip,
          onPressed: enabled ? () => command(name) : null,
          icon: Icon(icon, size: 22),
        ),
      );
}
