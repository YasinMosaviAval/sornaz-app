import 'package:flutter/material.dart';
import '../Social/social_api.dart';
import '../Social/social_widgets.dart';
import 'panel_api.dart';
import 'panel_form.dart';
import 'chat_cache.dart';
import '../Social/media_picker.dart';
import 'package:sornaz/components/media_dialogs.dart';

Future<bool> conversationMenu(
  BuildContext context,
  PanelApi api,
  Json section,
  Json conversation,
) async {
  try {
    final id = '${conversation['id']}';
    final details = await api.get('/chat/details', {'id': id});
    if (!context.mounted) return false;
    final actions = optionalObject(section['actions']);
    final allowed = [
      if (details['type'] == 'group') ...[
        if (details['canManage'] == true) ...['rename', 'avatar', 'members'],
        if (details['canLeave'] != false) 'leave',
      ],
      if (details['canDelete'] == true) 'delete',
    ].where(actions.containsKey).toList();
    final key = await showModalBottomSheet<String>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final key in allowed)
              ListTile(
                leading: Icon(switch (key) {
                  'rename' => Icons.edit_outlined,
                  'avatar' => Icons.image_outlined,
                  'members' => Icons.person_add_alt,
                  'leave' => Icons.logout,
                  _ => Icons.delete_outline,
                }),
                title: Text('${actions[key]['label']}'),
                onTap: () => Navigator.pop(c, key),
              ),
          ],
        ),
      ),
    );
    if (key == null || !context.mounted) return false;
    final definition = optionalObject(actions[key]);
    final fields = objects(definition['fields'] ?? []);
    PanelFormResult? result;
    if (key == 'avatar') {
      final file = await pickGalleryMedia(
        context,
        imagesOnly: true,
        crop: true,
      );
      if (file == null) return false;
      result = PanelFormResult({}, {'file': file});
    } else if (key == 'rename') {
      final name = await renameMediaDialog(
        context,
        '${details['title'] ?? ''}',
      );
      if (name == null) return false;
      result = PanelFormResult({'title': name}, {});
    } else if (fields.isNotEmpty) {
      final available = details['availableUsers'] ?? [];
      result = await Navigator.push<PanelFormResult>(
        context,
        MaterialPageRoute(
          builder: (_) => PanelFormPage(
            title: '${definition['label']}',
            fields: fields,
            data: {'users': available, 'people': available},
            initial: key == 'rename' ? {'title': details['title']} : const {},
          ),
        ),
      );
      if (result == null) return false;
    } else {
      final yes = await confirmMediaDelete(context, '${definition['label']}؟');
      if (yes != true) return false;
    }
    await api.act(
      'chat',
      key,
      params: {'id': id},
      values: result?.values ?? {},
      files: result?.files ?? {},
    );
    if (key == 'delete' || key == 'leave') {
      await ChatCache.remove(api.token, 'conversation:$id');
      final saved = await ChatCache.read(api.token, '/conversations');
      if (saved is List)
        await ChatCache.write(
          api.token,
          '/conversations',
          objects(saved).where((r) => '${r['id']}' != id).toList(),
        );
    }
    return true;
  } catch (e) {
    if (context.mounted) socialError(context, e);
    return false;
  }
}
