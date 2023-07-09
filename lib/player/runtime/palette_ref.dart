import 'dart:io';

import 'package:dirplayer/player/runtime/score.dart';
import 'package:flutter/foundation.dart';

enum BuiltInPalette {
  grayscale(-3), // -3
  pastels(-4), // -4
  vivid(-5), // -5
  ntsc(-6), // -6
  metallic(-7), // -7
  web216(-8), // -8
  vga(-9), // -9
  systemWinDir4(-101), // -101
  systemWin(-102), // -102
  systemMac(-1), // -1
  rainbow(-2); // -2
  final int intValue;
  const BuiltInPalette(this.intValue);
  static BuiltInPalette fromName(String value) => BuiltInPalette.values.firstWhere((element) => element.name.toLowerCase() == value.toLowerCase());
  static BuiltInPalette fromValue(int value) => BuiltInPalette.values.firstWhere((element) => element.intValue == value);
  static BuiltInPalette get systemDefault {
    if (kIsWeb || Platform.isWindows) {
      return BuiltInPalette.systemWin;
    } else {
      return BuiltInPalette.systemMac;
    }
  }
}

class PaletteRef {
  int paletteId;
  // TODO CastMemberReference? memberRef;
  PaletteRef(this.paletteId);

  bool isBuiltin() {
    return paletteId < 0;
  }

  BuiltInPalette toBuiltin() {
    return BuiltInPalette.fromValue(paletteId);
  }
}
