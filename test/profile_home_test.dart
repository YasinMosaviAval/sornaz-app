import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/screens/Home/ui/pages/home.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';
import 'package:sornaz/screens/Social/social_learning.dart';
import 'package:sornaz/screens/Social/learning_actions.dart';

final sampleCourse=<String,dynamic>{'id':12,'title':'آموزش گیتار از پایه','description':'یادگیری گام به گام موسیقی و اجرای نخستین قطعه','price':0,'updated_at':'2026-09-06','lesson_count':4,'author':{'name':'مدرس گیتار'},'completed':1,'progress':25,'completed_ids':[7]};
final sampleProfile=<String,dynamic>{'id':1,'name':'هنرجوی موسیقی','username':'student','bio':'در مسیر یادگیری گیتار','posts':2,'courses':0,'followers':4,'following':5};
http.Response response(dynamic data)=>http.Response.bytes(utf8.encode(jsonEncode({'status':200,'data':{'success':true,'data':data}})),200);
Widget host(Widget child,{bool dark=false,Locale locale=const Locale('fa')})=>ChangeNotifierProvider(create:(_)=>AppData()..toggleDarkMode(dark),child:MaterialApp(locale:locale,supportedLocales:const [Locale('fa'),Locale('en')],localizationsDelegates:const [GlobalMaterialLocalizations.delegate,GlobalWidgetsLocalizations.delegate,GlobalCupertinoLocalizations.delegate],home:child));

void main(){
  setUpAll(() async{
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader=FontLoader('iran_sansx_fa')..addFont(rootBundle.load('assets/fonts/iran_sansx_fa/regular.ttf'));
    await loader.load();
    final icons=FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  setUp(()=>SharedPreferences.setMockInitialValues({}));
  for(final width in [320.0,375.0,430.0]){
    for(final dark in [false,true]){
      testWidgets('home layout and search at $width dark=$dark',(tester) async{
        tester.view.physicalSize=Size(width,900);tester.view.devicePixelRatio=1;
        addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
        final api=SocialApi('',client:MockClient((r) async=>response({'courses':[sampleCourse],'authors':[sampleProfile]})));
        final key=GlobalKey();
        await tester.pumpWidget(host(RepaintBoundary(key:key,child:HomePage(api:api,articleLoader:() async=>[{'title':{'rendered':'راهنمای شروع یادگیری موسیقی'}}])),dark:dark));
        await tester.pumpAndSettle();expect(tester.takeException(),isNull);
        expect(find.text('دوره‌های جدید'),findsNothing);expect(find.text('جست‌وجوی آموزشگاه‌های موسیقی'),findsOneWidget);
        if(width==375){await tester.runAsync(() async{final image=await (key.currentContext!.findRenderObject()! as RenderRepaintBoundary).toImage();final bytes=await image.toByteData(format:ui.ImageByteFormat.png);await Directory('build/profile-previews').create(recursive:true);await File('build/profile-previews/home-${dark?'dark':'light'}.png').writeAsBytes(bytes!.buffer.asUint8List());image.dispose();});}
        await tester.drag(find.byType(ListView).first,const Offset(0,-650));await tester.pumpAndSettle();expect(tester.takeException(),isNull);
        await tester.drag(find.byType(ListView).first,const Offset(0,1500));await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('open-home-search')));await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const ValueKey('home-search')),'ناموجود');await tester.pumpAndSettle();expect(find.text(sampleCourse['title'] as String),findsNothing);expect(find.text('دوره‌های جدید'),findsNothing);await tester.enterText(find.byKey(const ValueKey('home-search')),'');await tester.pumpAndSettle();expect(find.text('دوره‌های جدید'),findsNothing);expect(find.text('جست‌وجوی آموزشگاه‌های موسیقی'),findsOneWidget);expect(tester.takeException(),isNull);
        await tester.pumpWidget(const SizedBox());api.dispose();
      });
    }
  }
  testWidgets('dashboard uses real completion counts and opens saved courses',(tester) async{
    final api=SocialApi('token',client:MockClient((r) async=>response(r.url.path.endsWith('/bookmarks')?{'courses':[sampleCourse],'authors':[sampleProfile]}:{'profile':sampleProfile,'courses':[sampleCourse],'completed_lessons':1,'completed_courses':0})));
    await tester.pumpWidget(host(SocialScaffold(title:'پروفایل',body:AccountDashboardBody(api:api))));await tester.pumpAndSettle();
    await tester.tap(find.text('ذخیره‌شده‌ها'));await tester.pumpAndSettle();expect(find.text(sampleCourse['title']!),findsOneWidget);expect(tester.takeException(),isNull);
    await tester.tap(find.text('نویسندگان'));await tester.pumpAndSettle();expect(find.text(sampleProfile['name']!),findsWidgets);
    await tester.pumpWidget(const SizedBox());api.dispose();
  });
  testWidgets('notification preference persists desired state',(tester) async{
    var follows=true;final api=SocialApi('token',client:MockClient((r) async{if(r.method=='POST')follows=r.bodyFields['follow']=='1';return response({'follow':follows,'message':true,'like':true});}));
    await tester.pumpWidget(host(NotificationSettingsPage(api:api)));await tester.pumpAndSettle();await tester.tap(find.text('دنبال‌کننده جدید'));await tester.pumpAndSettle();expect(follows,isFalse);expect(tester.takeException(),isNull);await tester.pumpWidget(const SizedBox());api.dispose();
  });
  testWidgets('lesson completion can be undone and sent to its course',(tester) async{
    String? path;String? completed;final api=SocialApi('token',client:MockClient((r) async{if(r.method=='POST'){path=r.url.path;completed=r.bodyFields['completed'];return response({'completed':false});}return response({'courses':[sampleCourse]});}));
    await tester.pumpWidget(host(SocialScaffold(title:'درس',body:LessonProgressControl(api:api,courseId:12,postId:7))));await tester.pumpAndSettle();await tester.tap(find.text('تکمیل شد؛ لغو علامت'));await tester.pumpAndSettle();expect(path,endsWith('/courses/12/lessons/7/progress'));expect(completed,'0');expect(find.text('این درس را تکمیل کردم'),findsOneWidget);await tester.pumpWidget(const SizedBox());api.dispose();
  });
}
