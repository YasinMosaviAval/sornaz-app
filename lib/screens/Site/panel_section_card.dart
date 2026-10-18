import 'package:flutter/material.dart';
import '../../helpers/app_appearance.dart';

/// Shared, initially open panel section. Hidden children retain form state.
class PanelSectionCard extends StatefulWidget {
  const PanelSectionCard({
    super.key,
    required this.title,
    required this.children,
    this.icon = Icons.filter_alt_outlined,
    this.color,
    this.horizontalInset = 12,
    this.storageId,
  });

  final String title;
  final List<Widget> children;
  final IconData icon;
  final Color? color;
  final double horizontalInset;
  final String? storageId;

  @override
  State<PanelSectionCard> createState() => _PanelSectionCardState();
}

class _PanelSectionCardState extends State<PanelSectionCard>
    with AutomaticKeepAliveClientMixin {
  final controller = ExpansibleController();
  @override
  bool get wantKeepAlive => true;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final shape = RoundedRectangleBorder(borderRadius: appRadius(context));
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: widget.horizontalInset,
        vertical: 4,
      ),
      color: widget.color,
      surfaceTintColor: Colors.transparent,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () =>
            controller.isExpanded ? controller.collapse() : controller.expand(),
        child: SizedBox(
          width: double.infinity,
          child: ExpansionTile(
            key: PageStorageKey(widget.storageId ?? widget.title),
            controller: controller,
            initiallyExpanded: true,
            maintainState: true,
            shape: shape,
            collapsedShape: shape,
            leading: Icon(widget.icon),
            title: Text(
              widget.title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            children: widget.children,
          ),
        ),
      ),
    );
  }
}
