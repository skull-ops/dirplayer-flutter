import 'package:dirplayer/director/chunk.dart';
import 'package:dirplayer/reader.dart';

class InitialMapChunk extends Chunk {
  int version = 0; // always 1
	int mmapOffset = 0;
	int directorVersion = 0;
	int unused1 = 0;
	int unused2 = 0;
	int unused3 = 0;

	InitialMapChunk({ required super.dir, super.chunkType = ChunkType.kInitialMapChunk }) {
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
