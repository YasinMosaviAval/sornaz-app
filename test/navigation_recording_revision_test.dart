import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Social/course_browse.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'package:sornaz/screens/Social/social_profile.dart';
import 'package:sornaz/screens/Voice%20Recorder/ui/components/seekable_waveform.dart';
import 'social_widget_test.dart' as fixture;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'profile editor accepts empty list links and shows editable fields',
    (tester) async {
      final api = SocialApi('');
      await tester.pumpWidget(
        fixture.host(
          EditProfilePage(
            api: api,
            profile: {'name': 'Student', 'bio': '', 'links': []},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsWidgets);
      expect(find.text('Student'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
  testWidgets(
    'course cards render empty API metadata and both price filters work',
    (tester) async {
      final api = SocialApi('');
      await tester.pumpWidget(
        fixture.host(
          Scaffold(
            body: CourseBrowse(
              api: api,
              items: [
                {
                  'id': 1,
                  'title': 'Free lesson',
                  'price': 0,
                  'details': [],
                  'rating': [],
                  'author': [],
                },
                {
                  'id': 2,
                  'title': 'Paid lesson',
                  'price': 100,
                  'details': [],
                  'rating': [],
                  'author': [],
                },
              ],
              open: (_) {},
              refresh: () async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Free lesson'), findsOneWidget);
      expect(find.text('Paid lesson'), findsOneWidget);
      expect(
        tester
            .widgetList<Checkbox>(find.byType(Checkbox))
            .every((c) => c.value == true),
        true,
      );
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();
      expect(find.text('Free lesson'), findsNothing);
      expect(find.text('Paid lesson'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
  testWidgets(
    'centered waveform seeks by tapping and dragging without slider',
    (tester) async {
      int? at;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 250,
              child: SeekableWaveform(
                samples: const [.2, .8, .4],
                duration: 10000,
                position: 5000,
                markers: const [2000],
                onSeek: (v) => at = v,
              ),
            ),
          ),
        ),
      );
      final bounds = tester.getRect(find.byType(SeekableWaveform));
      await tester.tapAt(Offset(bounds.center.dx + 60, bounds.center.dy));
      expect(at, 6000);
      expect(find.byType(Slider), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
