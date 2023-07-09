import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dirplayer/director/castmembers.dart' as dir_castmembers;
import 'package:dirplayer/director/chunks/bitmap.dart';
import 'package:dirplayer/director/chunks/cast.dart';
import 'package:dirplayer/director/chunks/cast_member.dart';
import 'package:dirplayer/director/chunks/script_context.dart';
import 'package:dirplayer/director/chunks/text.dart';
import 'package:dirplayer/director/file.dart';
import 'package:dirplayer/director/lingo/datum.dart';
import 'package:dirplayer/player/runtime/bitmap/bitmap_utils.dart';
import 'package:dirplayer/player/runtime/cast_member.dart';
import 'package:dirplayer/player/runtime/castlib.dart';
import 'package:dirplayer/player/runtime/image_ref.dart';
import 'package:dirplayer/player/runtime/net_manager.dart';
import 'package:dirplayer/player/runtime/net_task.dart';
import 'package:dirplayer/player/runtime/palette_ref.dart';
import 'package:dirplayer/player/runtime/score.dart';
import 'package:dirplayer/reader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;

import '../../director/chunks/script.dart';
import 'script.dart';

enum CastPreloadType {
  whenNeeded,
  afterFrameOne,
  beforeFrameOne,
}

class CastManager with ChangeNotifier {
  final List<CastLib> casts = [];

  ScriptChunk? getScriptChunk(int castLib, int castMember) {
    var cast = casts[castLib - 1];
    return cast.lctx?.scripts.values.where((element) => element.member!.id == castMember).firstOrNull;
  }

  Script? getScript(String memberName) {
    var member = findMemberOfType(
      dir_castmembers.MemberType.kScriptMember, 
      memberName,
    ) as ScriptMember?;
    //var script = member != null ? member.cast.scripts[member.scriptID] : null;
  
    Script? script;
    if (member != null) {
      script = member.cast.getScriptForMember(member.localCastNumber);
    }

    assert(member?.getName() == script?.name);

    return script;
  }

  CastLib? castLib(int number) {
    return casts.elementAtOrNull(number - 1);
  }

  List<Script> getMovieScripts() {
    var result = <Script>[];
    for (var cast in casts) {
      for (var script in cast.allScripts) {
        if (script.scriptType == dir_castmembers.ScriptType.kMovieScript) {
          result.add(script);
        }
      }
    }
    return result;
  }

  Future initFromFile(DirectorFile dir, NetManager netManager) async {
    var dirPathUri = dir.basePath;
    if (!kIsWeb || dirPathUri.host.isNotEmpty) {
      netManager.basePath = dirPathUri;
    }
    var castListChunk = dir.getCastListChunk();
    if (castListChunk != null) {
      var mappedCasts = <CastLib>[];
      for (var entry in castListChunk.entries.indexed) {
        var (index, castListEntry) = entry;
        var castChunk = dir.getCastChunkForCastId(castListEntry.id);
        var cast = CastLib(
          name: castListEntry.name,
          fileName: normalizeCastLibPath(netManager.basePath, castListEntry.filePath)?.toString() ?? "",
          number: index + 1,
          castListEntry: castListEntry,
          isLoading: castChunk == null,
          netManager: netManager,
        );
        if (castChunk != null) {
          await cast.applyCastChunk(dir, castChunk);
        }
        mappedCasts.add(cast);
      }
      casts.addAll(mappedCasts);
    }
    preloadCasts(netManager);
  }

  Uri? normalizeCastLibPath(Uri basePath, String filePath) {
    if (filePath.isEmpty) {
      return null;
    }
    var slashNormalized = filePath.replaceAll("\\", "/");
    var fileBaseName = slashNormalized.split("/").last;
    var fileBaseNameWithoutExt = fileBaseName.split(".").getRange(0, fileBaseName.split(".").length - 1).join(".");
    var castFileName = "$fileBaseNameWithoutExt.cct";

    return basePath.resolve(castFileName);
  }

