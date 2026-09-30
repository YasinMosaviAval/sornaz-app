import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_data.dart';
import '../Social/social_api.dart';

Color branchAccent(BuildContext context) =>
    Theme.of(context).colorScheme.primary;
Color branchSecondary(BuildContext context) =>
    Theme.of(context).colorScheme.onSurfaceVariant;
Color branchDivider(BuildContext context) => Theme.of(context).dividerColor;
Color branchCanvas(BuildContext context) =>
    Theme.of(context).scaffoldBackgroundColor;
Color branchHighlight(BuildContext context) =>
    Theme.of(context).colorScheme.primaryContainer;
bool branchFlag(dynamic value) => value == true || value == 1 || value == '1';
String branchStatusCode(Json row) => switch ('${row['status']}') {
  'فعال' || 'approved' || 'active' => 'active',
  'حذف‌شده' || 'removed' => 'removed',
  _ => 'inactive',
};
String branchStatus(Json row, bool fa) => switch (branchStatusCode(row)) {
  'active' => fa ? 'فعال' : 'Active',
  'removed' => fa ? 'حذف‌شده' : 'Removed',
  _ => fa ? 'غیرفعال' : 'Inactive',
};
String branchMode(dynamic value, bool fa) => switch (value) {
  'online' => fa ? 'آنلاین' : 'Online',
  'hybrid' => fa ? 'هیبرید' : 'Hybrid',
  _ => fa ? 'فیزیکی' : 'Physical',
};
BorderRadius branchRadius(BuildContext context) =>
    BorderRadius.circular(context.watch<AppData>().cornerRadius);

ThemeData branchTheme(BuildContext context) {
  return Theme.of(context);
}

class BranchSurface extends StatelessWidget {
  const BranchSurface({
    super.key,
    required this.child,
    this.color,
    this.border,
    this.padding = 24,
  });
  final Widget child;
  final Color? color, border;
  final double padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: color ?? Theme.of(context).colorScheme.surface,
      borderRadius: branchRadius(context),
      border: Border.all(color: border ?? branchDivider(context)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x08000000),
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Material(type: MaterialType.transparency, child: child),
  );
}

class BranchDialog extends StatelessWidget {
  const BranchDialog({
    super.key,
    required this.title,
    required this.child,
    this.main = false,
    this.busy = false,
  });
  final String title;
  final Widget child;
  final bool main, busy;
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: main
          ? branchHighlight(context)
          : Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: branchRadius(context),
        side: BorderSide(
          color: main ? const Color(0xfffcd34d) : Colors.transparent,
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 768,
          maxHeight: MediaQuery.sizeOf(context).height * .85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(24, 12, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: busy ? null : () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: branchSecondary(context)),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: branchDivider(context)),
            if (busy) const LinearProgressIndicator(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: child,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
