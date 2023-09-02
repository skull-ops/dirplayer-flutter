import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dirplayer/director/lingo/chunk_expr_type.dart';
import 'package:dirplayer/director/lingo/datum/string.dart';
import 'package:dirplayer/director/lingo/datum/string_chunk.dart';
import 'package:dirplayer/player/runtime/chunk_ref.dart';
import 'package:dirplayer/player/runtime/vm.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../director/lingo/datum.dart';

class StringWrapper {
  static List<String> getChunks(String value, ChunkExprType chunkType, String itemDelimiter) {
    switch (chunkType) {
      case ChunkExprType.kChunkChar:
        return value.characters.toList();
      case ChunkExprType.kChunkItem:
        return StringWrapper.getItems(value, itemDelimiter);
      case ChunkExprType.kChunkLine:
        return StringWrapper.getLines(value);
      case ChunkExprType.kChunkWord:
        return StringWrapper.getWords(value);
      default:
        throw Exception("Invalid string chunk type $chunkType");
      }
  }

  static int getCount(String value, String operand, String delimiter) {
    switch (operand) {
      case "char":
        return value.length;
      case "item":
        return getItems(value, delimiter).length;
      case "word":
        return value.isEmpty ? 0 : getWords(value).length;
      case "line":
        return getLines(value).length;
      default:
        throw Exception("Getting count of invalid operand from string: $operand");
    }
  }

  static List<String> getLines(String value) {
    return LineSplitter.split(value).toList();
  }

  static List<String> getWords(String value) {
    return value.split(RegExp("\\s")).where((element) => element.isNotEmpty).toList();
  }

  static List<String> getItems(String value, String itemDelimiter) {
    return value.split(itemDelimiter).toList();
  }

  static (int, int) vmRangeToHost((int, int) range, int maxLength) {
    var (start, end) = range;
    var startIndex = max(0, start - 1);
    int endIndex;
    if (end == 0) {
      endIndex = startIndex + 1;
    } else if (end == -1) {
      endIndex = maxLength;
    } else {
      endIndex = end;
    }
    return (startIndex, endIndex);
  }

  static (int, int) hostRangeToVM((int, int) range) {
    var (start, end) = range;
    return (start + 1, end);
  }

  static List<String> getLineChunk(String value, int start, int end) {
    var lines = getLines(value);
    var (startIndex, endIndex) = vmRangeToHost((start, end), lines.length);

    return lines.getRange(startIndex, endIndex).toList();//.join(lineSeparator);
  }

  static List<String> getItemChunk(String value, String itemDelimiter, int start, int end) {
    var items = getItems(value, itemDelimiter);
    var (startIndex, endIndex) = vmRangeToHost((start, end), items.length);

    return items.getRange(startIndex, endIndex).toList();//.join(itemDelimiter);
  }

  static List<String> getWordChunk(String value, int start, int end) {
    var items = getWords(value);
    if (items.isEmpty) {
      return [];
    }
    var (startIndex, endIndex) = vmRangeToHost((start, end), items.length);

    return items.getRange(startIndex, endIndex).toList();//.join(" ");
  }

  static List<String> getCharChunk(String value, int start, int end) {
    var items = value.characters;
    var (startIndex, endIndex) = vmRangeToHost((start, end), items.length);

    return items.getRange(startIndex, endIndex).toList();//.join();
  }

  static Datum getPropRef(PlayerVM vm, Datum datum, String propName, Datum start, Datum end) {
    var stringDatum = datum as StringDatum;
    switch (propName) {
      case "item": {
        return StringChunkDatum(
          stringDatum, 
          StringChunkRef.fromChunkType(ChunkExprType.kChunkItem, start.toInt(), end.toInt(), arg: vm.itemDelimiter)
        );
      }
      case "word": {
        return StringChunkDatum(
          stringDatum, 
          StringChunkRef.fromChunkType(ChunkExprType.kChunkWord, start.toInt(), end.toInt())
        ); 
      }
      case "char": {
        return StringChunkDatum(
          stringDatum, 
          StringChunkRef.fromChunkType(ChunkExprType.kChunkChar, start.toInt(), end.toInt())
        ); 
      }
      case "line": {
        return StringChunkDatum(
          stringDatum, 
          StringChunkRef.fromChunkType(ChunkExprType.kChunkLine, start.toInt(), end.toInt())
        ); 
      }
      default:
        throw Exception("Invalid getPropRef for string: $propName");
    }
  }

  static Datum callHandler(PlayerVM vm, Datum stringDatum, String handlerName, List<Datum> args) {
    switch (handlerName) {
    case "count": {
      var operand = args[0].stringValue();
      return Datum.ofInt(getCount(stringDatum.stringValue(), operand, vm.itemDelimiter));
    }
    case "getPropRef":
      var propName = args[0].stringValue();
      return getPropRef(vm, stringDatum, propName, args[1], Datum.ofInt(args[1].toInt()));
    case "getProp":
      var propName = args[0].stringValue();
      var start = args[1];
      var end = args.elementAtOrNull(2);
      return getPropRef(vm, stringDatum, propName, start, end ?? start /* TODO verify this */);
    }
    
    throw Exception("Undefined handler $handlerName for string");
  }

  static Datum getProp(String obj, String propName) {
    switch (propName) {
      case "length":
        return Datum.ofInt(obj.length);
      default:
        throw Exception("Undefined prop $propName for string");
    }
  }
}
