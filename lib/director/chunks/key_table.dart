
import '../../reader.dart';
import '../chunk.dart';
import '../subchunk.dart';

class KeyTableChunk extends Chunk {
  int /* int16 */ entrySize = 0; // Should always be 12 (3 uint32's)
	int /* int16 */ entrySize2 = 0;
	int entryCount = 0;
	int usedCount = 0;
	List<KeyTableEntry> entries = [];

  KeyTableChunk({
    required super.dir,
    super.chunkType = ChunkType.kKeyTableChunk,
  });

  @override
  void read(Reader stream, int dirVersion) {
    entrySize = stream.readUint16();
    entrySize2 = stream.readUint16();
    entryCount = stream.readUint32();
    usedCount = stream.readUint32();
    entries = List.generate(entryCount, (index) => KeyTableEntry.fromReader(stream));
  }
}
