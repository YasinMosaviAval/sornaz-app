import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/widgets.dart';

class NoteIcons {

  static const String _basePath = 'assets/icons/notes/';

  static final Widget quarter = SvgPicture.asset(
    '${_basePath}quarter.svg',
    width: 24,
    height: 24,
  );

  static final Widget eighth = SvgPicture.asset(
    '${_basePath}eighth.svg',
    width: 24,
    height: 24,
  );

  static final Widget triplet = SvgPicture.asset(
    '${_basePath}triplet.svg',
    width: 24,
    height: 24,
  );

  static final Widget half = SvgPicture.asset(
    '${_basePath}half.svg',
    width: 24,
    height: 24,
  );


  static Widget quarterNote({double size = 24, Color? color}) {
    return SvgPicture.asset(
      '${_basePath}quarter.svg',
      width: size,
      height: size,
      color: color,
    );
  }

}


/// مدل هر نماد موسیقی
class MusicSymbol {
  final String name;       // نام نماد
  final String type;       // note, rest, articulation, dynamic
  final String assetPath;  // مسیر SVG
  final double defaultSize;

  const MusicSymbol({
    required this.name,
    required this.type,
    required this.assetPath,
    this.defaultSize = 24.0,
  });

  /// نمایش Widget SVG
  Widget widget({double? size, Color? color}) {
    return SvgPicture.asset(
      assetPath,
      width: size ?? defaultSize,
      height: size ?? defaultSize,
      color: color,
    );
  }
}

/// مجموعه تمام نت‌ها و علائم موسیقی
class MusicSymbols {
  static const String _notePath = 'assets/icons/notes/';
  static const String _restPath = 'assets/icons/rests/';
  static const String _artPath = 'assets/icons/articulation/';
  static const String _dynPath = 'assets/icons/dynamics/';

  /// نت‌ها
  static const MusicSymbol wholeNote = MusicSymbol(
    name: 'Whole Note',
    type: 'note',
    assetPath: '${_notePath}whole.svg',
  );
  static const MusicSymbol halfNote = MusicSymbol(
    name: 'Half Note',
    type: 'note',
    assetPath: '${_notePath}half.svg',
  );
  static const MusicSymbol quarterNote = MusicSymbol(
    name: 'Quarter Note',
    type: 'note',
    assetPath: '${_notePath}quarter.svg',
  );
  static const MusicSymbol eighthNote = MusicSymbol(
    name: 'Eighth Note',
    type: 'note',
    assetPath: '${_notePath}eighth.svg',
  );
  static const MusicSymbol sixteenthNote = MusicSymbol(
    name: 'Sixteenth Note',
    type: 'note',
    assetPath: '${_notePath}sixteenth.svg',
  );
  static const MusicSymbol tripletNote = MusicSymbol(
    name: 'Triplet',
    type: 'note',
    assetPath: '${_notePath}triplet.svg',
  );

  /// سکوت‌ها
  static const MusicSymbol wholeRest = MusicSymbol(
    name: 'Whole Rest',
    type: 'rest',
    assetPath: '${_restPath}whole_rest.svg',
  );
  static const MusicSymbol halfRest = MusicSymbol(
    name: 'Half Rest',
    type: 'rest',
    assetPath: '${_restPath}half_rest.svg',
  );
  static const MusicSymbol quarterRest = MusicSymbol(
    name: 'Quarter Rest',
    type: 'rest',
    assetPath: '${_restPath}quarter_rest.svg',
  );
  static const MusicSymbol eighthRest = MusicSymbol(
    name: 'Eighth Rest',
    type: 'rest',
    assetPath: '${_restPath}eighth_rest.svg',
  );

  /// علائم اجرا
  static const MusicSymbol accent = MusicSymbol(
    name: 'Accent',
    type: 'articulation',
    assetPath: '${_artPath}accent.svg',
  );
  static const MusicSymbol staccato = MusicSymbol(
    name: 'Staccato',
    type: 'articulation',
    assetPath: '${_artPath}staccato.svg',
  );
  static const MusicSymbol tenuto = MusicSymbol(
    name: 'Tenuto',
    type: 'articulation',
    assetPath: '${_artPath}tenuto.svg',
  );
  static const MusicSymbol fermata = MusicSymbol(
    name: 'Fermata',
    type: 'articulation',
    assetPath: '${_artPath}fermata.svg',
  );
  static const MusicSymbol slur = MusicSymbol(
    name: 'Slur',
    type: 'articulation',
    assetPath: '${_artPath}slur.svg',
  );
  static const MusicSymbol tie = MusicSymbol(
    name: 'Tie',
    type: 'articulation',
    assetPath: '${_artPath}tie.svg',
  );

