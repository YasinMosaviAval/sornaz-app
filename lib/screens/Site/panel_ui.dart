import 'package:flutter/material.dart';
import 'package:sornaz/components/app_dialog.dart';
import '../../components/scroll_aware_scaffold.dart';
import '../Social/social_widgets.dart';
import 'branch_style.dart';

/// The compact visual language shared by all authenticated panel pages.
class PanelScaffold extends StatelessWidget {
  const PanelScaffold({
    super.key,
    this.appBar,
    this.body,
    this.embedded = false,
  });
  final bool embedded;
  final PreferredSizeWidget? appBar;
  final Widget? body;
  @override
  Widget build(BuildContext context) => Theme(
    data: branchTheme(context),
    child: embedded
        ? body ?? const SizedBox.shrink()
        : ScrollAwareScaffold(appBar: appBar, body: body),
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
}) async {
  if (delete)
    return showDeleteConfirmation(context, title: title, message: message);
  return await showDialog<bool>(
        context: context,
        builder: (c) => AppDialog(
          title: Text(title),
          content: message == null ? null : Text(message),
          actions: [
            AppDialogAction(
              role: AppDialogActionRole.cancel,
              onPressed: () => Navigator.pop(c, false),
              child: Text(socialText(c, 'انصراف', 'Cancel')),
            ),
            AppDialogAction(
              onPressed: () => Navigator.pop(c, true),
              child: Text(socialText(c, 'تأیید', 'Confirm')),
            ),
          ],
        ),
      ) ??
      false;
}

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
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  fit: FlexFit.tight,
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.bodyMedium,
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
