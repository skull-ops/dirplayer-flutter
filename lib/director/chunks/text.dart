import 'dart:typed_data';

import 'package:dirplayer/reader.dart';

import '../chunk.dart';

class TextChunk extends Chunk {
  int offset = 0;
  int textLength = 0;
  int dataLength = 0;
  String text = "";
  Uint8List data = Uint8List(0);

  TextChunk({required super.dir, super.chunkType = ChunkType.kTextChunk});

  @override
  void read(Reader stream, int dirVersion) {
    stream.endian = Endian.big;
    
    offset = stream.readUint32();
    if (offset != 12) {
      throw Exception("Stxt init: unhandled offset");
    }

    textLength = stream.readUint32();
    dataLength = stream.readUint32();
    text = stream.readString(textLength);
    data = stream.readByteList(dataLength);
  }
}