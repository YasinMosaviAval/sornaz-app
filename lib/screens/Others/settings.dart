import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_data.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    // final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text('Notification'),
          ),
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Get notified of app alerts'),
            value: appData.pushNotifications,
            onChanged: appData.togglePushNotifications,
          ),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('If it is ON, your app theme is Dark'),
            value: appData.isDark,
            onChanged: appData.toggleDarkMode,
          ),
          SwitchListTile(
            title: const Text('New course alerts'),
            subtitle: const Text('Know when instructors upload'),
            value: appData.newCourseAlerts,
            onChanged: appData.toggleNewCourseAlerts,
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text('Data'),
          ),
          SwitchListTile(
            title: const Text('Use WiFi'),
            subtitle: const Text('App will use wifi over data'),
            value: appData.useWifiOverData,
            onChanged: appData.toggleUseWifiOverData,
          ),
          SwitchListTile(
            title: const Text('Auto-download'),
            subtitle: const Text(
              'Courses will automatically save to your device',
            ),
            value: appData.autoDownload,
            onChanged: appData.toggleAutoDownload,
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text('Elements'),
          ),
          ListTile(
            title: const Text('Text Size'),
            subtitle: const Text('App will use wifi over data'),
            trailing: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(border: Border.all()),
              child: Text(appData.textSize.toInt().toString()),
            ),
          ),
          Slider(
            value: appData.textSize,
            min: 10,
            max: 20,
            divisions: 10,
            label: appData.textSize.toInt().toString(),
            onChanged: appData.updateTextSize,
          ),
        ],
      ),
    );
  }
}
