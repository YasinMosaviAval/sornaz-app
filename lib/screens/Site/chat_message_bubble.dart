import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Social/social_api.dart';
import '../Social/social_widgets.dart';

String messageDay(Json message) {
  final text = '${message['createdAt'] ?? ''}';
  return RegExp(r'^\d{4}-\d{2}-\d{2}').stringMatch(text) ??
      text.split(' ').first;
}

String messageTime(Json message) =>
    RegExp(
      r'[T ](\d{2}:\d{2})',
    ).firstMatch('${message['createdAt'] ?? ''}')?.group(1) ??
    '';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.actions,
    required this.onAction,
    this.attachment,
    this.busy = false,
  });
  final Json message, actions;
  final ValueChanged<String> onAction;
  final Widget? attachment;
  final bool busy;
  @override
  Widget build(BuildContext context) {
    final mine = message['mine'] == true;
    final colors = Theme.of(context).colorScheme;
    Widget button(String action, IconData icon, String fa, String en) =>
        SizedBox(
          width: 26,
          height: 32,
          child: IconButton(
            tooltip: socialText(context, fa, en),
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 26, height: 32),
            padding: EdgeInsets.zero,
            icon: Icon(
              icon,
              size: 18,
              color: action == 'like' && message['liked'] == true
                  ? colors.primary
                  : null,
            ),
            onPressed: busy ? null : () => onAction(action),
          ),
        );
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .82,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment:
                (Directionality.of(context) == TextDirection.rtl) == mine
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            children: [
              if (!mine)
                Text(
                  '${message['sender'] ?? ''}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              if ('${message['body'] ?? ''}'.isNotEmpty)
                Container(
                  key: ValueKey('message-body-${message['id']}'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: mine
                        ? colors.primaryContainer
                        : colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${message['body']}',
                    style: TextStyle(
                      color: mine
                          ? colors.onPrimaryContainer
                          : colors.onSurface,
                    ),
                  ),
                ),
              if (attachment != null) attachment!,
              Wrap(
                textDirection: mine ? TextDirection.rtl : TextDirection.ltr,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 0,
                children: [
                  if (actions.containsKey('like'))
                    button(
                      'like',
                      message['liked'] == true
                          ? Icons.favorite
                          : Icons.favorite_border,
                      'پسندیدن پیام',
                      'Like message',
                    ),
                  if (number(message['likes']) > 0)
                    Text(
                      '${message['likes']}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  if (mine && actions.containsKey('edit-message'))
                    button(
                      'edit-message',
                      Icons.edit_outlined,
                      'ویرایش پیام',
                      'Edit message',
                    ),
                  SizedBox(
                    width: 26,
                    height: 32,
                    child: IconButton(
                      tooltip: socialText(context, 'کپی پیام', 'Copy message'),
                      icon: const Icon(Icons.copy, size: 18),
                      constraints: const BoxConstraints.tightFor(
                        width: 26,
                        height: 32,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: () => Clipboard.setData(
                        ClipboardData(text: '${message['body'] ?? ''}'),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 26,
                    height: 32,
                    child: PopupMenuButton<String>(
                      enabled: !busy,
                      tooltip: socialText(
                        context,
                        'گزینه‌های پیام',
                        'Message options',
                      ),
                      icon: const Icon(Icons.more_vert, size: 18),
                      padding: EdgeInsets.zero,
                      onSelected: onAction,
                      itemBuilder: (_) => [
                        if (actions.containsKey('forward'))
                          PopupMenuItem(
                            value: 'forward',
                            child: Text(
                              socialText(
                                context,
                                'ارسال در چت دیگر',
                                'Forward to another chat',
                              ),
                            ),
                          ),
                        if (actions.containsKey('delete-message'))
                          PopupMenuItem(
                            value: 'delete-message',
                            enabled: mine,
                            child: Text(
                              socialText(
                                context,
                                'پاک کردن پیام',
                                'Delete message',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      messageTime(message),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                  if (message['edited'] == true)
                    Text(
                      socialText(context, 'ویرایش‌شده', 'Edited'),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
