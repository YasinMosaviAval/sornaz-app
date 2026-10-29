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
  bool admin = false;
  String stage = 'academy';
  int academies = 0, branches = 0, skips = 0;
  String? sentStep;
  @override
  Future<Map<String, dynamic>> state() async => data();
  Map<String, dynamic> data() => {
    'stage': stage,
    'otp_required': !admin,
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
    expect(otp, admin ? '' : '123456');
    if (step == 'academy') {
      academies++;
      stage = 'complete';
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

Future<void> register(
  WidgetTester tester, {
  bool branch = false,
  bool admin = false,
}) async {
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
  if (admin) return;
  await fill(tester, 'registration-otp', '123456');
  await tester.ensureVisible(find.text('تأیید و ثبت'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('تأیید و ثبت'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'administrator finishes academy registration without branch or OTP steps',
    (tester) async {
      final api = RegistrationFake()..admin = true;
      await tester.pumpWidget(
        fixture.host(AcademyRegistrationPage(api: api, userId: 1)),
      );
      await tester.pumpAndSettle();
      await register(tester, admin: true);
      expect(api.academies, 1);
      expect(api.sentStep, isNull);
      expect(api.branches, 0);
      expect(api.skips, 0);
      expect(api.sentStep, isNull);
      expect(find.byKey(const ValueKey('registration-otp')), findsNothing);
      expect(find.byKey(const ValueKey('registration-panel')), findsOneWidget);
      expect(find.text('ثبت شعبه اصلی'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final signedIn in [false, true]) {
    testWidgets(
      'native academy registration finishes directly signedIn=$signedIn',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final api = RegistrationFake();
        await tester.pumpWidget(
          fixture.host(
            AcademyRegistrationPage(
              api: api,
              userId: signedIn ? 9 : 0,
              token: signedIn ? 'token' : '',
            ),
          ),
        );
        await tester.pumpAndSettle();
        await register(tester);
        expect(api.academies, 1);
        expect(find.byKey(const ValueKey('without-branch')), findsNothing);
        expect(find.text('ثبت شعبه اصلی'), findsNothing);
        expect(
          find.byKey(const ValueKey('registration-panel')),
          findsOneWidget,
        );
        expect(find.textContaining('منوی سازمان'), findsOneWidget);
        expect(api.branches, 0);
        expect(api.skips, 0);
        expect(api.stage, 'complete');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        api.dispose();
      },
    );
  }
  for (final stage in ['choice', 'branch', 'complete']) {
    testWidgets('resuming legacy $stage ends at the Organization instruction', (
      tester,
    ) async {
      final api = RegistrationFake()..stage = stage;
      await tester.pumpWidget(fixture.host(AcademyRegistrationPage(api: api)));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('without-branch')), findsNothing);
      expect(find.text('ثبت شعبه اصلی'), findsNothing);
      expect(find.byKey(const ValueKey('registration-panel')), findsOneWidget);
      expect(find.byKey(const ValueKey('email')), findsNothing);
      expect(api.branches, 0);
      expect(api.skips, 0);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    });
  }
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
