import 'package:dirplayer/director/lingo/bytecode.dart';
import 'package:dirplayer/director/lingo/datum.dart';
import 'package:dirplayer/director/lingo/opcode.dart';
import 'package:dirplayer/player/runtime/bytecode/handler_manager.dart';
import 'package:dirplayer/player/runtime/vm.dart';

import '../../../director/util.dart';

class StackBytecodeHandler extends BytecodeHandler {
  @override
  get syncHandlers => {
    OpCode.kOpPushInt8: pushInt,
    OpCode.kOpPushInt16: pushInt,
    OpCode.kOpPushInt32: pushInt,
    OpCode.kOpPushFloat32: pushFloat,
    OpCode.kOpPushArgList: pushArgList,
    OpCode.kOpPushArgListNoRet: pushArgListNoRet,
    OpCode.kOpPushZero: pushZero,
    OpCode.kOpPushPropList: pushPropList,
    OpCode.kOpPushSymb: pushSymbol,
    OpCode.kOpPushList: pushList,
    OpCode.kOpPeek: peek,
    OpCode.kOpPop: pop,
    OpCode.kOpPushCons: pushCons,
    OpCode.kOpPushChunkVarRef: pushChunkVarRef,
  };

  static HandlerExecutionResult pushInt(PlayerVM vm, Bytecode bytecode) {
    vm.push(Datum.ofInt(bytecode.obj));
    return HandlerExecutionResult.advance;
  }

  static HandlerExecutionResult pushFloat(PlayerVM vm, Bytecode bytecode) {
    vm.push(Datum.ofFloat(int32BytesToFloat(bytecode.obj)));
    return HandlerExecutionResult.advance;
  }

  static HandlerExecutionResult pushArgList(PlayerVM vm, Bytecode bytecode) {
    vm.push(Datum.ofDatumList(DatumType.kDatumArgList, vm.popN(bytecode.obj)));
    return HandlerExecutionResult.advance;
  }

  static HandlerExecutionResult pushArgListNoRet(PlayerVM vm, Bytecode bytecode) {
    vm.push(Datum.ofDatumList(DatumType.kDatumArgListNoRet, vm.popN(bytecode.obj)));
    return HandlerExecutionResult.advance;
  }

  HandlerExecutionResult pushZero(PlayerVM vm, Bytecode bytecode) {
    vm.push(Datum.ofInt(0));
    return HandlerExecutionResult.advance;
  }

  static HandlerExecutionResult pushPropList(PlayerVM vm, Bytecode bytecode) {
    var argList = vm.pop().toList();
    assert(argList.length % 2 == 0);

    var entryCount = argList.length ~/ 2;
    var entries = List.generate(entryCount, (index) {
      var baseIndex = index * 2;
      var key = argList[baseIndex];
      var value = argList[baseIndex + 1];
      return MapEntry(key, value);
    });
    vm.push(Datum.ofPropList(Map.fromEntries(entries)));
    return HandlerExecutionResult.advance;
  }

  static HandlerExecutionResult pushSymbol(PlayerVM vm, Bytecode bytecode) {
    var symbolName = vm.currentHandler!.getName(bytecode.obj);
    vm.push(Datum.ofSymbol(symbolName));
    return HandlerExecutionResult.advance;
  }

  static HandlerExecutionResult pushList(PlayerVM vm, Bytecode bytecode) {
    var list = vm.pop().toList();
    vm.push(Datum.ofDatumList(DatumType.kDatumList, list));
    return HandlerExecutionResult.advance;
  }

  static HandlerExecutionResult peek(PlayerVM vm, Bytecode bytecode) {
    var offset = bytecode.obj;
    vm.push(vm.stack[vm.stack.length - 1 - offset]);
    return HandlerExecutionResult.advance;
  }

  static HandlerExecutionResult pop(PlayerVM vm, Bytecode bytecode) {
    var count = bytecode.obj;
    var startIndex = vm.stack.length - count;
    var endIndex = vm.stack.length - 1;

    for (var i = 0; i < count; i++) {
      vm.pop();
    }
    return HandlerExecutionResult.advance;
  }

  static HandlerExecutionResult pushCons(PlayerVM vm, Bytecode bytecode) {
    int literalID = bytecode.obj ~/ vm.currentHandler!.variableMultiplier();
    var literal = vm.currentHandler!.script.literals[literalID];
    vm.push(literal.value!);
    return HandlerExecutionResult.advance;
  }

  static HandlerExecutionResult pushChunkVarRef(PlayerVM vm, Bytecode bytecode) {
    var ref = vm.readVar(bytecode.obj);
    vm.push(ref.get());
    return HandlerExecutionResult.advance;
  }
}
