import 'package:dirplayer/director/lingo/opcode.dart';
import 'package:dirplayer/player/runtime/bytecode/arithmetic.dart';
import 'package:dirplayer/player/runtime/bytecode/comparing.dart';
import 'package:dirplayer/player/runtime/bytecode/flow_control.dart';
import 'package:dirplayer/player/runtime/bytecode/get_set.dart';
import 'package:dirplayer/player/runtime/bytecode/stack.dart';
import 'package:dirplayer/player/runtime/bytecode/string.dart';

import '../../../director/lingo/bytecode.dart';
import '../vm.dart';

typedef BytecodeHandlerFunctionSync = HandlerExecutionResult Function(PlayerVM vm, Bytecode bytecode);
typedef BytecodeHandlerFunctionAsync = Future<HandlerExecutionResult> Function(PlayerVM vm, Bytecode bytecode);

abstract class BytecodeHandler {
  Map<OpCode, BytecodeHandlerFunctionSync> get syncHandlers => {};
  Map<OpCode, BytecodeHandlerFunctionAsync> get asyncHandlers => {};
}

class BytecodeHandlerManager {
  final syncHandlerMap = <int, BytecodeHandlerFunctionSync>{};
  final asyncHandlerMap = <int, BytecodeHandlerFunctionAsync>{};

  BytecodeHandlerManager() {
    add(ArithmeticBytecodeHandler());
    add(ComparingBytecodeHandler());
    add(FlowControlBytecodeHandler());
    add(GetSetBytecodeHandler());
    add(StackBytecodeHandler());
    add(StringBytecodeHandler());
  }

  bool containsHandler(OpCode opCode) {
    return syncHandlerMap.containsKey(opCode.rawValue) || asyncHandlerMap.containsKey(opCode.rawValue);
  }

  void registerSyncOpcode(OpCode opCode, BytecodeHandlerFunctionSync function) {
    if (containsHandler(opCode)) {
      throw Exception("OpCode already registered: $opCode");
    }
    syncHandlerMap[opCode.rawValue] = function;
  }

  void add(BytecodeHandler handler) {
    for (var entry in handler.syncHandlers.entries) {
      registerSyncOpcode(entry.key, entry.value);
    }
    for (var entry in handler.asyncHandlers.entries) {
      registerAsyncOpcode(entry.key, entry.value);
    }
  }

  void registerAsyncOpcode(OpCode opCode, BytecodeHandlerFunctionAsync function) {
    if (containsHandler(opCode)) {
      throw Exception("OpCode already registered: $opCode");
    }
    asyncHandlerMap[opCode.rawValue] = function;
  }

  Future<HandlerExecutionResult> executeBytecode(PlayerVM vm, Bytecode bytecode) async {
    var syncHandler = syncHandlerMap[bytecode.opcode.rawValue];
    if (syncHandler != null) {
      return syncHandler(vm, bytecode);
    }
    var asyncHandler = asyncHandlerMap[bytecode.opcode.rawValue];
    if (asyncHandler != null) {
      return await asyncHandler(vm, bytecode);
    }
    return Future.error(Exception("No handler for OpCode ${bytecode.opcode}"));
  } 
}
