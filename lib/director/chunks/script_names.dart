import 'dart:typed_data';

import 'package:dirplayer/reader.dart';

import '../chunk.dart';

class ScriptNamesChunk extends Chunk {
	int unknown0 = 0;
	int unknown1 = 0;
	int len1 = 0;
	int len2 = 0;
	int namesOffset = 0;
	int namesCount = 0;
	List<String> names = [];

	ScriptNamesChunk({ required super.dir, super.chunkType = ChunkType.kScriptNamesChunk });
  
  @override
  void read(Reader stream, int dirVersion) {
    // Lingo scripts are always big endian regardless of file endianness
    stream.endian = Endian.big;

    unknown0 = stream.readInt32();
    unknown1 = stream.readInt32();
    len1 = stream.readUint32();
    len2 = stream.readUint32();
    namesOffset = stream.readUint16();
    namesCount = stream.readUint16();

    stream.position = namesOffset;
    names = List.generate(namesCount, (index) => stream.readPascalString());
  }

	bool validName(int id) {
    return -1 < id && id < names.length;
  }

	String getName(int id) {
    if (validName(id)) {
      return names[id];
    }
    return "UNKNOWN_NAME_$id";
  }

	//virtual void writeJSON(Common::JSONWriter &json) const;
}
