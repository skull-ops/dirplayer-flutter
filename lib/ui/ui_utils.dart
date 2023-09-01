import 'package:dirplayer/director/file.dart';
import 'package:dirplayer/player/player.dart';
import 'package:dirplayer/player/runtime/net_manager.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

Future<DirectorFile?> pickAndLoadDirFile(DirPlayer player) async {
  var result = await FilePicker.platform.pickFiles();
  if (result != null) {
    var file = result.files.single;
    DirectorFile dirFile;
    if (kIsWeb) {
      dirFile = await readDirectorFileFromBytes(file.bytes!, file.name, Uri.parse("C:\\fakedir"));
    } else {
      dirFile = await readDirectorFile(player.vm.netManager, file.path!);
    }
    return dirFile;
  } else {
    return null;
  }
}
