import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/ab_repeat.dart';
import 'package:sornaz/screens/Players/providers/audio_player_provider.dart';
import 'package:sornaz/screens/Players/playback/playback_queue_manager.dart';
import 'package:sornaz/screens/Players/scan/audio_file.dart';
import 'package:sornaz/screens/Players/ui/pages/music_player_tabs.dart';
import 'package:sornaz/screens/Players/ui/components/audio_controls.dart';
import 'social_widget_test.dart' as fixture;
class Audio extends ChangeNotifier implements AudioPlayerProvider {
 @override bool get isPlaying=>false;
 @override bool get isUndoMode=>false;
 @override bool get folderMode=>false;
 @override bool get isShuffle=>false;
 @override RepeatMode get repeatMode=>RepeatMode.off;
 @override double get playbackSpeed=>1;
 @override List<double> get speedOptions=>[1,2];
 @override AudioFile? get currentAudio=>null;
 @override final abRepeat=AbRepeat();
 @override dynamic noSuchMethod(Invocation invocation)=>super.noSuchMethod(invocation);
}
void main(){
 for(final direction in TextDirection.values){
 testWidgets('player slides retain physical left/right order with controls at 320: $direction',(tester)async{
 tester.view.physicalSize=const Size(320,640);tester.view.devicePixelRatio=1;
 addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
 final audio=Audio();
 await tester.pumpWidget(fixture.host(ChangeNotifierProvider<AudioPlayerProvider>.value(value:audio,child:Directionality(textDirection:direction,child:const Scaffold(body:MusicPlayerTabs(pages:[Center(child:Text('info-page')),Center(child:Text('list-page')),Center(child:Text('eq-page')),Center(child:Text('playlist-page'))],controls:AudioControls()))))));
 await tester.pumpAndSettle();expect(find.text('list-page').hitTestable(),findsOneWidget);expect(find.byType(TabBar),findsNothing);
 final left=direction==TextDirection.rtl?'player-trailing-slide':'player-leading-slide';
 final right=direction==TextDirection.rtl?'player-leading-slide':'player-trailing-slide';
 await tester.tap(find.byKey(ValueKey(left)));await tester.pumpAndSettle();expect(find.text('info-page').hitTestable(),findsOneWidget);
 expect(tester.widget<IconButton>(find.byKey(ValueKey(left))).onPressed,isNull);
 await tester.tap(find.byKey(ValueKey(right)));await tester.pumpAndSettle();
 await tester.drag(find.byType(PageView),const Offset(-280,0));await tester.pumpAndSettle();expect(find.text('eq-page').hitTestable(),findsOneWidget);
 await tester.tap(find.byKey(ValueKey(right)));await tester.pumpAndSettle();expect(find.text('playlist-page').hitTestable(),findsOneWidget);
 expect(tester.widget<IconButton>(find.byKey(ValueKey(right))).onPressed,isNull);
 expect(tester.takeException(),isNull);await tester.pumpWidget(const SizedBox());audio.dispose();
 });
 }
}