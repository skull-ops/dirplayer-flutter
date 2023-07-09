import 'dart:typed_data';

import '../../reader.dart';
import '../chunk.dart';

class ListChunk extends Chunk {
  int dataOffset = 0;
  int offsetTableLen = 0;
  List<int> offsetTable = [];
  int itemsLen = 0;
  Endian itemEndian = Endian.big;
  List<Uint8List> items = [];

  ListChunk({ required super.dir, required super.chunkType });
  
  @override
  void read(Reader stream, int dirVersion) {
    readHeader(stream);
    readOffsetTable(stream);
    readItems(stream);
  }

  void readHeader(Reader stream) {
    dataOffset = stream.readUint32();
  }

  void readOffsetTable(Reader stream) {
    stream.position = dataOffset;
    offsetTableLen = stream.readUint16();
    offsetTable = List.generate(offsetTableLen, (index) => stream.readUint32());
  }

  void readItems(Reader stream) {
    itemsLen = stream.readUint32();

    itemEndian = stream.endian;
    int listOffset = stream.position;

    items = List.generate(offsetTableLen, (i) {
      int offset = offsetTable[i];
      int nextOffset = (i == offsetTableLen - 1) ? itemsLen : offsetTable[i + 1];
      stream.position = listOffset + offset;

      return stream.readByteList(nextOffset - offset);
    });
  }

  String readString(int index) {
    if (index >= offsetTableLen) {
      return "";
    }

    Reader stream = Reader(data: items[index].buffer, endian: itemEndian);
    return stream.readString(stream.data.lengthInBytes);
  }

  String readPascalString(int index) {
    if (index >= offsetTableLen) {
      return "";
    }

    Reader stream = Reader(data: items[index].buffer, endian: itemEndian);
    if (stream.data.lengthInBytes == 0) {
      return "";
    }

    return stream.readPascalString();
  }

  int readUint16(int index) {
    if (index >= offsetTableLen) {
      return 0;
    }

    Reader stream = Reader(data: items[index].buffer, endian: itemEndian);
    return stream.readUint16();
  }

  int readUint32(int index) {
    if (index >= offsetTableLen) {
      return 0;
    }

    Reader stream = Reader(data: items[index].buffer, endian: itemEndian);
    return stream.readUint32();
  }

  void updateOffsets() {
    int offset = 0;
    for (int i = 0; i < offsetTableLen; i++) {
      offsetTable[i] = offset;
      offset += itemSize(i);
    }
    itemsLen = offset;
  }

  int size() {
    int len = 0;
    len += headerSize();
    len += offsetTableSize();
    len += itemsSize();
    return len;
  }

  int headerSize() => 4;
  int offsetTableSize() {
    int len = 0;
    len += 2; // offsetTableLen
    len += 4 * offsetTableLen; // offset table
    return len;
  }
  int itemsSize() {
    updateOffsets();
    int len = 0;
    len += 4; // itemsLen
    len += itemsLen; // items
    return len;
  }

  int itemSize(int index) {
    return items[index].lengthInBytes;
  }
}
