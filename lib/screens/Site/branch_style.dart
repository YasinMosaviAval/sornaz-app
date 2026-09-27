import 'package:flutter/material.dart';
import '../Social/social_api.dart';

// Colors and spacing from the mobile Analytics branch templates.
const branchIndigo = Color(0xff4f46e5);
const branchMuted = Color(0xff6b7280);
const branchBorder = Color(0xffe5e7eb);
const branchBackground = Color(0xfff9fafb);
const branchAmber = Color(0xfffffbeb);
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
ThemeData branchTheme(BuildContext context) {
  final base = Theme.of(context);
  return base.copyWith(
    colorScheme: const ColorScheme.light(
      primary: branchIndigo,
      surface: Colors.white,
      onSurface: Color(0xff111827),
    ),
    scaffoldBackgroundColor: branchBackground,
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: branchBorder),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xffeeeeee),
      thickness: .2,
    ),
    dialogTheme: DialogThemeData(
      titleTextStyle: const TextStyle(fontSize: 14, color: Color(0xff111827)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    textTheme: base.textTheme.apply(
      fontFamily: 'vazir_fa',
      fontFamilyFallback: const ['vazir_en'],
      bodyColor: const Color(0xff111827),
      displayColor: const Color(0xff111827),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xffd1d5db)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xffd1d5db)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: branchIndigo),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: branchIndigo,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: branchIndigo,
        side: const BorderSide(color: branchBorder),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    ),
  );
}

class BranchSurface extends StatelessWidget {
  const BranchSurface({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.border = branchBorder,
    this.padding = 24,
  });
  final Widget child;
  final Color color, border;
  final double padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: border),
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
      backgroundColor: main ? branchAmber : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
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
                    icon: const Icon(Icons.close, color: branchMuted),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: branchBorder),
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
