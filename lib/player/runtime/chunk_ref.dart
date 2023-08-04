import 'dart:math';

import 'package:dirplayer/common/util.dart';
import 'package:dirplayer/director/lingo/chunk_expr_type.dart';
import 'package:dirplayer/player/runtime/wrappers/string.dart';

abstract class StringChunkRef {
  final int startNumber;
  final int endNumber;

  const StringChunkRef(this.startNumber, this.endNumber);
  List<String> getItems(String value);
  String stringValue(String value);

  static StringChunkRef fromChunkType(ChunkExprType chunkType, int start, int end, { String arg = "" }) {
    switch (chunkType) {
      case ChunkExprType.kChunkItem:
        return ItemStringChunkRef(arg, start.toInt(), end.toInt()); 
      case ChunkExprType.kChunkWord:
        return WordStringChunkRef(start.toInt(), end.toInt());
      case ChunkExprType.kChunkChar:
        return CharStringChunkRef(start.toInt(), end.toInt()); 
      case ChunkExprType.kChunkLine:
        return LineStringChunkRef(start.toInt(), end.toInt()); 
      default:
        throw Exception("Invalid string chunk type $chunkType");
    }
  }

  String deletingFrom(String original);
}

class ItemStringChunkRef extends StringChunkRef {
  String itemDelimiter;
  ItemStringChunkRef(this.itemDelimiter, super.startNumber, super.endNumber);
  
  @override
  List<String> getItems(String value) {
    return StringWrapper.getItemChunk(value, itemDelimiter, startNumber, endNumber);
  }
  
  @override
  String stringValue(String value) {
    return getItems(value).join(itemDelimiter);
  }

  @override
  String deletingFrom(String original) {
    throw Exception("Delete not implemented for ItemStringChunkRef");
  }
}

class CharStringChunkRef extends StringChunkRef {
  CharStringChunkRef(super.startNumber, super.endNumber);

  @override
  List<String> getItems(String value) {
    return StringWrapper.getCharChunk(value, startNumber, endNumber);
  }

  @override
  String stringValue(String value) {
    return getItems(value).join();
  }

  @override
  String deletingFrom(String original) {
    var normalizedStart = min(max(startNumber - 1, 0), original.length);
    var normalizedEnd = min(max(endNumber, normalizedStart), original.length);

    var before = original.substring(0, normalizedStart);
    var after = original.substring(normalizedEnd);
    return before + after;
  }
}

class WordStringChunkRef extends StringChunkRef {
  WordStringChunkRef(super.startNumber, super.endNumber);

  @override
  List<String> getItems(String value) {
    return StringWrapper.getWordChunk(value, startNumber, endNumber);
  }

  @override
  String stringValue(String value) {
    return getItems(value).join(" ");
  }

  @override
  String deletingFrom(String original) {
    throw Exception("Delete not implemented for WordStringChunkRef");
  }
}

class LineStringChunkRef extends StringChunkRef {
  LineStringChunkRef(super.startNumber, super.endNumber);

  @override
  List<String> getItems(String value) {
    return StringWrapper.getLineChunk(value, startNumber, endNumber);
  }

  @override
  String stringValue(String value) {
    return getItems(value).join(getLineSeparator());
  }

  @override
  String deletingFrom(String original) {
    throw Exception("Delete not implemented for LineStringChunkRef");
  }
}