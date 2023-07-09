import 'package:dirplayer/director/file.dart';
import 'package:dirplayer/reader.dart';

enum ChunkType {
	kCastChunk,
	kCastListChunk,
	kCastMemberChunk,
	kCastInfoChunk,
	kConfigChunk,
	kInitialMapChunk,
	kKeyTableChunk,
	kMemoryMapChunk,
	kScriptChunk,
	kScriptContextChunk,
	kScriptNamesChunk,
  kScoreChunk,
  kTextChunk,
  kBitmapChunk,
}

abstract class Chunk {
  DirectorFile dir;
  ChunkType chunkType;
  bool writable;

  Chunk({ required this.dir, required this.chunkType, this.writable = false });
  void read(Reader stream, int dirVersion);

  /*
  	virtual void read(Common::ReadStream &stream) = 0;
	virtual size_t size() { return 0; }
	virtual void write(Common::WriteStream&) {}
	virtual void writeJSON(Common::JSONWriter &json) const;
  */
}
