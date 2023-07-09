import '../reader.dart';
import 'lingo/datum.dart';

class CastListEntry {
  String name;
  String filePath;
  int preloadSettings;
  int minMember;
  int maxMember;
  int id;

  CastListEntry({
    this.name = "",
    this.filePath = "",
    this.preloadSettings = 0,
    this.minMember = 0,
    this.maxMember = 0,
    this.id = 0
  });

  // void writeJSON(Common::JSONWriter &json) const;
}

class MemoryMapEntry {
  int fourCC = 0;
	int len = 0;
	int offset = 0;
	int flags = 0;
	int unknown0 = 0;
	int next = 0;

	void read(Reader stream) {
    throw Exception("TODO");
  }
	//void write(Common::WriteStream &stream);
	//void writeJSON(Common::JSONWriter &json) const;
}

class ScriptContextMapEntry {
  int unknown0 = 0;
	int sectionID = 0;
	int unknown1 = 0;
	int unknown2 = 0;

	void read(Reader stream) {
    unknown0 = stream.readInt32();
    sectionID = stream.readInt32();
    unknown1 = stream.readUint16();
    unknown2 = stream.readUint16();
  }

	// void writeJSON(Common::JSONWriter &json) const;
}

enum LiteralType {
  kLiteralInvalid(0),
	kLiteralString(1),
	kLiteralInt(4),
	kLiteralFloat(9);

  const LiteralType(this.rawValue);
  final int rawValue;
  static LiteralType fromRawValue(int value) {
    return LiteralType.values.firstWhere((element) => element.rawValue == value);
  }
}

class KeyTableEntry {
  int sectionID;
  int castID;
  int fourCC;

  KeyTableEntry({ required this.sectionID, required this.castID, required this.fourCC });

  static KeyTableEntry fromReader(Reader stream) {
    return KeyTableEntry(
      sectionID: stream.readInt32(),
      castID: stream.readInt32(),
      fourCC: stream.readUint32()
    );
  }
}

class LiteralStore {
  LiteralType type = LiteralType.kLiteralInvalid;
  int offset = 0;
  Datum? value;

  void readRecord(Reader stream, int version) {
    if (version >= 500) {
      type = LiteralType.fromRawValue(stream.readUint32());
    } else {
      type = LiteralType.fromRawValue(stream.readUint16());
    }
    offset = stream.readUint32();
  }

	void readData(Reader stream, int startOffset) {
    if (type == LiteralType.kLiteralInt) {
      value = Datum.ofInt(offset);
    } else {
      stream.position = startOffset + offset;
      var length = stream.readUint32();
      if (type == LiteralType.kLiteralString) {
        value = Datum.ofString(stream.readString(length - 1));
      } else if (type == LiteralType.kLiteralFloat) {
        double floatVal = 0.0;
        if (length == 8) {
          floatVal = stream.readDouble();
        } else if (length == 10) {
          floatVal = stream.readAppleFloat80();
        }
        value = Datum.ofFloat(floatVal);
      } else {
        value = Datum.ofVoid();
      }
    }
  }
	//void writeJSON(Common::JSONWriter &json) const;
}