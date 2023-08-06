import 'package:dirplayer/player/runtime/xtras/multiuser.dart';

class XtraManager {
  static final Map<String, dynamic> xtras = {
    "Multiuser": MultiuserXtra()
  };

  static dynamic getXtra(String name) {
    return xtras[name];
  }
}
