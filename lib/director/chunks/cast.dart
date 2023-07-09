import 'dart:typed_data';

import 'package:dirplayer/director/util.dart';
import 'package:logging/logging.dart';

import '../../reader.dart';
import '../chunk.dart';
import 'cast_member.dart';
import 'script_context.dart';

class CastChunk extends Chunk {
  static final log = Logger("CastChunk");
  List<int> memberIDs = [];
  String name = "";
  Map<int, CastMemberChunk> members = {};
  ScriptContextChunk? lctx;

  CastChunk({
    required super.dir,
    super.chunkType = ChunkType.kCastChunk,
  });

  @override
  void read(Reader stream, int dirVersion) {
    stream.endian = Endian.big;
    while (!stream.eof()) {
      var id = stream.readInt32();
      memberIDs.add(id);
    }
  }

  void populate(String castName, int id, int minMember) {
    name = castName;

    for (var entry in dir.keyTable!.entries) {
      if (entry.castID == id
              && (entry.fourCC == FOURCC("Lctx") || entry.fourCC == FOURCC("LctX"))
              && dir.chunkExists(entry.fourCC, entry.sectionID)) {
        lctx = dir.getChunk(entry.fourCC, entry.sectionID) as ScriptContextChunk;
        break;
      }
    }

    for (int i = 0; i < memberIDs.length; i++) {
      int sectionID = memberIDs[i];
      if (sectionID > 0) {
        var member = dir.getChunk(FOURCC("CASt"), sectionID) as CastMemberChunk;
        var children = dir.getChildrenOfChunk(sectionID);

        member.id = i + minMember;
        log.fine("Member ${member.id} name: \"${member.getName()}\" chunk: $sectionID children: ${children.length}");

        if (member.info == null) {
          log.warning("Member ${member.id}: No info!");
        }
        if (lctx != null && lctx!.scripts.containsKey(member.getScriptID())) {
          member.script = lctx!.scripts[member.getScriptID()];
          member.script!.member = member;
        }

        member.childrenChunkIds = children.map((e) => e?.id).toList();
        members[member.id] = member;
      }
    }
  }

  /*
	virtual void writeJSON(Common::JSONWriter &json) const;
  */
}

