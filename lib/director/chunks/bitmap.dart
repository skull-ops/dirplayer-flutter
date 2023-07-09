import 'dart:typed_data';

import 'package:dirplayer/reader.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:logging/logging.dart';

import '../chunk.dart';

class BitmapInfo {
  int width = 0;
  int height = 0;
  int regX = 0;
  int regY = 0;
  int bitDepth = 0;
  int paletteId = 0;

  void read(Reader reader) {
    reader.endian = Endian.big;

    var unk0 = reader.readUint8();
    var unk1 = reader.readUint8(); // Logo -> 16
    var unk3 = reader.readUint32();
    height = reader.readUint16();
    width = reader.readUint16();
    var unk5_0 = reader.readInt16();
    var unk5_1 = reader.readInt16();
    var unk6_0 = reader.readInt16();
    var unk6_1 = reader.readInt16();
    regY = reader.readUint16();
    regX = reader.readUint16();
    var unk9 = reader.readUint8();
    if (reader.eof()) {
      bitDepth = 1;
    } else {
      bitDepth = reader.readUint8();
      var unk10 = reader.readInt16(); // palette?
      paletteId = reader.readInt16() - 1; // TODO why?
    }
  }
}

class BitmapChunk extends Chunk {
  final log = Logger("BitmapChunk");
  img.Image? image;
  BitmapChunk({required super.dir, super.chunkType = ChunkType.kBitmapChunk});

  @override
  void read(Reader stream, int dirVersion) { }

  void populate(Reader stream, BitmapInfo bitmapInfo) {
    var bitmapDebugInfo = "${bitmapInfo.width}x${bitmapInfo.height}x${bitmapInfo.bitDepth}";
    log.finer("Loading bitmap($bitmapDebugInfo)");
    try {
      image = readBitmapBuffer(stream, bitmapInfo.width, bitmapInfo.height, bitmapInfo.bitDepth);
    } catch (err) {
      log.severe("Failed to parse bitmap($bitmapDebugInfo): $err");
      image = img.Image(width: bitmapInfo.width, height: bitmapInfo.height, numChannels: 4, format: img.Format.uint8);
    }
  }

  img.Image decode1bitBitmap(int width, int height, int scanWidth, int scanHeight, Uint8List bitmapValues) {
    // Decodes a 1-bit to 8-bit indexed
    var scanData = Uint8List(bitmapValues.length * 8);
    var p = 0;
    for (var i = 0; i < bitmapValues.length; i++) {
      var originalValue = bitmapValues[i];
      for (var j = 1; j <= 8; j++) {
        var bit = (originalValue & (0x1 << (8 - j))) >> (8 - j);
        scanData[p++] = bit == 1 ? 255 : 0;
      }
    }

    var resultBitmap = Uint8List(width * height);
    for (var y = 0; y < scanHeight; y++) {
      for (var x = 0; x < scanWidth; x++) {
        var scanIndex = (y * scanWidth) + x;
        if (x < width) {
          var resultIndex = (y * width) + x;
          resultBitmap[resultIndex] = scanData[scanIndex];
        }
      }
    }

    return img.Image.fromBytes(
      width: width, 
      height: height, 
      bytes: resultBitmap.buffer,
      numChannels: 1,
      format: img.Format.uint8,
    );
  }

  img.Image decode2bitBitmap(int width, int height, int scanWidth, int scanHeight, Uint8List bitmapValues) {
    // Decodes a 2-bit to 8-bit indexed
    var decodedData = Uint8List(width * height * 4);
    var p = 0;
    for (var i = 0; i < bitmapValues.length; i++) {
      var originalValue = bitmapValues[i];
      var value1 = (originalValue & 0xC0) >> 6;
      var value2 = (originalValue & 0x30) >> 4;
      var value3 = (originalValue & 0x0C) >> 2;
      var value4 = (originalValue & 0x03);

      decodedData[p++] = ((value1.toDouble() / 0x3) * 255.0).toInt();
      decodedData[p++] = ((value2.toDouble() / 0x3) * 255.0).toInt();
      decodedData[p++] = ((value3.toDouble() / 0x3) * 255.0).toInt();
      decodedData[p++] = ((value4.toDouble() / 0x3) * 255.0).toInt();
    }

    var resultBitmap = Uint8List(scanWidth * scanHeight);
    for (var y = 0; y < scanHeight; y++) {
      for (var x = 0; x < scanWidth; x++) {
        var compressedIndex = (y * scanWidth) + x;
        if (x < width) {
          var resultIndex = (y * width) + x;
          resultBitmap[resultIndex] = decodedData[compressedIndex];
        }
      }
    }

    return img.Image.fromBytes(
      width: width, 
      height: height, 
      bytes: resultBitmap.buffer,
      numChannels: 1,
      format: img.Format.uint8,
    );
  }

  img.Image decode4bitBitmap(int width, int height, int scanWidth, int scanHeight, Uint8List bitmapValues) {
    // Decodes a 4-bit to 8-bit indexed
    var decodedData = Uint8List(width * height * 2);
    var p = 0;
    for (var i = 0; i < bitmapValues.length; i++) {
      var originalValue = bitmapValues[i];
      var leftValue = (originalValue & 0xF0) >> 4;
      var rightValue = (originalValue & 0x0F);

      decodedData[p++] = ((leftValue.toDouble() / 0xF) * 255.0).toInt();
      decodedData[p++] = ((rightValue.toDouble() / 0xF) * 255.0).toInt();
    }

    var resultBitmap = Uint8List(scanWidth * scanHeight * 2);
    for (var y = 0; y < scanHeight; y++) {
      for (var x = 0; x < scanWidth; x++) {
        var scanIndex = (y * scanWidth) + x;
        if (x < width) {
          var resultIndex = (y * width) + x;
          resultBitmap[resultIndex] = decodedData[scanIndex];
        }
      }
    }

    return img.Image.fromBytes(
      width: width, 
      height: height, 
      bytes: resultBitmap.buffer,
      numChannels: 1,
      format: img.Format.uint8,
    );
  }

