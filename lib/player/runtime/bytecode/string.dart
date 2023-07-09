import 'package:dirplayer/director/lingo/bytecode.dart';
import 'package:dirplayer/director/lingo/datum.dart';
import 'package:dirplayer/director/lingo/datum/string.dart';
import 'package:dirplayer/director/lingo/datum/string_chunk.dart';
import 'package:dirplayer/director/lingo/opcode.dart';
import 'package:dirplayer/player/runtime/bytecode/handler_manager.dart';
import 'package:dirplayer/player/runtime/chunk_ref.dart';
import 'package:dirplayer/player/runtime/vm.dart';

import '../../../director/lingo/chunk_expr_type.dart';
import '../wrappers/string.dart';

class StringBytecodeHandler implements BytecodeHandler {
  @override
  Future<HandlerExecutionResult?> executeBytecode(PlayerVM vm, Bytecode bytecode) async {
    switch (bytecode.opcode) {
    case OpCode.kOpJoinPadStr: {
      var right = vm.pop().stringValue();
      var left = vm.pop().stringValue();
      vm.push(Datum.ofString("$left $right"));
      break;
    }
    case OpCode.kOpJoinStr: {
      var right = vm.pop().stringValue();
      var left = vm.pop().stringValue();
      vm.push(Datum.ofString("$left$right"));
      break;
    }
    case OpCode.kOpContainsStr: {
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
      break;
    }
    case OpCode.kOpGetChunk: {
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
        result = StringChunkRef.fromChunkType(ChunkExprType.kChunkLine, firstItem.toInt(), lastItem.toInt());
      } else if (firstItem != 0 || lastItem != 0) {
        result = StringChunkRef.fromChunkType(ChunkExprType.kChunkItem, firstItem.toInt(), lastItem.toInt(), arg: vm.itemDelimiter);
      } else if (firstWord != 0 || lastWord != 0) {
        result = StringChunkRef.fromChunkType(ChunkExprType.kChunkWord, firstItem.toInt(), lastItem.toInt());
      } else if (firstChar != 0 || lastChar != 0) {
        result = StringChunkRef.fromChunkType(ChunkExprType.kChunkChar, firstItem.toInt(), lastItem.toInt());
      } else {
        throw Exception("Invalid OpCode.kOpGetChunk call");
      }

      vm.push(StringChunkDatum(string, result));
      break;
    }
    default:
      return null;
    }
    return HandlerExecutionResult.advance;
  }
}
