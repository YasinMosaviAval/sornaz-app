/// Canonical logical pixels and inactive colors for every piano adapter.
abstract final class PianoKeyboardSpec {
  static const whiteHeight = 180.0;
  static const blackHeight = 130.0;
  static const quarterHeight = blackHeight * .75;
  static const whiteWidth = 60.0;
  static const iranianWhiteWidth = 120.0;
  static const blackWidth = 40.0;
  static const whiteColor = 0xffffffff;
  static const blackColor = 0xff000000;
  // Opaque equivalents of the tuner's original colors over a white key.
  // A translucent overlay would expose the seam between E/F or B/C underneath.
  static const koronColor = 0xffbdbdbd;
  static const soriColor = 0xff777777;
  static String cssColor(int color) =>
      '#${(color & 0xffffff).toRadixString(16).padLeft(6, '0')}${(color >> 24).toRadixString(16).padLeft(2, '0')}';
  static Map<String, Object> get browser => {
    'whiteHeight': whiteHeight,
    'blackHeight': blackHeight,
    'quarterHeight': quarterHeight,
    'whiteWidth': whiteWidth,
    'iranianWhiteWidth': iranianWhiteWidth,
    'blackWidth': blackWidth,
    'whiteColor': cssColor(whiteColor),
    'blackColor': cssColor(blackColor),
    'koronColor': cssColor(koronColor),
    'soriColor': cssColor(soriColor),
  };
}
