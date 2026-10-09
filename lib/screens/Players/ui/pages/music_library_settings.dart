import 'package:flutter/material.dart';
import 'package:sornaz/components/app_bar.dart';
import '../../services/player_settings.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';

class MusicLibrarySettings extends StatelessWidget {
  const MusicLibrarySettings({
    super.key,
    required this.mode,
    this.video = false,
    this.videoNames = const {},
  });
  final String mode;
  final bool video;
  final Map<String, String> videoNames;
  @override
  Widget build(BuildContext context) {
    final settings = PlayerSettings.instance;
    final names = video
        ? ['Videos', 'Folders', 'Playlists']
        : ['Songs', 'Folders', 'Playlists', 'Equalizer'];
    final fa = video
        ? ['ویدیوها', 'پوشه‌ها', 'لیست پخش‌ها']
        : ['آهنگ‌ها', 'پوشه‌ها', 'لیست پخش‌ها', 'اکولایزر'];
    List<String> order() => video ? settings.videoTabOrder : settings.tabOrder;
    List<String> tabsHidden() =>
        video ? settings.videoHiddenTabs : settings.hiddenTabs;
    final orderKey = video ? 'videoTabOrder' : 'tabOrder';
    final hiddenKey = video ? 'videoHiddenTabs' : 'hiddenTabs';
    return ListenableBuilder(
      listenable: settings,
      builder: (c, _) => Scaffold(
        appBar: SornazAppBar(
          title: mode == 'sort'
              ? socialText(c, 'مرتب‌سازی تب‌ها', 'Sort Tabs')
              : mode == 'hide'
              ? socialText(c, 'مخفی کردن تب‌ها', 'Hide Tabs')
              : socialText(
                  c,
                  'فایل‌ها و پوشه‌های مخفی',
                  'Hidden Files and Folders',
                ),
        ),
        body: mode == 'sort'
            ? Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      socialText(
                        c,
                        'تب را نگه دارید و به چپ یا راست بکشید.',
                        'Hold a tab and drag it left or right.',
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 80,
                    child: ReorderableListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      scrollDirection: Axis.horizontal,
                      buildDefaultDragHandles: false,
                      onReorderItem: (old, next) {
                        final nextOrder = [...order()];
                        nextOrder.insert(next, nextOrder.removeAt(old));
                        settings.setOption(orderKey, nextOrder);
                      },
                      children: [
                        for (var i = 0; i < order().length; i++)
                          ReorderableDelayedDragStartListener(
                            key: ValueKey(order()[i]),
                            index: i,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Center(
                                child: Text(
                                  socialText(
                                    c,
                                    fa[int.parse(order()[i])],
                                    names[int.parse(order()[i])],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              )
            : mode == 'hide'
            ? ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (var i = 0; i < names.length; i++)
                    SwitchListTile(
                      title: Text(socialText(c, fa[i], names[i])),
                      value: tabsHidden().contains('$i'),
                      onChanged: (v) {
                        final hidden = [...tabsHidden()];
                        if (v && hidden.length < names.length - 1)
                          hidden.add('$i');
                        if (!v) hidden.remove('$i');
                        settings.setOption(hiddenKey, hidden);
                      },
                    ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  if ((video
                          ? [
                              ...settings.videoHiddenUris,
                              ...settings.videoHiddenFolders,
                            ]
                          : settings.hiddenPaths)
                      .isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        socialText(
                          c,
                          'از منوی فایل یا پوشه گزینه مخفی کردن را انتخاب کنید.',
                          'Choose Hide from a file or folder menu.',
                        ),
                      ),
                    ),
                  for (final path
                      in video
                          ? settings.videoHiddenFolders
                          : settings.hiddenPaths)
                    ListTile(
                      title: Text(videoNames[path] ?? path),
                      trailing: IconButton(
                        icon: const Icon(Icons.visibility),
                        tooltip: socialText(c, 'نمایش دوباره', 'Unhide'),
                        onPressed: () => settings.setOption(
                          video ? 'videoHiddenFolders' : 'hiddenPaths',
                          [
                            ...(video
                                ? settings.videoHiddenFolders
                                : settings.hiddenPaths),
                          ]..remove(path),
                        ),
                      ),
                    ),
                  if (video)
                    for (final uri in settings.videoHiddenUris)
                      ListTile(
                        title: Text(videoNames[uri] ?? uri),
                        trailing: IconButton(
                          icon: const Icon(Icons.visibility),
                          tooltip: socialText(c, 'نمایش دوباره', 'Unhide'),
                          onPressed: () => settings.setOption(
                            'videoHiddenUris',
                            [...settings.videoHiddenUris]..remove(uri),
                          ),
                        ),
                      ),
                ],
              ),
      ),
    );
  }
}
