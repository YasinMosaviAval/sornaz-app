import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';
import 'package:sornaz/screens/Site/academy_registration.dart';
import 'package:sornaz/screens/Site/academy_registration_api.dart';
import 'social_widget_test.dart' as fixture;

class RegistrationFake extends AcademyRegistrationApi {
  String stage = 'academy';
  int academies = 0, branches = 0, skips = 0;
  String? sentStep;
  @override
  Future<Map<String, dynamic>> state() async => data();
  Map<String, dynamic> data() => {
    'stage': stage,
    'academy_name': 'Sornaz',
    'terms': 'Academy terms',
    'branch_terms': 'Branch terms',
    'without_branch': skips > 0,
  };
  @override
  Future<Map<String, dynamic>> sendCode(
    Map<String, String> form,
    String step,
  ) async {
    sentStep = step;
    return {'retry_after': 60, 'expires_in': 120};
  }

  @override
  Future<Map<String, dynamic>> submit(
    Map<String, String> form,
    String step,
    String otp,
  ) async {
    expect(otp, '123456');
    if (step == 'academy') {
      academies++;
      stage = 'choice';
    } else {
      branches++;
      stage = 'complete';
    }
    return data();
  }

  @override
  Future<Map<String, dynamic>> withoutBranch() async {
    skips++;
    stage = 'complete';
    return data();
  }

  @override
  Future<void> forget() async {}
}

Future<void> fill(WidgetTester tester, String key, String value) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.enterText(finder, value);
  await tester.pumpAndSettle();
}

Future<void> register(WidgetTester tester, {bool branch = false}) async {
  await fill(
    tester,
    'email',
    branch ? 'branch@example.test' : 'academy@example.test',
  );
  await fill(tester, 'username', branch ? 'main_branch' : 'my_academy');
  await fill(tester, 'academy_name', branch ? 'Main branch' : 'Academy');
  await fill(tester, 'password', 'StrongPass123!');
  await fill(tester, 'password2', 'StrongPass123!');
  await tester.ensureVisible(find.byType(Checkbox));
  await tester.pumpAndSettle();
  await tester.tap(find.byType(Checkbox));
  await tester.ensureVisible(
    find.byKey(const ValueKey('send-registration-code')),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('send-registration-code')));
  await tester.pumpAndSettle();
  await fill(tester, 'registration-otp', '123456');
  await tester.ensureVisible(find.text('تأیید و ثبت'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('تأیید و ثبت'));
  await tester.pumpAndSettle();
}

void main() {
  for (final branch in [false, true]) {
    testWidgets('native academy registration completes with branch=$branch', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = RegistrationFake();
      await tester.pumpWidget(fixture.host(AcademyRegistrationPage(api: api)));
      await tester.pumpAndSettle();
      await register(tester);
      expect(api.academies, 1);
      expect(find.byKey(const ValueKey('without-branch')), findsOneWidget);
      if (branch) {
        await tester.tap(find.widgetWithText(FilledButton, 'ثبت شعبه اصلی'));
        await tester.pumpAndSettle();
        await register(tester, branch: true);
        expect(api.branches, 1);
        expect(api.skips, 0);
      } else {
        await tester.tap(find.byKey(const ValueKey('without-branch')));
        await tester.pumpAndSettle();
        expect(api.branches, 0);
        expect(api.skips, 1);
      }
      expect(api.stage, 'complete');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    });
  }
  testWidgets('resuming academy registration offers optional branch creation', (
    tester,
  ) async {
    final api = RegistrationFake()..stage = 'choice';
    await tester.pumpWidget(fixture.host(AcademyRegistrationPage(api: api)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('without-branch')), findsOneWidget);
    expect(find.byKey(const ValueKey('email')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
  test(
    'native client keeps its OTP session and flow proof between requests',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      var requests = 0;
      final client = MockClient((r) async {
        requests++;
        if (requests == 1) {
          expect(r.method, 'GET');
          return http.Response(
            jsonEncode({
              'data': {
                'success': true,
                'stage': 'academy',
                'flow_token': 'proof',
              },
            }),
            200,
            headers: {'set-cookie': 'PHPSESSID=session123; HttpOnly; Secure'},
          );
        }
        expect(r.headers['Cookie'], 'PHPSESSID=session123');
        expect(r.headers['X-Academy-Flow'], 'proof');
        return http.Response(
          jsonEncode({
            'data': {'success': true, 'expires_in': 120},
          }),
          200,
        );
      });
      final api = AcademyRegistrationApi(client: client);
      await api.state();
      await api.sendCode({'email': 'a@example.test'}, 'academy');
      expect(requests, 2);
      api.dispose();
    },
  );
}
