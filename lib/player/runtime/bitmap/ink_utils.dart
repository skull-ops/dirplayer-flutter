import 'dart:typed_data';
import 'dart:ui';

import 'package:dirplayer/director/chunks/bitmap.dart';

class InkUtils {
  static Uint8List backgroundTransparent(Uint8List data, int width, int height) {
    var result = Uint8List.fromList(data.toList());
    var backgroundColor = const Color.fromARGB(255, 255, 255, 255);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        var baseIndex = ((y * width) + x) * 4;
        var r = data[baseIndex];
        var g = data[baseIndex + 1];
        var b = data[baseIndex + 2];
        var a = data[baseIndex + 3];

        if (r == backgroundColor.red && g == backgroundColor.green && b == backgroundColor.blue) {
          result[baseIndex] = 0;
          result[baseIndex + 1] = 0;
          result[baseIndex + 2] = 0;
          result[baseIndex + 3] = 255;
        }
      }
    }
    return result;
  }
}
