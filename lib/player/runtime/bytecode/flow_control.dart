import 'package:dirplayer/director/lingo/bytecode.dart';
import 'package:dirplayer/director/lingo/datum.dart';
import 'package:dirplayer/director/lingo/opcode.dart';
import 'package:dirplayer/player/runtime/bytecode/handler_manager.dart';
import 'package:dirplayer/player/runtime/vm.dart';

class FlowControlBytecodeHandler implements BytecodeHandler {
  @override
  Future<HandlerExecutionResult?> executeBytecode(PlayerVM vm, Bytecode bytecode) async {
    switch (bytecode.opcode) {
    case OpCode.kOpRet:
      vm.stack.clear();
      return HandlerExecutionResult.stop;
    
    case OpCode.kOpJmpIfZ:
      vm.currentScope!.loopPositions.add(vm.currentScope!.handlerPosition);

      var value = vm.pop().toInt();
      var offset = bytecode.obj;
      if (value == 0) {
        vm.jumpToBytecodePosition(bytecode.pos + offset);
        return HandlerExecutionResult.jump;
      }
      break;
    case OpCode.kOpEndRepeat: {
      var returnPosition = bytecode.pos - bytecode.obj;
      vm.jumpToBytecodePosition(returnPosition);
      return HandlerExecutionResult.jump;
    }
    case OpCode.kOpJmp: {
      var position = bytecode.pos + bytecode.obj;
      vm.jumpToBytecodePosition(position);
      return HandlerExecutionResult.jump;
    }
    case OpCode.kOpLocalCall: {
      var argListDatum = vm.pop();
      var isNoRet = argListDatum.type == DatumType.kDatumArgListNoRet;
      var args = argListDatum.toList();
      var handler = vm.currentScope!.script.handlers[bytecode.obj];

      var result = await vm.callHandler(vm.currentScope!.script, vm.currentScope!.receiver, handler, args);
      if (!isNoRet) {
        vm.push(result);
      }
      break;
    }
    case OpCode.kOpObjCall: {
      var argListDatum = vm.pop();
      var isNoRet = argListDatum.type == DatumType.kDatumArgListNoRet;
      var argList = argListDatum.toList();
      var obj = argList[0];
      var args = argList.getRange(1, argList.length).toList();
      var handlerName = vm.currentHandler!.getName(bytecode.obj);

      var result = await vm.callObjectHandler(obj, handlerName, args);
      if (!isNoRet) {
        vm.push(result);
      }
      break;
    }
    case OpCode.kOpExtCall:
      String name = vm.currentHandler!.getName(bytecode.obj);
      var argListDatum = vm.pop();
      var isNoRet = argListDatum.type == DatumType.kDatumArgListNoRet;
      var argList = argListDatum.toList();

      var extCallResult = await vm.extCall(name, argList);
      if (!isNoRet) {
        vm.push(extCallResult.result);
      }
      return extCallResult.handlerExecutionResult;
    default:
      return null;
    }
    return HandlerExecutionResult.advance;
  }
}
