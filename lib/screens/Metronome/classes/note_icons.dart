// ignore_for_file: constant_identifier_names

import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/widgets.dart';
import 'package:sornaz/helpers/app_constants.dart';

class NoteIcons {

  static const String _basePath = AppConstants.BASE_PATH;

  static final Widget quarter = SvgPicture.asset(
    '$_basePath${AppConstants.QUARTER_SVG}',
    width: 24,
    height: 24,
  );

  static final Widget eighth = SvgPicture.asset(
    '$_basePath${AppConstants.EIGHTH_SVG}',
    width: 24,
    height: 24,
  );

  static final Widget triplet = SvgPicture.asset(
    '$_basePath${AppConstants.TRIPLET_SVG}',
    width: 24,
    height: 24,
  );

  static final Widget half = SvgPicture.asset(
    '$_basePath${AppConstants.HALF_SVG}',
    width: 24,
    height: 24,
  );


  static Widget quarterNote({double size = 24, Color? color}) {
    return SvgPicture.asset(
      '$_basePath${AppConstants.QUARTER_SVG}',
      width: size,
      height: size,
      // color: color,
    );
  }

}


/// مدل هر نماد موسیقی
class MusicSymbol {
  final String name;
  final String type;
  final String assetPath;
  final double defaultSize;

  const MusicSymbol({
    required this.name,
    required this.type,
    required this.assetPath,
    this.defaultSize = 24.0,
  });

