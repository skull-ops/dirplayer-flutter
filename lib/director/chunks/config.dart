
import 'dart:typed_data';

import '../../reader.dart';
import '../chunk.dart';
import '../util.dart';

class ConfigChunk extends Chunk {
	/*  0 */ int len = 0;
	/*  2 */ int fileVersion = 0;
	/*  4 */ int movieTop = 0;
	/*  6 */ int movieLeft = 0;
	/*  8 */ int movieBottom = 0;
	/* 10 */ int movieRight = 0;
	/* 12 */ int minMember = 0;
	/* 14 */ int maxMember = 0;
	/* 16 */ int field9 = 0;
	/* 17 */ int field10 = 0;

	// Director 6 and below
		/* 18 */ int preD7field11 = 0;
	// Director 7 and above
		/* 18 */ int D7stageColorG = 0;
		/* 19 */ int D7stageColorB = 0;

	/* 20 */ int commentFont = 0;
	/* 22 */ int commentSize = 0;
	/* 24 */ int commentStyle = 0;

	// Director 6 and below
		/* 26 */ int preD7stageColor = 0;
	// Director 7 and above
		/* 26 */ int D7stageColorIsRGB = 0;
		/* 27 */ int D7stageColorR = 0;

	/* 28 */ int bitDepth = 0;
	/* 30 */ int field17 = 0;
	/* 31 */ int field18 = 0;
	/* 32 */ int field19 = 0;
	/* 36 */ int directorVersion = 0;
	/* 38 */ int field21 = 0;
	/* 40 */ int field22 = 0;
	/* 44 */ int field23 = 0;
	/* 48 */ int field24 = 0;
	/* 52 */ int field25 = 0;
	/* 53 */ int field26 = 0;
	/* 54 */ int frameRate = 0;
	/* 56 */ int platform = 0;
	/* 58 */ int protection = 0;
	/* 60 */ int field29 = 0;
	/* 64 */ int checksum = 0;
	/* 68 */ Uint8List remnants = Uint8List(0);

  ConfigChunk({
    required super.dir,
    super.chunkType = ChunkType.kConfigChunk,
  });

  int computeChecksum() {
    int ver = humanVersion(directorVersion);

    int check = len + 1;
    check *= fileVersion + 2;
    check ~/= movieTop + 3;
    check *= movieLeft + 4;
    check ~/= movieBottom + 5;
    check *= movieRight + 6;
    check -= minMember + 7;
    check *= maxMember + 8;
    check -= field9 + 9;
    check -= field10 + 10;

    int operand11 = 0;
    if (ver < 700) {
      operand11 = preD7field11;
    } else {
      // TODO inverse if incorrect
      operand11 = dir.endian == Endian.little 
        ? ((D7stageColorB << 8) | D7stageColorG).toInt() & 0xFFFF
        : ((D7stageColorG << 8) | D7stageColorB).toInt() & 0xFFFF;
    }
    check += operand11 + 11;
    check *= commentFont + 12;
    check += commentSize + 13;
    
    int operand14 = (ver < 800) ? ((commentSize >> 8) & 0xFF) : commentStyle;
    check *= operand14 + 14;

    int operand15 = (ver < 700) ? preD7stageColor : D7stageColorR;
    check += operand15 + 15;
    check += bitDepth + 16;
    check += field17 + 17;
    check *= field18 + 18;
    check += field19 + 19;
    check *= directorVersion + 20;
    check += field21 + 21;
    check += field22 + 22;
    check += field23 + 23;
    check += field24 + 24;
    check *= field25 + 25;
    check += frameRate + 26;
    check *= platform + 27;
    check *= (protection * 0xE06) + 0xFF450000;
    check ^= FOURCC("ralf");

    return check & 0xFFFFFFFF;
  }

  @override
  void read(Reader stream, int dirVersion) {
    /*var preD7field11 = 0;
    var preD7stageColor = 0;
    var D7stageColorIsRGB = 0;
    var D7stageColorR = 0;
    var D7stageColorG = 0;
    var D7stageColorB = 0;*/

    stream.endian = Endian.big;

    stream.position = 36;
    directorVersion = stream.readInt16();
	  var ver = humanVersion(directorVersion);

    stream.position = 0;
    len = stream.readInt16();
    fileVersion = stream.readInt16();
    movieTop = stream.readInt16();
    movieLeft = stream.readInt16();
    movieBottom = stream.readInt16();
    movieRight = stream.readInt16();
    minMember = stream.readInt16();
    maxMember = stream.readInt16();
    field9 = stream.readInt8();
    field10 = stream.readInt8();
    if (ver < 700) {
		  preD7field11 = stream.readInt16();
    } else {
      D7stageColorG = stream.readUint8();
      D7stageColorB = stream.readUint8();
    }
    commentFont = stream.readInt16();
    commentSize = stream.readInt16();
    commentStyle = stream.readUint16();
    if (ver < 700) {
      preD7stageColor = stream.readInt16();
    } else {
      D7stageColorIsRGB = stream.readUint8();
      D7stageColorR = stream.readUint8();
    }
    bitDepth = stream.readInt16();
    field17 = stream.readUint8();
    field18 = stream.readUint8();
    field19 = stream.readInt32();
    /* directorVersion = */ stream.readInt16();
    field21 = stream.readInt16();
    field22 = stream.readInt32();
    field23 = stream.readInt32();
    field24 = stream.readInt32();
    field25 = stream.readInt8();
    field26 = stream.readUint8();
    frameRate = stream.readInt16();
    platform = stream.readInt16();
    protection = stream.readInt16();
    field29 = stream.readInt32();
    checksum = stream.readUint32();
    remnants = stream.readByteList(len - stream.position);

    int computedChecksum = computeChecksum();
    if (checksum != computedChecksum) {
      print("Checksums don't match! Stored: $checksum Computed: $computedChecksum");
    }
  }

  void unprotect() {
    fileVersion = directorVersion;
    if (protection % 23 == 0) {
      protection += 1;
    }
  }
}
