import 'package:flutter/foundation.dart';
import 'package:sornaz/components/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';

class AppReleaseInfo extends StatelessWidget {
  const AppReleaseInfo({super.key, this.rating = false});
  final bool rating;
  static const playUrl = String.fromEnvironment('SORNAZ_PLAY_STORE_URL');
  static const appleUrl = String.fromEnvironment('SORNAZ_APP_STORE_URL');
  static Future<String> version() async {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      return await const MethodChannel(
            'sornaz/app_info',
          ).invokeMethod<String>('version') ??
          'Unknown';
    }
    return const String.fromEnvironment(
      'FLUTTER_BUILD_NAME',
      defaultValue: '1.0.0',
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: SornazAppBar(title: rating ? 'Rate Us' : 'Version'),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: rating
            ? FilledButton.icon(
                icon: const Icon(Icons.star_outline),
                label: Text(socialText(context, 'امتیاز دادن', 'Rate Us')),
                onPressed: () async {
                  final url = defaultTargetPlatform == TargetPlatform.iOS
                      ? appleUrl
                      : playUrl;
                  if (url.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          socialText(
                            context,
                            'برنامه هنوز در فروشگاه منتشر نشده است.',
                            'The app has not been published in the store yet.',
                          ),
                        ),
                      ),
                    );
                    return;
                  }
                  final opened = await launchUrl(
                    Uri.parse(url),
                    mode: LaunchMode.externalApplication,
                  );
                  if (!opened && context.mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          socialText(
                            context,
                            'باز کردن فروشگاه ممکن نیست.',
                            'Could not open the store.',
                          ),
                        ),
                      ),
                    );
                },
              )
            : FutureBuilder<String>(
                future: version(),
                builder: (c, snapshot) => Text(
                  snapshot.hasError
                      ? socialText(
                          c,
                          'نسخه در دسترس نیست',
                          'Version unavailable',
                        )
                      : snapshot.data ?? '…',
                ),
              ),
      ),
    ),
  );
}
