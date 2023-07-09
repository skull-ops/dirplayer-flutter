import 'package:dirplayer/director/lingo/opcode.dart';
import 'package:dirplayer/player/runtime/bytecode/arithmetic.dart';
import 'package:dirplayer/player/runtime/bytecode/comparing.dart';
import 'package:dirplayer/player/runtime/bytecode/flow_control.dart';
import 'package:dirplayer/player/runtime/bytecode/get_set.dart';
import 'package:dirplayer/player/runtime/bytecode/stack.dart';
import 'package:dirplayer/player/runtime/bytecode/string.dart';

import '../../../director/lingo/bytecode.dart';
import '../vm.dart';

abstract class BytecodeHandler {
  Future<HandlerExecutionResult?> executeBytecode(PlayerVM vm, Bytecode bytecode);
}

class BytecodeHandlerManager {
  final List<BytecodeHandler> handlers = [];

  BytecodeHandlerManager() {
    add(ArithmeticBytecodeHandler());
    add(ComparingBytecodeHandler());
    add(FlowControlBytecodeHandler());
    add(GetSetBytecodeHandler());
    add(StackBytecodeHandler());
    add(StringBytecodeHandler());
  }

  void add(BytecodeHandler handler) {
    handlers.add(handler);
  }

  Future<HandlerExecutionResult> executeBytecode(PlayerVM vm, Bytecode bytecode) async {
    for (var handler in handlers) {
      var result = await handler.executeBytecode(vm, bytecode);
      if (result != null) {
        return result;
      }
    }
    return Future.error(Exception("No handler for OpCode ${bytecode.opcode}"));
  } 
}