  /// نمایش Widget SVG
  Widget noteWidget({double? size, Color? color}) {
    return SvgPicture.asset(
      assetPath,
      width: size ?? defaultSize,
      height: size ?? defaultSize,
      colorFilter: color == null ? null : ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

/// مجموعه تمام نت‌ها و علائم موسیقی
class MusicSymbols {
  static const String _notePath = AppConstants.NOTES_PATH;
  static const String _restPath = AppConstants.RESTS_PATH;
  // static const String _artPath = AppConstants.ARTICULATIONS_PATH;
  // static const String _dynPath = AppConstants.DYNAMICS_PATH;
  static const String _signaturePath = AppConstants.SIGNATURES_PATH;

  static Widget quarter({double size = 24, Color? color}) {
    return SvgPicture.asset(
      '$_notePath${AppConstants.QUARTER_SVG}',
      width: size,
      height: size,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  static Widget eighth({double size = 24, Color? color}) {
    return SvgPicture.asset(
      '$_notePath${AppConstants.EIGHTH_SVG}',
      width: size,
      height: size,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  static const MusicSymbol double_whole_note = MusicSymbol(name: AppConstants.DOUBLE_WHOLE_NOTE_NAME, type: AppConstants.NOTE, assetPath: '$_notePath${AppConstants.DOUBLE_WHOLE_SVG}');
  static const MusicSymbol whole_note = MusicSymbol(name: AppConstants.WHOLE_NOTE_NAME, type: AppConstants.NOTE, assetPath: '$_notePath${AppConstants.WHOLE_SVG}');
  static const MusicSymbol half_note = MusicSymbol(name: AppConstants.HALF_NOTE_NAME, type: AppConstants.NOTE, assetPath: '$_notePath${AppConstants.HALF_SVG}');
  static const MusicSymbol half_note_reverse = MusicSymbol(name: AppConstants.HALF_NOTE_REVERSE_NAME, type: AppConstants.NOTE, assetPath: '$_notePath${AppConstants.HALF_REVERSE_SVG}');
  static const MusicSymbol quarter_note = MusicSymbol(name: AppConstants.QUARTER_NOTE_NAME, type: AppConstants.NOTE, assetPath: '$_notePath${AppConstants.QUARTER_SVG}');
  static const MusicSymbol quarter_note_reverse = MusicSymbol(name: AppConstants.QUARTER_NOTE_REVERSE_NAME, type: AppConstants.NOTE, assetPath: '$_notePath${AppConstants.QUARTER_REVERSE_SVG}');
  static const MusicSymbol eighth_note = MusicSymbol(name: AppConstants.EIGHTH_NOTE_NAME, type: AppConstants.NOTE, assetPath: '$_notePath${AppConstants.EIGHTH_SVG}');
  static const MusicSymbol eighth_note_reverse = MusicSymbol(name: AppConstants.EIGHTH_NOTE_REVERSE_NAME, type: AppConstants.NOTE, assetPath: '$_notePath${AppConstants.EIGHTH_REVERSE_SVG}');
  static const MusicSymbol sixteenth_note = MusicSymbol(name: AppConstants.SIXTEENTH_NOTE_NAME, type: AppConstants.NOTE, assetPath: '$_notePath${AppConstants.SIXTEENTH_SVG}');
  static const MusicSymbol sixteenth_note_reverse = MusicSymbol(name: AppConstants.SIXTEENTH_NOTE_REVERSE_NAME, type: AppConstants.NOTE, assetPath: '$_notePath${AppConstants.SIXTEENTH_REVERSE_SVG}');

  static const MusicSymbol full_rest = MusicSymbol(name: AppConstants.FULL_REST_NAME, type: AppConstants.REST, assetPath: '$_restPath${AppConstants.FULL_REST_SVG}');
  static const MusicSymbol whole_rest = MusicSymbol(name: AppConstants.WHOLE_REST_NAME, type: AppConstants.REST, assetPath: '$_restPath${AppConstants.WHOLE_REST_SVG}');
  static const MusicSymbol half_rest = MusicSymbol(name: AppConstants.HALF_REST_NAME, type: AppConstants.REST, assetPath: '$_restPath${AppConstants.HALF_REST_SVG}');
  static const MusicSymbol quarter_rest = MusicSymbol(name: AppConstants.QUARTER_REST_NAME, type: AppConstants.REST, assetPath: '$_restPath${AppConstants.QUARTER_REST_SVG}');
  static const MusicSymbol eighth_rest = MusicSymbol(name: AppConstants.EIGHTH_REST_NAME, type: AppConstants.REST, assetPath: '$_restPath${AppConstants.EIGHTH_REST_SVG}');
  static const MusicSymbol sixteenth_rest = MusicSymbol(name: AppConstants.SIXTEENTH_REST_NAME, type: AppConstants.REST, assetPath: '$_restPath${AppConstants.SIXTEENTH_REST_SVG}');


  static const MusicSymbol clef_c = MusicSymbol(name: AppConstants.CLEF_C_NAME, type: AppConstants.SIGNATURE, assetPath: '$_signaturePath${AppConstants.CLEF_C_SVG}');
  static const MusicSymbol clef_f = MusicSymbol(name: AppConstants.CLEF_F_NAME, type: AppConstants.SIGNATURE, assetPath: '$_signaturePath${AppConstants.CLEF_F_SVG}');
  static const MusicSymbol clef_g = MusicSymbol(name: AppConstants.CLEF_G_NAME, type: AppConstants.SIGNATURE, assetPath: '$_signaturePath${AppConstants.CLEF_G_SVG}');

  static const MusicSymbol bemol = MusicSymbol(name: AppConstants.BEMOL_NAME, type: AppConstants.SIGNATURE, assetPath: '$_signaturePath${AppConstants.BEMOL_SVG}');
  static const MusicSymbol sharp = MusicSymbol(name: AppConstants.SHARP_NAME, type: AppConstants.SIGNATURE, assetPath: '$_signaturePath${AppConstants.SHARP_SVG}');
  static const MusicSymbol becarre = MusicSymbol(name: AppConstants.BECARRE_NAME, type: AppConstants.SIGNATURE, assetPath: '$_signaturePath${AppConstants.BECARRE_SVG}');
  static const MusicSymbol double_bemol = MusicSymbol(name: AppConstants.DOUBLE_BEMOL_NAME, type: AppConstants.SIGNATURE, assetPath: '$_signaturePath${AppConstants.DOUBLE_BEMOL_SVG}');
  static const MusicSymbol double_sharp = MusicSymbol(name: AppConstants.DOUBLE_SHARP_NAME, type: AppConstants.SIGNATURE, assetPath: '$_signaturePath${AppConstants.DOUBLE_SHARP_SVG}');
  static const MusicSymbol becarre_bemol = MusicSymbol(name: AppConstants.BECARRE_BEMOL_NAME, type: AppConstants.SIGNATURE, assetPath: '$_signaturePath${AppConstants.BECARRE_BEMOL_SVG}');
  static const MusicSymbol becarre_sharp = MusicSymbol(name: AppConstants.BECARRE_SHARP_NAME, type: AppConstants.SIGNATURE, assetPath: '$_signaturePath${AppConstants.BECARRE_SHARP_SVG}');


}


/*

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
*/


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