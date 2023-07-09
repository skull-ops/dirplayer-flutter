import 'dart:typed_data';

import 'package:archive/archive.dart' as archive;
import 'package:archive/archive_io.dart' as archive_io;
import 'package:flutter/foundation.dart';

var zlib = kIsWeb ? const archive.ZLibDecoder() : const archive_io.ZLibDecoder();

class Reader {
  ByteBuffer data;
  int position = 0;
  Endian endian;

  Reader({ required this.data, this.endian = Endian.big });

  ByteData readBytes(int n) {
    if (position + n > data.lengthInBytes) {
      throw Exception("Reading too far");
    }
    var result = data.asByteData(position, n);
    position += n;

    return result;
  }

  Uint8List readByteList(int n) {
    if (position + n > data.lengthInBytes) {
      throw Exception("Reading too far");
    }
    var result = data.asUint8List(position, n);
    position += n;

    return Uint8List.fromList(result);
  }

  int readUint8() {
    return readBytes(1).getUint8(0);
  }

  int readInt8() {
    return readBytes(1).getInt8(0);
  }

  int readUint16() {
    return readBytes(2).getUint16(0, endian);
  }

  int readInt16() {
    return readBytes(2).getInt16(0, endian);
  }

  int readUint32() {
    return readBytes(4).getUint32(0, endian);
  }

  int readInt32() {
    return readBytes(4).getInt32(0, endian);
  }

  int readUint64() {
    return readBytes(8).getUint64(0, endian);
  }

  int readVarInt() {
    int val = 0;
    int b;
    do {
      b = readUint8();
      val = (val << 7) | (b & 0x7f); // The 7 least significant bits are appended to the result
    } while (b >> 7 > 0); // If the most significant bit is 1, there's another byte after
    return val;
  }

  double readDouble() {
    /*var p = position;
    position += 4;
    if (pastEOF()) {
      throw Exception("ReadStream::readDouble: Read past end of stream!");
    }*/

    // TODO check if this is right
    return readBytes(4).getFloat32(0);

    /*var f64bin = endian == Endian.little
      ? load_little_u64(&_data[p])
      : load_big_u64(&_data[p]);

    return *(double *)(&f64bin);*/
  }

  double readAppleFloat80() {
    // Adapted from @moralrecordings' code
    // from engines/director/lingo/lingo-bytecode.cpp in ScummVM

    // Floats are stored as an "80 bit IEEE Standard 754 floating
    // point number (Standard Apple Numeric Environment [SANE] data type
    // Extended).

    //var p = position;
    var data = readBytes(10);
    /*position += 10;
    if (pastEOF()) {
      throw Exception("ReadStream::readAppleFloat80: Read past end of stream!");
    }*/

    int exponent = data.getUint16(0); //boost::endian::load_big_u16(&_data[p]);
    BigInt f64sign = BigInt.from(exponent & 0x8000) << 48;
    exponent &= 0x7fff;
    BigInt fraction = BigInt.from(data.getUint64(2)); //boost::endian::load_big_u64(&_data[p + 2]);
    fraction &= BigInt.parse("0x7fffffffffffffff");//ULL;
    BigInt f64exp = BigInt.zero;
    if (exponent == 0) {
      f64exp = BigInt.zero;
    } else if (exponent == 0x7fff) {
      f64exp = BigInt.from(0x7ff);
    } else {
      BigInt normexp = BigInt.from(exponent & 0xFFFFFFFF) - BigInt.from(0x3fff);
      if ((BigInt.from(-0x3fe) > normexp) || (normexp >= BigInt.from(0x3ff))) {
        throw Exception("Constant float exponent too big for a double");
      }
      f64exp = (normexp + BigInt.from(0x3ff));
    }
    f64exp <<= 52;
    BigInt f64fract = fraction >> 11;
    BigInt f64bin = f64sign | f64exp | f64fract;

    // TODO check if this works
    return Int64List.fromList([f64bin.toInt()])
      .buffer
      .asFloat64List()
      .first;
    
    //return *(double *)(&f64bin);
  }

  String readString(int n) {
    if (position + n > data.lengthInBytes) {
      throw Exception("Reading too far");
    }
    var result = data.asUint8List(position, n);
    position += n;

    return String.fromCharCodes(result);
  }

  String readPascalString() {
    var len = readUint8();
    return readString(len);
  }

  String readCString() {
    var result = "";
    int ch = readUint8();
    while (ch != 0) {
      result += String.fromCharCode(ch);
      ch = readUint8();
    }

    return result;
  }

  bool pastEOF() {
    return position > data.lengthInBytes;
  }

  bool eof() {
    return position >= data.lengthInBytes;
  }

  Uint8List readZlibBytes(int len) {
    var bytes = readByteList(len);
    return Uint8List.fromList(zlib.decodeBytes(bytes));
  }
}
