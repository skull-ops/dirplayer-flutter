import 'dart:typed_data';
import 'dart:ui';

import 'package:dirplayer/director/chunk.dart';
import 'package:dirplayer/director/chunks/list.dart';
import 'package:dirplayer/reader.dart';

// https://iskrich.wordpress.com
// https://github.com/scummvm-director/continuity
// https://github.com/Earthquake-Project/Format-Documentation/blob/master/imports/doc_schockabsorber/fileformat/section-VWSC.asciidoc
// https://gist.github.com/rvanlaar/d7bd98a23c8c09c9770ab2c7bf4e4e20
// https://github.com/scummvm/scummvm/blob/master/engines/director/score.cpp

class ScoreFrameDelta {
  int offset;
  Uint8List data;

  ScoreFrameDelta(this.offset, this.data);
}

const kChannelDataSize = 38664; // (25 * 50);

class ScoreFrameChannelData {
  int flags = 0;
  int unk0 = 0;
  int castLib = 0;
  int castMember = 0;
  int unk1 = 0;
  int posY = 0;
  int posX = 0;
  int height = 0;
  int width = 0;

  void read(Reader stream) {
    flags = stream.readUint16();
    unk0 = stream.readUint16();
    castLib = stream.readUint16();
    castMember = stream.readUint16();
    unk1 = stream.readUint16();
    posY = stream.readUint16();
    posX = stream.readUint16();
    height = stream.readUint16();
    width = stream.readUint16();
  }
}

class ScoreFrameData {
  int frameCount = 0;
  int framesVersion = 0;
  int _numChannelsDisplayed = 0;
  int spriteRecordSize = 0;
  int numChannels = 0;
  Uint8List uncompressedData = Uint8List(0);

  void read(Reader stream) {
    readHeader(stream);

    Uint8List channelData = Uint8List(frameCount * numChannels * spriteRecordSize);

    while (!stream.eof()) {
      // FDStart
      var fdStart = stream.position;
      var length = stream.readUint16(); // Length of Sprite channel subsection, from FDStart

      if (length == 0) {
        break;
      }

      var frameLength = length - 2;
      if (frameLength > 0) {
        var chunkData = stream.readByteList(length - 2);
        var frameChunkReader = Reader(data: chunkData.buffer, endian: Endian.big);

        while (!frameChunkReader.eof()) {
          var channelSize = frameChunkReader.readUint16();
          var channelOffset = frameChunkReader.readUint16();
          var channelDelta = frameChunkReader.readByteList(channelSize);

          channelData.setRange(channelOffset, channelOffset + channelSize, channelDelta);
        }
      }
    }

    uncompressedData = channelData;

    var channelReader = Reader(data: channelData.buffer, endian: Endian.big);
    for (var i = 0; i < frameCount; i++) {
      for (var j = 0; j < numChannels; j++) {
        var pos = channelReader.position;
        var channelFrameData = ScoreFrameChannelData();
        channelFrameData.read(channelReader);

        channelReader.position = pos + spriteRecordSize;
        if (channelFrameData.flags != 0) {
          print("frame $i channel $j flags=${channelFrameData.flags}");
        }
      }
    }
  }

  void readHeader(Reader stream) {
    var actualLength = stream.readUint32();
    var unk1 = stream.readUint32(); // Header size? (Constant = 20)
    frameCount = stream.readUint32();
    framesVersion = stream.readUint16(); // (Constant = 13) - framesVersion?
    spriteRecordSize = stream.readUint16(); // SpriteByteSize -- the number of bytes per channel per frame (Constant = 48)
    numChannels = stream.readUint16(); // ChannelCount -- the number of sprite channels (typically 1006)
    if (framesVersion > 13) {
      _numChannelsDisplayed = stream.readUint16(); // (Multiple of 10, often of 50)
    } else {
      if (framesVersion <= 7)	{// Director5
				_numChannelsDisplayed = 48;
      } else {
				_numChannelsDisplayed = 120;	// D6
      }

			stream.readUint16(); // Skip
    }
  }
}

class FrameIntervalPrimary {
  int startFrame = 0;
  int endFrame = 0;
  int unk0 = 0;
  int unk1 = 0;
  int spriteNumber = 0;
  int unk2 = 0;
  int unk3 = 0;
  int unk4 = 0;
  int unk5 = 0;
  int unk6 = 0;
  int unk7 = 0;
  int unk8 = 0;

  void read(Reader stream) {
    startFrame = stream.readUint32();
    endFrame = stream.readUint32();
    unk0 = stream.readUint32();
    unk1 = stream.readUint32();
    spriteNumber = stream.readUint32();
    unk2 = stream.readUint16();
    unk3 = stream.readUint32();
    unk4 = stream.readUint16();
    unk5 = stream.readUint32();
    unk6 = stream.readUint32();
    unk7 = stream.readUint32();
    unk8 = stream.readUint32();
  }
}

class FrameIntervalSecondary {
  int castLib = 0;
  int castMember = 0;
  int unk0 = 0;

  void read(Reader stream) {
    castLib = stream.readUint16();
    castMember = stream.readUint16();
    unk0 = stream.readUint32();
  }
}

class ScoreChunk extends Chunk {
  int totalLength = 0;
  int unk1 = 0;
  int unk2 = 0;
  int entryCount = 0;
  int unk3 = 0;
  int entrySizeSum = 0;

  List<Uint8List> entries = [];
  List<FrameIntervalPrimary> frameIntervalPrimaries = [];
  List<FrameIntervalSecondary> frameIntervalSecondaries = [];
  ScoreFrameData? frameData;

  ScoreChunk({ required super.dir }) : super(chunkType: ChunkType.kScoreChunk);

  @override
  void read(Reader stream, int dirVersion) {
    readHeader(stream);

    var offsets = List.generate(entryCount + 1, (i) => stream.readUint32());
    var entries = List.generate(entryCount, (index) {
      var nextOffset = offsets[index + 1];
      var length = nextOffset - offsets[index];

      return stream.readByteList(length);
    });

    var deltaReader = Reader(data: entries[0].buffer, endian: Endian.big);
    frameData = ScoreFrameData();
    frameData!.read(deltaReader);

    var frameIntervalEntries = entries.getRange(3, entries.length).toList();
    //for (var i = 3; i < entryCount; i += 3) {
    for (var i = 0; i < frameIntervalEntries.length; i++) {
      if (frameIntervalEntries[i].isEmpty) {
        continue;
      }
      var isPrimary = i % 3 == 0;
      var isSecondary = i % 3 == 1;
      var isTertiary = i % 3 == 2;

      var frameIntervalReader = Reader(data: frameIntervalEntries[i].buffer, endian: Endian.big);
      if (isPrimary) {
        var frameInterval = FrameIntervalPrimary();
        frameInterval.read(frameIntervalReader);

        frameIntervalPrimaries.add(frameInterval);
      } else if (isSecondary) {
        var frameInterval = FrameIntervalSecondary();
        frameInterval.read(frameIntervalReader);

        frameIntervalSecondaries.add(frameInterval);
      }
    }
  }

  void readHeader(Reader stream) {
    stream.endian = Endian.big;

    totalLength = stream.readUint32();
    unk1 = stream.readUint32(); // Constant = -3
    unk2 = stream.readUint32(); // Constant = 12
    entryCount = stream.readUint32(); 
    unk3 = stream.readUint32(); // Invariant = EntryCount+1
    entrySizeSum = stream.readUint32();
  }
}
