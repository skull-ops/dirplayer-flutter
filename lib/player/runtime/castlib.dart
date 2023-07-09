import 'package:dirplayer/common/util.dart';
import 'package:dirplayer/director/chunks/cast.dart';
import 'package:dirplayer/director/chunks/cast_info.dart';
import 'package:dirplayer/director/chunks/cast_member.dart';
import 'package:dirplayer/director/chunks/script_context.dart';
import 'package:dirplayer/director/chunks/text.dart';
import 'package:dirplayer/director/lingo/datum.dart';
import 'package:dirplayer/player/runtime/cast_member.dart';
import 'package:dirplayer/player/runtime/data_reference.dart';
import 'package:dirplayer/player/runtime/image_ref.dart';
import 'package:dirplayer/player/runtime/palette_ref.dart';
import 'package:dirplayer/player/runtime/prop_interface.dart';
import 'package:dirplayer/player/runtime/script.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:dirplayer/director/castmembers.dart' as dir_castmembers;
import 'package:path/path.dart';

import '../../director/chunks/bitmap.dart';
import '../../director/chunks/script.dart';
import '../../director/file.dart';
import '../../director/subchunk.dart';
import '../../reader.dart';
import 'net_manager.dart';
import 'net_task.dart';

class CastLib extends PropInterface {
  //CastChunk castChunk;
  String fileName = "";
  String name;
  int number;
  CastListEntry castListEntry;
  ScriptContextChunk? lctx;
  Map<int, Member> members = {};
  Map<int, TextChunk> texts = {};
  Map<int, Script> _scripts = {};
  bool isLoading = false;
  NetManager netManager;

  int preloadMode = 0;

  CastLib({
    required this.name,
    required this.number,
    required this.castListEntry,
    this.lctx,
    required this.fileName,
    required this.isLoading,
    required this.netManager,
  });

  bool get isExternal {
    return castListEntry.filePath.isNotEmpty;
  }

  List<Script> get allScripts => _scripts.values.toList();

  Script? getScriptForMember(int memberNumber) {
    var member = findMemberByNumber(memberNumber);
    if (member == null) {
      return null;
    }
    return _scripts[member.localCastNumber];
  }

  setScriptForMember(int memberNumber, Script script) {
    _scripts[memberNumber] = script;
  }

  Future setFileName(String fileName) async {
    if (fileName == this.fileName) {
      return;
    }
    clear();
    this.fileName = fileName;
    await preload();
  }

  Future preload() async {
    if (fileName.isNotEmpty) {
      print("Loading cast $fileName");
      isLoading = true;
      var task = netManager.preloadNetThing(fileName);
      var result = await netManager.awaitNetTask(task);
      onCastPreloadResult(result, task.resolvedUri.toString());
    }
  }

  void clear() {
    _scripts.clear();
    members.clear();
    texts.clear();
    lctx = null;
  }

  void onCastPreloadResult(NetResult result, String loadFileName) {
    if (result is NetResultSuccess) {
      var castBytes = result.bytes;
      var castFile = DirectorFile(getBaseUri(Uri.parse(loadFileName)), loadFileName, Reader(data: castBytes.buffer));
      if (castFile.read()) {
        castFile.parseScripts();

        var castChunk = castFile.casts.first;
        fileName = loadFileName;
        name = basenameWithoutExtension(fileName);
        applyCastChunk(castFile, castChunk);
        print("Loaded $loadFileName");
      } else {
        print("Could not parse $loadFileName");
      }
      isLoading = false;
    } else {
      print("Fetching $loadFileName failed");
    }
  }

  Script scriptChunkToScript(
    DirectorFile dir, 
    ScriptChunk chunk,
    dir_castmembers.ScriptMember dirScriptMember,
  ) {
    return Script(chunk.member!.getName(), chunk, dirScriptMember.scriptType);
  }

  Future applyCastChunk(DirectorFile dir, CastChunk castChunk) async {
    var lctx = castChunk.lctx;
    this.lctx = lctx;
    for (var dirMember in castChunk.members.values) {
      var member = await memberChunkToMember(dir, dirMember.id, dirMember, lctx);
      members[dirMember.id] = member;
    }
  }