  Future preloadCasts(NetManager netManager) async {
    for (var cast in casts) {
      if (cast.isLoading && cast.fileName.isNotEmpty) {
        // TODO: wait until finish depending on preload mode
        cast.preload().then((value) => notifyListeners());
      }
    }
  }

  CastLib? getCastByName(String name) {
    return casts.where((element) => element.name.toLowerCase() == name.toLowerCase()).firstOrNull;
  }

  CastLib? getCastByNumber(int number)  {
    return casts.elementAtOrNull(number - 1);
  }

  Member? findMemberForScript(Script script) {
    for (var cast in casts) {
      for (var member in cast.members.values) {
        if (member is ScriptMember && cast.getScriptForMember(member.number) == script) {
          return member;
        }
      }
    }
    return null;
  }

  Member? findMember(bool Function(Member member) predicate) {
    for (var cast in casts) {
      var member = cast.members.values
        .where(predicate)
        .firstOrNull;
      if (member != null) {
        return member;
      }
    }
    return null;
  }

  Member? findMemberOfType(dir_castmembers.MemberType type, String name) {
    for (var cast in casts) {
      var member = cast.members.values
        .where((element) => element.type == type && element.getName().toLowerCase() == name.toLowerCase())
        .firstOrNull;
      if (member != null) {
        return member;
      }
    }
    return null;
  }

  Member? findMemberByName(String name) {
    return findMember((member) => member.getName() == name);
  }

  Member? findMemberByNumber(int number) {
    return findMember((member) => member.number == number || member.localCastNumber == number);
  }

  Member? findMemberByRef(CastMemberReference ref) {
    CastLib? cast;
    if (ref.castLib > 0) {
      cast = getCastByNumber(ref.castLib);
    }

    var member = cast != null 
      ? cast.findMemberByNumber(ref.castMember)
      : findMemberByNumber(ref.castMember);
    return member;
  }

  Member? findMemberByIdentifiers(Datum memberNameOrNum, Datum? castNameOrNum) {
    CastLib? cast;
    Member? member;

    if (castNameOrNum != null && castNameOrNum.isString()) {
      cast = getCastByName(castNameOrNum.stringValue());
    } else if (castNameOrNum != null && castNameOrNum.isNumber() && castNameOrNum.toInt() > 0) {
      cast = getCastByNumber(castNameOrNum.toInt());
    } else if (castNameOrNum != null && !castNameOrNum.isInt()) {
      throw Exception("Cast number or name invalid: $castNameOrNum");
    }

    if (memberNameOrNum.isString()) {
      member = cast != null 
        ? cast.findMemberByName(memberNameOrNum.stringValue())
        : findMemberByName(memberNameOrNum.stringValue());
    } else if (memberNameOrNum.isNumber()) {
      member = cast != null 
        ? cast.findMemberByNumber(memberNameOrNum.toInt())
        : findMemberByNumber(memberNameOrNum.toInt());
    } else {
      throw Exception("Member number or name invalid: $castNameOrNum");
    }

    if (member != null) {
      return member;
    } else {
      print("[!!] warn: Cast member not found (member: $memberNameOrNum cast: $castNameOrNum)");
      return null;
    }
  }

  String getFieldValue(DirectorFile file, String fieldName) {
    var member = findMemberOfType(dir_castmembers.MemberType.kTextMember, fieldName);
    if (member == null) {
      throw Exception("Cast member not found $fieldName");
    }
    if (member is FieldMember) {
      return member.text;
    } else {
      throw Exception("Cast member is not a field");
    }
  }

  String getFieldValueByIdentifiers(Datum memberNameOrNum, Datum castNameOrNum) {
    var member = findMemberByIdentifiers(memberNameOrNum, castNameOrNum);
    if (member == null) {
      throw Exception("Cast member not found $memberNameOrNum (castLib $castNameOrNum)");
    }
    if (member is FieldMember) {
      return member.text;
    } else {
      throw Exception("Cast member is not a field");
    }
  }

  void removeMemberWithRef(CastMemberReference ref) {
    assert(ref.castLib != 0);
    CastLib? cast = getCastByNumber(ref.castLib);
    cast?.removeMember(ref.castMember);
  }
}
