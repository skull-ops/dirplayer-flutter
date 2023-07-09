import 'dart:typed_data';

import '../castmembers.dart';
import '../chunk.dart';
import '../util.dart';
import '../../reader.dart';

import '../subchunk.dart';
import 'script.dart';
import 'script_names.dart';

class ScriptContextChunk extends Chunk {
  int unknown0 = 0;
	int unknown1 = 0;
	int entryCount = 0;
	int entryCount2 = 0;
	int entriesOffset = 0;
	int unknown2 = 0;
	int unknown3 = 0;
	int unknown4 = 0;
	int unknown5 = 0;
	int lnamSectionID = 0;
	int validCount = 0;
	int flags = 0;
	int freePointer = 0;

  ScriptNamesChunk? lnam;
  List<ScriptContextMapEntry> sectionMap = [];
  Map<int, ScriptChunk> scripts = {};

  ScriptContextChunk({ required super.dir, super.chunkType = ChunkType.kScriptContextChunk });

  List<ScriptChunk> getMovieScripts() {
    return scripts.values.where((element) => 
      element.member!.type == MemberType.kScriptMember 
        && (element.member!.member as ScriptMember).scriptType == ScriptType.kMovieScript
    ).toList();
  }

  @override
  void read(Reader stream, int dirVersion) {
    // Lingo scripts are always big endian regardless of file endianness
    stream.endian = Endian.big;

    unknown0 = stream.readInt32();
    unknown1 = stream.readInt32();
    entryCount = stream.readUint32();
    entryCount2 = stream.readUint32();
    entriesOffset = stream.readUint16();
    unknown2 = stream.readInt16();
    unknown3 = stream.readInt32();
    unknown4 = stream.readInt32();
    unknown5 = stream.readInt32();
    lnamSectionID = stream.readInt32();
    validCount = stream.readUint16();
    flags = stream.readUint16();
    freePointer = stream.readInt16();

    stream.position = entriesOffset;
    sectionMap = List.generate(entryCount, (index) => ScriptContextMapEntry());
    for (var entry in sectionMap) {
      entry.read(stream);
    }

    lnam = dir.getChunk(FOURCC("Lnam"), lnamSectionID) as ScriptNamesChunk;
    for (int i = 1; i <= entryCount; i++) {
      var section = sectionMap[i - 1];
      if (section.sectionID > -1) {
        var script = dir.getChunk(FOURCC("Lscr"), section.sectionID) as ScriptChunk;
        script.setContext(this);
        scripts[i] = script;
      }
    }

    for (var entry in scripts.entries) {
      var script = entry.value;
      if (script.isFactory()) {
        var parent = scripts[script.parentNumber + 1];
        parent!.factories.add(script);
      }
    }
  }
  
  // void ScriptContextChunk::writeJSON(Common::JSONWriter &json) const

  bool validName(int id) {
    return lnam?.validName(id) ?? false;
  }

  String getName(int id) {
    return lnam?.getName(id) ?? "";
  }

  void parseScripts() {
    for (var entry in scripts.entries) {
      entry.value.parse();
    }
  }
}