  img.Image decodeGenericBitmap(int width, int height, int scanWidth, int scanHeight, int bitDepth, int numChannels, Uint8List bitmapValues) {
    // TODO the 16bit parsing is broken, look into that
    var bytesPerPixel = bitDepth ~/ 8;
    if (scanWidth * scanHeight * numChannels * bytesPerPixel != bitmapValues.length) {
      print("[!!] warn: Exception Expected ${scanWidth * scanHeight * numChannels * bytesPerPixel} bitmap bytes but got ${bitmapValues.length} (width=$width, height=$height, scanWidth=$scanWidth, scanHeight=$scanHeight, numChannels=$numChannels, bitDepth=$bitDepth)");
      return img.Image.empty();
    }
    var resultBitmap = Uint8List(width * height * numChannels * bytesPerPixel);
    for (var y = 0; y < scanHeight; y++) {
      for (var x = 0; x < scanWidth; x++) {
        for (var c = 0; c < numChannels; c++) {
          for (var b = 0; b < bytesPerPixel; b++) {
            var scanIndex = (y * scanWidth * numChannels * bytesPerPixel) + x + c + b;
            if (x < width) {
              var resultIndex = (y * width * numChannels * bytesPerPixel) + x + c + b;
              resultBitmap[resultIndex] = bitmapValues[scanIndex];
            }
          }
        }
      }
    }

    img.Format format;
    switch (bitDepth) {
    case 8:
      format = img.Format.uint8;
    case 16:
      format = img.Format.uint16;
    default:
      throw Exception("Unknown bitDepth $bitDepth");
    }

    return img.Image.fromBytes(
      width: width, 
      height: height, 
      bytes: resultBitmap.buffer,
      numChannels: numChannels,
      format: format,
    );
  }

  int getNumChannels(int bitDepth) {
    switch (bitDepth) {
    case 1:
    case 2:
    case 4:
    case 8:
    case 16:
      return 1;
    case 32:
      return 4;
    default:
      throw Exception("Unknown bitDepth $bitDepth");
    }
  }

  int getAlignmentWidth(int bitDepth) {
    switch (bitDepth) {
    case 1:
      return 4;
    case 4:
      return 4;
    case 2:
    case 8:
      return 2;
    case 16:
      return 1;
    case 32:
      return 4;
    default:
      throw Exception("Unknown bitDepth $bitDepth");
    }
  }

  img.Image readBitmapBuffer(Reader stream, int width, int height, int bitDepth) {
    // Converts a nuu-encoded image into an 8bit bitmap
    var bitmapValueList = <int>[];
    var currentIndex = 0;
    var numChannels = getNumChannels(bitDepth);
    var alignmentLength = getAlignmentWidth(bitDepth); // 2

    int scanWidth = width;
    int scanHeight = height;
    if (width % alignmentLength == 0) {
      scanWidth = width;
    } else {
      scanWidth = alignmentLength * (width / alignmentLength).ceil();
    }

    if (stream.data.lengthInBytes * 8 == scanWidth * scanHeight * bitDepth) {
      // no compression
      bitmapValueList.addAll(stream.readByteList(stream.data.lengthInBytes - stream.position));
    } else {
      while (!stream.eof()) {
        var rLen = stream.readUint8();
        if (0x101 - rLen > 0x7F) {
          rLen++;
          for (var j = 0; j < rLen; j++) {
            if (stream.eof()) {
              print("error");
            }
            var val = stream.readUint8();
            bitmapValueList.add(0xFF - val);
            currentIndex++;
          }
        } else {
          rLen = 0x101 - rLen;
          var val = stream.readUint8();

          for (var j = 0; j < rLen; j++) {
            bitmapValueList.add(0xFF - val);
            currentIndex++;
          }
        }
      }
    }

    if (bitmapValueList.length == width * height * numChannels) {
      scanWidth = width;
      scanHeight = height;
    } else {
      if (width % alignmentLength == 0) {
        scanWidth = width;
      } else {
        scanWidth = alignmentLength * (width / alignmentLength).ceil();
      }
      scanHeight = height;
    }

    var bitmapValues = Uint8List.fromList(bitmapValueList);
    switch (bitDepth) {
    case 1:
      return decode1bitBitmap(width, height, scanWidth, scanHeight, bitmapValues);
    case 2:
      return decode2bitBitmap(width, height, scanWidth, scanHeight, bitmapValues);
    case 4:
      return decode4bitBitmap(width, height, scanWidth, scanHeight, bitmapValues);
    case 8:
      return decodeGenericBitmap(width, height, scanWidth, scanHeight, 8, 1, bitmapValues);
    case 16:
      return decodeGenericBitmap(width, height, scanWidth, scanHeight, 16, 1, bitmapValues);
    case 32:
      return decodeGenericBitmap(width, height, scanWidth, scanHeight, 8, 4, bitmapValues);
    default:
      throw Exception("Unknown bitDepth $bitDepth");
    }
  }
}
