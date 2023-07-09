import 'package:dirplayer/director/lingo/bytecode.dart';
import 'package:dirplayer/director/lingo/datum.dart';
import 'package:dirplayer/director/lingo/opcode.dart';
import 'package:dirplayer/player/runtime/bytecode/handler_manager.dart';
import 'package:dirplayer/player/runtime/vm.dart';

import '../../../director/util.dart';

class StackBytecodeHandler implements BytecodeHandler {
  @override
  Future<HandlerExecutionResult?> executeBytecode(PlayerVM vm, Bytecode bytecode) async {
    switch (bytecode.opcode) {
    case OpCode.kOpPushInt8:
    case OpCode.kOpPushInt16:
    case OpCode.kOpPushInt32:
      vm.push(Datum.ofInt(bytecode.obj));
      break;
    case OpCode.kOpPushFloat32:
      vm.push(Datum.ofFloat(int32BytesToFloat(bytecode.obj)));
    case OpCode.kOpPushArgList:
      vm.push(Datum.ofDatumList(DatumType.kDatumArgList, vm.popN(bytecode.obj)));
      break;
    case OpCode.kOpPushArgListNoRet:
      vm.push(Datum.ofDatumList(DatumType.kDatumArgListNoRet, vm.popN(bytecode.obj)));
      break;
    case OpCode.kOpPushZero:
      vm.push(Datum.ofInt(0));
      break;
    case OpCode.kOpPushPropList:
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
      break;
    case OpCode.kOpPushSymb:
      var symbolName = vm.currentHandler!.getName(bytecode.obj);
      vm.push(Datum.ofSymbol(symbolName));
      break;
    case OpCode.kOpPushList:
      var list = vm.pop().toList();
      vm.push(Datum.ofDatumList(DatumType.kDatumList, list));
      break;
    case OpCode.kOpPeek:
      var offset = bytecode.obj;
      vm.push(vm.stack[vm.stack.length - 1 - offset]);
      break;
    case OpCode.kOpPop:
      var count = bytecode.obj;
      var startIndex = vm.stack.length - count;
      var endIndex = vm.stack.length - 1;

      for (var i = 0; i < count; i++) {
        vm.pop();
      }
      break;
    case OpCode.kOpPushCons: {
      int literalID = bytecode.obj ~/ vm.currentHandler!.variableMultiplier();
      var literal = vm.currentHandler!.script.literals[literalID];
      vm.push(literal.value!);
      break;
    }
    case OpCode.kOpPushChunkVarRef: {
      var ref = vm.readVar(bytecode.obj);
      vm.push(ref.get());
      break;
    }
    default:
      return null;
    }
    return HandlerExecutionResult.advance;
  }
}