  /// علائم دینامیک و صدا
  static const MusicSymbol forte = MusicSymbol(
    name: 'Forte (f)',
    type: 'dynamic',
    assetPath: '${_dynPath}f.svg',
  );
  static const MusicSymbol piano = MusicSymbol(
    name: 'Piano (p)',
    type: 'dynamic',
    assetPath: '${_dynPath}p.svg',
  );
  static const MusicSymbol mezzoForte = MusicSymbol(
    name: 'Mezzo Forte (mf)',
    type: 'dynamic',
    assetPath: '${_dynPath}mf.svg',
  );
  static const MusicSymbol mezzoPiano = MusicSymbol(
    name: 'Mezzo Piano (mp)',
    type: 'dynamic',
    assetPath: '${_dynPath}mp.svg',
  );
  static const MusicSymbol crescendo = MusicSymbol(
    name: 'Crescendo',
    type: 'dynamic',
    assetPath: '${_dynPath}crescendo.svg',
  );
  static const MusicSymbol decrescendo = MusicSymbol(
    name: 'Decrescendo',
    type: 'dynamic',
    assetPath: '${_dynPath}decrescendo.svg',
  );
}


/*
assets/icons/
├── notes/
│   ├── whole.svg
│   ├── half.svg
│   ├── quarter.svg
│   ├── eighth.svg
│   ├── sixteenth.svg
│   ├── triplet.svg
├── rests/
│   ├── whole_rest.svg
│   ├── half_rest.svg
│   ├── quarter_rest.svg
│   ├── eighth_rest.svg
│   ├── sixteenth_rest.svg
├── articulation/
│   ├── accent.svg
│   ├── staccato.svg
│   ├── tenuto.svg
│   ├── fermata.svg
│   ├── slur.svg
│   ├── tie.svg
├── dynamics/
│   ├── f.svg
│   ├── p.svg
│   ├── mf.svg
│   ├── mp.svg
│   ├── crescendo.svg
│   ├── decrescendo.svg
*/



/*
1️⃣ نت‌های پایه
نام	توضیح	نماد پیشنهادی
Whole	نت گرد	◯
Half	نت سفید	♩
Quarter	نت سیاه	♪
Eighth	نت چنگ	♫
Sixteenth	دو چنگ	♬
Thirty-second	چهار چنگ	♭
Sixty-fourth	پنج چنگ	♮
Hundred-twenty-eighth	شش چنگ	♯
2️⃣ نت‌های نقطه‌دار (Dotted Notes)
نام	توضیح	نماد پیشنهادی
Dotted Whole	نت گرد نقطه‌دار	◯·
Dotted Half	نت سفید نقطه‌دار	♩·
Dotted Quarter	نت سیاه نقطه‌دار	♪·
Dotted Eighth	نت چنگ نقطه‌دار	♫·
Dotted Sixteenth	دو چنگ نقطه‌دار	♬·
3️⃣ سکوت‌ها (Rests)
نام	توضیح
Whole Rest	سکوت یک ضرب کامل
Half Rest	سکوت نصف ضرب
Quarter Rest	سکوت یک چهارم
Eighth Rest	سکوت چنگ
Sixteenth Rest	سکوت دو چنگ
Thirty-second Rest	سکوت چهار چنگ
4️⃣ علامت‌های پرچم و اکسنت
نام	توضیح
Accent	تأکید روی ضرب
Staccato	کوتاه و منقطع
Tenuto	کشش کامل
Fermata	توقف روی نت
Slur	کشش ملودی بین نت‌ها
Tie	اتصال دو نت هم‌نوع
Triplet	تقسیم ضرب به سه قسمت
Duplet / Quadruplet	تقسیم ضرب به ۲ یا ۴
5️⃣ سایر علائم رایج
نام	توضیح
Crescendo	کم‌کم صدا را زیاد کن
Decrescendo	کم‌کم صدا را کم کن
Forte	صدای بلند
Piano	صدای کم
Mezzo Forte	متوسط بلند
Mezzo Piano	متوسط کم
Dynamic Marks	p, f, mf, mp, sf, sffz …
*/