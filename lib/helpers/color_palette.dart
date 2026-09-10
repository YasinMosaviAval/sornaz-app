import 'package:flutter/material.dart';

enum ColorPalette {
  original('اصلی', 'Original', Color(0xff0064fb), Color(0xffc19e32)),
  indigo('نیلی', 'Indigo', Color(0xff4f46e5), Color(0xff818cf8)),
  emerald('زمردی', 'Emerald', Color(0xff059669), Color(0xff34d399)),
  rose('رز', 'Rose', Color(0xffe11d48), Color(0xfffb7185)),
  amber('کهربایی', 'Amber', Color(0xffd97706), Color(0xfffbbf24));

  const ColorPalette(this.fa, this.en, this.light, this.dark);
  final String fa, en;
  final Color light, dark;
  static ColorPalette current = original;
}
