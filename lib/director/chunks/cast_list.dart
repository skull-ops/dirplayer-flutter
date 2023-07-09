import 'dart:typed_data';

import '../../reader.dart';
import '../chunk.dart';
import '../subchunk.dart';
import 'list.dart';

class CastListChunk extends ListChunk {
  int unk0 = 0;
  int castCount = 0;
	int itemsPerCast = 0;
	int unk1 = 0;
	List<CastListEntry> entries = [];

  CastListChunk({ required super.dir, super.chunkType = ChunkType.kCastListChunk });
  
  @override
  void read(Reader stream, int dirVersion) {
    stream.endian = Endian.big;
    super.read(stream, dirVersion);
    entries = List.generate(castCount, (i) => CastListEntry());
    for (int i = 0; i < castCount; i++) {
      if (itemsPerCast >= 1) {
        entries[i].name = readPascalString(i * itemsPerCast + 1);
      }
      if (itemsPerCast >= 2) {
        entries[i].filePath = readPascalString(i * itemsPerCast + 2);
      }
      if (itemsPerCast >= 3) {
        entries[i].preloadSettings = readUint16(i * itemsPerCast + 3);
      }
      if (itemsPerCast >= 4) {
        Reader item = Reader(data: items[i * itemsPerCast + 4].buffer, endian: itemEndian);
        entries[i].minMember = item.readUint16();
        entries[i].maxMember = item.readUint16();
        entries[i].id = item.readInt32();
      }
    }
  }

  @override
  void readHeader(Reader stream) {
    dataOffset = stream.readUint32();
    unk0 = stream.readUint16();
    castCount = stream.readUint16();
    itemsPerCast = stream.readUint16();
    unk1 = stream.readUint16();
  }
}
