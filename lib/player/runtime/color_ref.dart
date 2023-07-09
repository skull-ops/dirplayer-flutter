import 'dart:ui';
import 'package:image/image.dart' as img;
import 'package:logging/logging.dart';

abstract class ColorRef {
  img.Color toImgColor();
  static ColorRef fromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    assert(hexColor.length == 6);

    var r = int.parse(hexColor.substring(0, 2), radix: 16);
    var g = int.parse(hexColor.substring(2, 4), radix: 16);
    var b = int.parse(hexColor.substring(4, 6), radix: 16);

    return RgbColorRef(Color.fromARGB(255, r, g, b));
  }

  static ColorRef fromRgb(int r, int g, int b) {
    return RgbColorRef(Color.fromARGB(255, r, g, b));
  }
}

class RgbColorRef extends ColorRef {
  Color color;
  RgbColorRef(this.color);

  @override
  img.Color toImgColor() {
    return img.ColorUint8.rgba(color.red, color.green, color.blue, color.alpha);
  }
}

class PaletteIndexColorRef extends ColorRef {
  final log = Logger("PaletteIndexColorRef");
  int paletteIndex;
  PaletteIndexColorRef(this.paletteIndex);

  @override
  img.Color toImgColor() {
    log.shout("PaletteIndexColorRef.toImgColor is an invalid call! Returning a fake color");
    return img.ColorUint8.rgba(paletteIndex, paletteIndex, paletteIndex, 255);
  }
}
