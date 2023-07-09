import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dirplayer/player/runtime/bitmap/ink_utils.dart';

import '../../../director/chunks/bitmap.dart';

typedef GetColorCallback = ui.Color Function(int color);

class BitmapUtils {
  static Future<ui.Image> decodeRgba8888Image(Uint8List bytes, BitmapInfo bitmapInfo) async {
    //var rgba8888bytes = decodeNuuImage(bytes, bitmapInfo, getColor);
    var completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      bytes, 
      bitmapInfo.width, 
      bitmapInfo.height, 
      ui.PixelFormat.rgba8888,
      (result) => completer.complete(result),
      allowUpscaling: false
    );
    return await completer.future;
  }

  static Uint8List palette8bitToRgba8(Uint8List bytes, int width, int height, GetColorCallback getColor) {
    var outBytesPerPixel = 4;
    var inBytesPerPixel = 1;
    var rgba8888bytes = List.filled(width * height * outBytesPerPixel, 0);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        var baseIndexIn = ((y * width) + x) * inBytesPerPixel;
        var baseIndexOut = ((y * width) + x) * outBytesPerPixel;

        var colorNumber = bytes[baseIndexIn];
        var color = getColor(colorNumber);
        rgba8888bytes[baseIndexOut] = color.red;
        rgba8888bytes[baseIndexOut + 1] = color.green;
        rgba8888bytes[baseIndexOut + 2] = color.blue;
        rgba8888bytes[baseIndexOut + 3] = color.alpha;
      }
    }

    return Uint8List.fromList(rgba8888bytes);
  }

  static Uint8List blendImageBytes(Uint8List bytes, int width, int height, int ink) {
    switch (ink) {
    case 36: // background transparent
      return InkUtils.backgroundTransparent(bytes, width, height);
    default:
      throw Exception("Unknown ink $ink");
    }
  }
}