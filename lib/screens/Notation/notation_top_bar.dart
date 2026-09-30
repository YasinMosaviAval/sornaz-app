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
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    final editable = data['editable'] == true;
    final selected = (data['selectedNotes'] as num?)?.toInt() ?? 0;
    final disabledColor = Theme.of(context).disabledColor;
    final actions = <Widget>[
      if (editor && editable) ...[
        _action(
          Icons.undo,
          'undo',
          socialText(context, 'واگرد', 'Undo'),
          data['undo'] == true,
        ),
        _action(
          Icons.redo,
          'redo',
          socialText(context, 'ازنو', 'Redo'),
          data['redo'] == true,
        ),
        SizedBox(
          width: 32,
          child: IconButton(
            constraints: const BoxConstraints.tightFor(width: 32, height: 40),
            padding: EdgeInsets.zero,
            tooltip: socialText(context, 'حذف با سکوت', 'Delete with rest'),
            onPressed: selected > 0 ? () => command('delete-note-rest') : null,
            icon: _TrashIcon(
              twoLines: false,
              color: selected > 0 ? Colors.red : disabledColor,
            ),
          ),
        ),
        SizedBox(
          width: 32,
          child: IconButton(
            constraints: const BoxConstraints.tightFor(width: 32, height: 40),
            padding: EdgeInsets.zero,
            tooltip: socialText(
              context,
              'حذف بدون سکوت',
              'Delete without rest',
            ),
            onPressed: selected > 0
                ? () => command('delete-note-compact')
                : null,
            icon: _TrashIcon(
              twoLines: true,
              color: selected > 0 ? Colors.red : disabledColor,
            ),
          ),
        ),
        _action(
          Icons.save_outlined,
          'save',
          socialText(context, 'ذخیره', 'Save'),
          true,
        ),
      ],
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
    return AppTopBarDirection(
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
                    ...actions,
                  ],
                ),
              )
            : Text(socialText(context, 'نت نویسی', 'Notation')),
        leading: editor ? null : BackButton(onPressed: () => command('back')),
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

class _TrashIcon extends StatelessWidget {
  const _TrashIcon({required this.twoLines, required this.color});
  final bool twoLines;
  final Color color;
  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size(22, 22),
    painter: _TrashPainter(twoLines, color),
  );
}

class _TrashPainter extends CustomPainter {
  const _TrashPainter(this.twoLines, this.color);
  final bool twoLines;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final scale = size.width / 24;
    canvas.save();
    canvas.scale(scale);
    canvas.drawPath(
      Path()
        ..moveTo(3, 6)
        ..lineTo(21, 6)
        ..moveTo(9, 6)
        ..lineTo(9, 3)
        ..lineTo(15, 3)
        ..lineTo(15, 6)
        ..moveTo(5, 6)
        ..lineTo(6, 21)
        ..lineTo(18, 21)
        ..lineTo(19, 6),
      paint,
    );
    if (twoLines) {
      canvas.drawLine(const Offset(10, 10), const Offset(10, 17), paint);
      canvas.drawLine(const Offset(14, 10), const Offset(14, 17), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TrashPainter old) =>
      old.twoLines != twoLines || old.color != color;
}
