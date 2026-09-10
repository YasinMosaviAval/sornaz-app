import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Social/protected_media.dart';
import 'package:sornaz/screens/Social/course_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'package:sornaz/screens/Social/social_downloads.dart';

class TestDownloads extends LessonDownloads{
  TestDownloads(super.api,this.root);final Directory root;
  @override Future<Directory> directory() async=>root;
}
void main(){
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({}); CourseCache.checked.clear(); FlutterSecureStorage.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), (_) async => Directory.systemTemp.path);
  });
  for(final mode in ['success','locked','redirect','truncated']){
    test('download $mode preserves access and file integrity',() async{
      final root=await Directory.systemTemp.createTemp('sornaz-download-test-');
      final api=SocialApi('secret',client:MockClient((r) async=>http.Response(jsonEncode({'success':true,'data':{'id':1,'access':true,'title':'Course','price':0,'curriculum':[{'lessons':[{'post_id':2,'locked':mode=='locked','media':[3]}]}],'files':[{'id':3,'bytes':4,'mime':'video/mp4'}]}}),200)));
      var requests=0;
      final client=MockClient((r) async{requests++;expect(r.followRedirects,isFalse);expect(r.headers['Authorization'],'Bearer secret');return mode=='redirect'?http.Response('',302,headers:{'location':'https://different.example/media'}):http.Response(mode=='truncated'?'12':'1234',200);});
      final downloads=TestDownloads(api,root);
      try{
        if(mode=='success'){
          await downloads.download(1,(_){},client);
          final encrypted = File('${root.path}/1-3.sornaz');
          final clear = await ProtectedMedia(CourseCache.account(api.token)).open(encrypted);
          expect(await clear.readAsString(),'1234'); await ProtectedMedia.close(clear);
          expect(await File('${root.path}/1.json').exists(),isTrue);
          await downloads.remove({'id':1});expect(await root.list().isEmpty,isTrue);
        }else{
          await expectLater(downloads.download(1,(_){},client),throwsA(isA<SocialException>()));
          expect(await File('${root.path}/1.json').exists(),isFalse);
          expect(await root.list().isEmpty,isTrue);
        }
        expect(requests,mode=='locked'?0:1);
      }finally{api.dispose();client.close();await root.delete(recursive:true);}
    });
  }
}
