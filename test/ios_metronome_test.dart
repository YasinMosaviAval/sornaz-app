import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sornaz/screens/Metronome/controller/metronome_controller.dart';

void main() {
  testWidgets(
    'iOS metronome sends tempo and volume changes to its native audio clock',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      const methods = MethodChannel('sornaz/metronome');
      const events = MethodChannel('sornaz/metronome/events');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(methods, (call) async {
        calls.add(call);
        return null;
      });
      messenger.setMockMethodCallHandler(events, (call) async => null);
      final controller = MetronomeController();
      try {
        controller.start();
        await tester.pump();
        expect(controller.isPlaying, true);
        expect(calls.last.method, 'start');
        controller.setBpm(180);
        controller.setTickVolume(.25);
        controller.setAccentVolume(.5);
        controller.setSubTickVolume(.1);
        await tester.pump();
        expect(calls.last.method, 'configure');
        expect(calls.last.arguments, containsPair('bpm', 180));
        expect(calls.last.arguments, containsPair('tick', .25));
        expect(calls.last.arguments, containsPair('accent', .5));
        expect(calls.last.arguments, containsPair('sub', .1));
        controller.stop();
        await tester.pump();
        expect(calls.last.method, 'stop');
        expect(controller.isPlaying, false);
      } finally {
        controller.dispose();
        await tester.pump();
        messenger.setMockMethodCallHandler(methods, null);
        messenger.setMockMethodCallHandler(events, null);
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );
}
