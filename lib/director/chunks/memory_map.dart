import 'package:dirplayer/director/chunk.dart';
import 'package:dirplayer/reader.dart';

import '../subchunk.dart';

class MemoryMapChunk extends Chunk {
  int headerLength = 0; // should be 24
	int entryLength = 0; // should be 20
	int chunkCountMax = 0;
	int chunkCountUsed = 0;
	int junkHead = 0;
	int junkHead2 = 0;
	int freeHead = 0;
	List<MemoryMapEntry> mapArray = [];

	MemoryMapChunk({ required super.dir, super.chunkType = ChunkType.kMemoryMapChunk }) {
		writable = true;
	}

  @override
	void read(Reader stream, int dirVersion) {
    throw Exception("TODO");
  }
	/*virtual size_t size();
	virtual void write(Common::WriteStream &stream);
	virtual void writeJSON(Common::JSONWriter &json) const;*/
}
