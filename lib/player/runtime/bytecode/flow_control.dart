import 'package:dirplayer/director/lingo/bytecode.dart';
import 'package:dirplayer/director/lingo/datum.dart';
import 'package:dirplayer/director/lingo/opcode.dart';
import 'package:dirplayer/player/runtime/bytecode/handler_manager.dart';
import 'package:dirplayer/player/runtime/vm.dart';

class FlowControlBytecodeHandler extends BytecodeHandler {
  @override
  get syncHandlers => {
    OpCode.kOpRet: ret,
    OpCode.kOpJmpIfZ: jmpIfZ,
    OpCode.kOpEndRepeat: endRepeat,
    OpCode.kOpJmp: jmp,
  };

  @override
  get asyncHandlers => {
    OpCode.kOpLocalCall: localCall,
    OpCode.kOpObjCall: objCall,
    OpCode.kOpExtCall: extCall,
  };

  static HandlerExecutionResult ret(PlayerVM vm, Bytecode bytecode) {
    vm.stack.clear();
    return HandlerExecutionResult.stop;
  }

  static HandlerExecutionResult jmpIfZ(PlayerVM vm, Bytecode bytecode) {
    vm.currentScope!.loopPositions.add(vm.currentScope!.handlerPosition);

    var value = vm.pop().toInt();
    var offset = bytecode.obj;
    if (value == 0) {
      vm.jumpToBytecodePosition(bytecode.pos + offset);
      return HandlerExecutionResult.jump;
    }
    return HandlerExecutionResult.advance;
  }

  static HandlerExecutionResult endRepeat(PlayerVM vm, Bytecode bytecode) {
    var returnPosition = bytecode.pos - bytecode.obj;
    vm.jumpToBytecodePosition(returnPosition);
    return HandlerExecutionResult.jump;
  }

  static HandlerExecutionResult jmp(PlayerVM vm, Bytecode bytecode) {
    var position = bytecode.pos + bytecode.obj;
    vm.jumpToBytecodePosition(position);
    return HandlerExecutionResult.jump;
  }

  static Future<HandlerExecutionResult> localCall(PlayerVM vm, Bytecode bytecode) async {
    var argListDatum = vm.pop();
    var isNoRet = argListDatum.type == DatumType.kDatumArgListNoRet;
    var args = argListDatum.toList();
    var handler = vm.currentScope!.script.getOwnHandlerAt(bytecode.obj);

    var result = await vm.callHandler(vm.currentScope!.script, vm.currentScope!.receiver, handler, args);
    if (!isNoRet) {
      vm.push(result);
    }
    return HandlerExecutionResult.advance;
  }

  static Future<HandlerExecutionResult> objCall(PlayerVM vm, Bytecode bytecode) async {
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
    return HandlerExecutionResult.advance;
  }

  Future<HandlerExecutionResult> extCall(PlayerVM vm, Bytecode bytecode) async {
    String name = vm.currentHandler!.getName(bytecode.obj);
    var argListDatum = vm.pop();
    var isNoRet = argListDatum.type == DatumType.kDatumArgListNoRet;
    var argList = argListDatum.toList();

    var extCallResult = await vm.extCall(name, argList);
    if (!isNoRet) {
      vm.push(extCallResult.result);
    }
    return extCallResult.handlerExecutionResult;
  }
}
