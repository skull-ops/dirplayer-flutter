import 'package:dirplayer/director/chunk.dart';
import 'package:dirplayer/director/chunks/list.dart';
import 'package:dirplayer/reader.dart';

class CastInfoChunk extends ListChunk {
	int unk1 = 0;
	int unk2 = 0;
	int flags = 0;
	int scriptId = 0;

	String scriptSrcText = "";
	String name = "";
	// cProp02;
	// cProp03;
	// std::string comment;
	// cProp05;
	// cProp06;
	// cProp07;
	// cProp08;
	// xtraGUID;
	// cProp10;
	// cProp11;
	// cProp12;
	// cProp13;
	// cProp14;
	// cProp15;
	// std::string fileFormatID;
	// uint32_t created;
	// uint32_t modified;
	// cProp19;
	// cProp20;
	// imageCompression;

	CastInfoChunk({ required super.dir, super.chunkType = ChunkType.kCastInfoChunk }) {
		writable = true;
	}

  @override
	void read(Reader stream, int dirVersion) {
    super.read(stream, dirVersion);
    scriptSrcText = readString(0);
    name = readPascalString(1);
    // cProp02 = readProperty(2);
    // cProp03 = readProperty(3);
    // comment = readString(4);
    // cProp05 = readProperty(5);
    // cProp06 = readProperty(6);
    // cProp07 = readProperty(7);
    // cProp08 = readProperty(8);
    // xtraGUID = readProperty(9);
    // cProp10 = readProperty(10);
    // cProp11 = readProperty(11);
    // cProp12 = readProperty(12);
    // cProp13 = readProperty(13);
    // cProp14 = readProperty(14);
    // cProp15 = readProperty(15);
    // fileFormatID = readString(16);
    // created = readUint32(17);
    // modified = readUint32(18);
    // cProp19 = readProperty(19);
    // cProp20 = readProperty(20);
    // imageCompression = readProperty(21);
    if (offsetTableLen == 0) { // Workaround: Increase table len to have at least one entry for decompilation results
      offsetTableLen = 1;
      offsetTable = List.filled(offsetTableLen, 0);
    }
  }

	@override
  void readHeader(Reader stream) {
    dataOffset = stream.readUint32();
    unk1 = stream.readUint32();
    unk2 = stream.readUint32();
    flags = stream.readUint32();
    scriptId = stream.readUint32();
  }
	/*virtual size_t headerSize();
	virtual void writeHeader(Common::WriteStream &stream);
	virtual size_t itemSize(uint16_t index);
	virtual void writeItem(Common::WriteStream &stream, uint16_t index);
	virtual void writeJSON(Common::JSONWriter &json) const;*/
}