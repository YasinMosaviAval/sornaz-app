import 'package:flutter/material.dart';
import '../../components/scroll_aware_scaffold.dart';
import '../Social/social_widgets.dart';
import 'branch_style.dart';

/// The compact visual language shared by all authenticated panel pages.
class PanelScaffold extends StatelessWidget {
  const PanelScaffold({super.key, this.appBar, this.body});
  final PreferredSizeWidget? appBar;
  final Widget? body;
  @override
  Widget build(BuildContext context) => Theme(
    data: branchTheme(context),
    child: ScrollAwareScaffold(appBar: appBar, body: body),
  );
}

class PanelModal extends StatelessWidget {
  const PanelModal({
    super.key,
    required this.title,
    required this.child,
    this.busy = false,
  });
  final String title;
  final Widget child;
  final bool busy;
  @override
  Widget build(BuildContext context) => Theme(
    data: branchTheme(context),
    child: BranchDialog(title: title, busy: busy, child: child),
  );
}

Future<bool> showPanelConfirmation(
  BuildContext context,
  String title, {
  String? message,
  bool delete = false,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => Theme(
        data: branchTheme(context),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          title: Text(title, style: const TextStyle(fontSize: 14)),
          content: message == null ? null : Text(message),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
              onPressed: () => Navigator.pop(c, false),
              child: Text(socialText(c, 'انصراف', 'Cancel')),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: delete ? Colors.red : branchIndigo,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              onPressed: () => Navigator.pop(c, true),
              child: Text(
                delete
                    ? socialText(c, 'حذف', 'Delete')
                    : socialText(c, 'تأیید', 'Confirm'),
              ),
            ),
          ],
        ),
      ),
    ) ??
    false;

class PanelValueRow extends StatelessWidget {
  const PanelValueRow({
    super.key,
    required this.title,
    required this.value,
    required this.onTap,
  });
  final String title, value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(title, style: const TextStyle(fontSize: 13)),
                ),
                const SizedBox(width: 12),
                Flexible(
                  fit: FlexFit.tight,
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: .2, thickness: .2, color: Color(0xffeeeeee)),
      ],
    ),
  );
}
