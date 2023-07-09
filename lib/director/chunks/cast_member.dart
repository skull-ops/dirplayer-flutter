import 'dart:typed_data';

import '../../reader.dart';
import '../castmembers.dart';
import '../chunk.dart';
import 'cast_info.dart';
import 'script.dart';

class CastMemberChunk extends Chunk {
  MemberType type = MemberType.kNullMember;
  int infoLen = 0;
  int specificDataLen = 0;
  CastInfoChunk? info;
  Uint8List specificData = Uint8List.fromList([]);
  CastMember? member;
  bool hasFlags1 = false;
  int flags1 = 0;
  int id = 0;
  ScriptChunk? script;

  List<int?> childrenChunkIds = [];

  CastMemberChunk({
    required super.dir,
    super.chunkType = ChunkType.kCastMemberChunk,
  });

  @override
  void read(Reader stream, int dirVersion) {
    stream.endian = Endian.big;

    if (dir.version >= 500) {
      type = MemberType.fromValue(stream.readUint32());
      infoLen = stream.readUint32();
      specificDataLen = stream.readUint32();

      // info
      if (infoLen != 0) {
        var infoStream = Reader(data: stream.readByteList(infoLen).buffer, endian: stream.endian);
        info = CastInfoChunk(dir: dir);
        info!.read(infoStream, dirVersion);
      }

      // specific data
      hasFlags1 = false;
      specificData = stream.readByteList(specificDataLen);
    } else {
      specificDataLen = stream.readUint16();
      infoLen = stream.readUint32();

      // these bytes are common but stored in the specific data
      int specificDataLeft = specificDataLen;
      type = MemberType.fromValue(stream.readUint8());
      specificDataLeft -= 1;
      if (specificDataLeft != 0) {
        hasFlags1 = true;
        flags1 = stream.readUint8();
        specificDataLeft -= 1;
      } else {
        hasFlags1 = false;
      }

      // specific data
      specificData = stream.readByteList(specificDataLeft);

      // info
      var infoStream = Reader(data: stream.readByteList(infoLen).buffer, endian: stream.endian);
      if (infoLen != 0) {
        info = CastInfoChunk(dir: dir);
        info!.read(infoStream, dirVersion);
      }
    }

    switch (type) {
    case MemberType.kScriptMember:
      member = ScriptMember(dir);
      break;
    default:
      member = CastMember(dir: dir, type: type);
      break;
    }
    var specificStream = Reader(data: specificData.buffer, endian: stream.endian);
    member!.read(specificStream);
  }

  int size() {
    infoLen = info!.size() ?? 0;
    specificDataLen = specificData.lengthInBytes;

    int len = 0;
    if (dir.version >= 500) {
      len += 4; // type
      len += 4; // infoLen
      len += 4; // specificDataLen
      len += infoLen; // info
      len += specificDataLen; // specificData
    } else {
      specificDataLen += 1; // type
      if (hasFlags1) {
        specificDataLen += 1; // flags1
      }

      len += 2; // specificDataLen
      len += 4; // infoLen
      len += specificDataLen; // specificData
      len += infoLen; // info
    }
    return len;
  }

	/*virtual void write(Common::WriteStream &stream);
	virtual void writeJSON(Common::JSONWriter &json) const;
  */
	int getScriptID() {
    return info?.scriptId ?? 0;
  }

	String getScriptText() {
    return info?.scriptSrcText ?? "";
  }

	void setScriptText(String val) {
    if (info == null) {
      print("Tried to set scriptText on member with no info!");
      return;
    }
    info?.scriptSrcText = val;
  }

	String getName() {
    return info?.name ?? "";
  }
}
