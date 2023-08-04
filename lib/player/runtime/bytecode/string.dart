import 'package:dirplayer/director/lingo/bytecode.dart';
import 'package:dirplayer/director/lingo/datum.dart';
import 'package:dirplayer/director/lingo/datum/string.dart';
import 'package:dirplayer/director/lingo/datum/string_chunk.dart';
import 'package:dirplayer/director/lingo/opcode.dart';
import 'package:dirplayer/player/runtime/bytecode/handler_manager.dart';
import 'package:dirplayer/player/runtime/chunk_ref.dart';
import 'package:dirplayer/player/runtime/vm.dart';

import '../../../director/lingo/chunk_expr_type.dart';

class StringBytecodeHandler extends BytecodeHandler {
  @override
  get syncHandlers => {
    OpCode.kOpJoinPadStr: joinPadStr,
    OpCode.kOpJoinStr: joinStr,
    OpCode.kOpContainsStr: containsStr,
    OpCode.kOpGetChunk: getChunk,
  };

  static HandlerExecutionResult joinPadStr(PlayerVM vm, Bytecode bytecode) {
    var right = vm.pop().stringValue();
    var left = vm.pop().stringValue();
    vm.push(Datum.ofString("$left $right"));
    return HandlerExecutionResult.advance;
  }

  static HandlerExecutionResult joinStr(PlayerVM vm, Bytecode bytecode) {
    var right = vm.pop().stringValue();
    var left = vm.pop().stringValue();
    vm.push(Datum.ofString("$left$right"));
    return HandlerExecutionResult.advance;
  }

  static HandlerExecutionResult containsStr(PlayerVM vm, Bytecode bytecode) {
    var searchString = vm.pop().stringValue();
    var searchIn = vm.pop();

    if (searchIn.isList()) {
      bool contains = searchIn.toList().any((element) => element.isString() && element.stringValue() == searchString);
      vm.push(Datum.ofBool(contains));
    } else if (searchIn.isString()) {
      vm.push(Datum.ofBool(searchIn.stringValue().contains(searchString)));
    } else {
      throw Exception("kOpContainsStr invalid search subject $searchIn");
    }
    return HandlerExecutionResult.advance;
  }

  static HandlerExecutionResult getChunk(PlayerVM vm, Bytecode bytecode) {
    var string = vm.pop<StringDatum>(); // TODO varref?
    var lastLine = vm.pop().toInt();
    var firstLine = vm.pop().toInt();
    var lastItem = vm.pop().toInt();
    var firstItem = vm.pop().toInt();
    var lastWord = vm.pop().toInt();
    var firstWord = vm.pop().toInt();
    var lastChar = vm.pop().toInt();
    var firstChar = vm.pop().toInt();

    StringChunkRef result;
    if (firstLine != 0 || lastLine != 0) {
      result = StringChunkRef.fromChunkType(ChunkExprType.kChunkLine, firstLine.toInt(), lastLine.toInt());
    } else if (firstItem != 0 || lastItem != 0) {
      result = StringChunkRef.fromChunkType(ChunkExprType.kChunkItem, firstItem.toInt(), lastItem.toInt(), arg: vm.itemDelimiter);
    } else if (firstWord != 0 || lastWord != 0) {
      result = StringChunkRef.fromChunkType(ChunkExprType.kChunkWord, firstWord.toInt(), lastWord.toInt());
    } else if (firstChar != 0 || lastChar != 0) {
      result = StringChunkRef.fromChunkType(ChunkExprType.kChunkChar, firstChar.toInt(), lastChar.toInt());
    } else {
      throw Exception("Invalid OpCode.kOpGetChunk call");
    }

    vm.push(StringChunkDatum(string, result));
    return HandlerExecutionResult.advance;
  }
}