  Future<Member> memberChunkToMember(DirectorFile dir, int number, CastMemberChunk chunk, ScriptContextChunk? lctx) async {
    Member result;
    switch (chunk.type) {
    case dir_castmembers.MemberType.kTextMember: {
      var textChunkId = chunk.childrenChunkIds[0];
      var chunkInfo = dir.chunkInfo[textChunkId]!;
      var textChunk = dir.getChunk<TextChunk>(chunkInfo.fourCC, chunkInfo.id);
      result = FieldMember(number: chunk.id, cast: this, text: textChunk.text);
    }
    case dir_castmembers.MemberType.kScriptMember: {
      var dirScriptMember = chunk.member as dir_castmembers.ScriptMember;
      var scriptChunk = lctx!.scripts[chunk.getScriptID()]!;
      var script = scriptChunkToScript(dir, scriptChunk, dirScriptMember);

      setScriptForMember(chunk.id, script);
      result = ScriptMember(number: chunk.id, cast: this, scriptID: chunk.getScriptID(), scriptType: dirScriptMember.scriptType);
    }
    case dir_castmembers.MemberType.kBitmapMember: {
      var specificData = chunk.specificData;
      var specificDataReader = Reader(data: specificData.buffer, endian: dir.endian);

      var abmpChunkId = chunk.childrenChunkIds[0];
      var chunkInfo = dir.chunkInfo[abmpChunkId]!;
      var bitmapChunk = dir.getChunk<BitmapChunk>(chunkInfo.fourCC, chunkInfo.id);
      var bitmapChunkData = dir.getChunkData(chunkInfo.fourCC, chunkInfo.id);
      var bitmapReader = Reader(data: bitmapChunkData, endian: dir.endian);

      var bitmapInfo = BitmapInfo();
      bitmapInfo.read(specificDataReader);
      bitmapChunk.populate(bitmapReader, bitmapInfo);

      var member = BitmapMember(
        number: chunk.id, 
        cast: this, 
        imageRef: ImageRef(
          bitmapChunk.image!, 
          bitmapInfo.bitDepth,
          PaletteRef(bitmapInfo.paletteId)
        ),
        regX: bitmapInfo.regX,
        regY: bitmapInfo.regY,
      );
      result = member;
    }
    default:
      result = Member(number: chunk.id, type: chunk.type, cast: this);
    }
    result.loadFromChunk(chunk);
    return result;
  }

  @override
  Ref<Datum>? getPropRef(String propName) {
    switch (propName) {
      case "preloadMode":
        return MutableCallbackRef(
          get: () => Datum.ofInt(preloadMode),
          set: (value) => preloadMode = value.toInt()
        );
      case "name":
        return MutableCallbackRef(
          get: () => Datum.ofString(name),
          set: (value) => name = value.stringValue() 
        );
      case "fileName":
        return MutableCallbackRef(
          get: () => Datum.ofString(fileName),
          set: (value) => setFileName(value.stringValue())
        );
      case "number":
        return CallbackRef(get: () => Datum.ofInt(number));
      default:
        return null;
    }
  }

  @override
  String toString() {
    return "(castLib $number)";
  }

  Member? findMemberByName(String name) {
    return members.values.where((element) => element.getName().toLowerCase() == name.toLowerCase()).firstOrNull;
  }

  Member? findMemberByNumber(int number) {
    return members.values.where((element) => element.number == number || element.localCastNumber == number).firstOrNull;
  }

  int get firstFreeMemberNumber {
    var maxMember = 5000; // TODO where from?
    for (var i = 1; i <= maxMember; i++) {
      if (!members.containsKey(i)) {
        return i;
      }
    }
    return 0;
  }

  void insertMemberAt(int number, Member member) {
    members[number] = member;
  }

  Member addMemberAt(int number, String type) {
    Member newMember;
    switch (type) {
    case "text":
      newMember = TextMember(number: number, cast: this, text: "");
      break;
    case "field":
      newMember = FieldMember(number: number, cast: this, text: "");
      break;
    case "bitmap":
      newMember = BitmapMember(
        number: number, 
        cast: this, 
        imageRef: ImageRef(
          img.Image(width: 1, height: 1),
          8,
          PaletteRef(BuiltInPalette.grayscale.intValue)
        ), 
        regX: 0, 
        regY: 0
      );
    case "palette":
      newMember = PaletteMember(number: number, cast: this);
    default:
      throw Exception("Cannot create member of type $type");
    }

    members[number] = newMember;
    return newMember;
  }

  void removeMember(int number) {
    members.remove(number);
  }
}
