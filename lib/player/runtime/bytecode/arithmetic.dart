import 'package:dirplayer/director/lingo/bytecode.dart';
import 'package:dirplayer/director/lingo/datum.dart';
import 'package:dirplayer/director/lingo/opcode.dart';
import 'package:dirplayer/player/runtime/bytecode/handler_manager.dart';
import 'package:dirplayer/player/runtime/datum_operations.dart';
import 'package:dirplayer/player/runtime/vm.dart';

class ArithmeticBytecodeHandler extends BytecodeHandler {
  @override
  get syncHandlers => {
    OpCode.kOpAdd: add,
    OpCode.kOpMod: mod,
    OpCode.kOpSub: sub,
    OpCode.kOpInv: inv,
    OpCode.kOpDiv: div,
    OpCode.kOpMul: mul,
  };

  static HandlerExecutionResult add(PlayerVM vm, Bytecode bytecode) {
    final right = vm.pop();
    final left = vm.pop();
    vm.push(addDatums(left, right));
    return HandlerExecutionResult.advance;
  }

  static HandlerExecutionResult mod(PlayerVM vm, Bytecode bytecode) {
    var right = vm.pop();
    var left = vm.pop();

    if (left.isNumber() && right.isNumber()) {
      if (left.type == DatumType.kDatumFloat || right.type == DatumType.kDatumFloat) {
        vm.push(Datum.ofFloat(left.toFloat() % right.toFloat()));
      } else {
        vm.push(Datum.ofInt(left.toInt() % right.toInt()));
      }
    } else {
      throw Exception("Cannot mod non-numeric datums");
    }
    return HandlerExecutionResult.advance;
  }

  static HandlerExecutionResult sub(PlayerVM vm, Bytecode bytecode) {
    var right = vm.pop();
    var left = vm.pop();
    vm.push(subtractDatums(left, right));
    return HandlerExecutionResult.advance;
  }

  static HandlerExecutionResult inv(PlayerVM vm, Bytecode bytecode) {
    var obj = vm.pop();
    if (obj.isInt()) {
      vm.push(Datum.ofInt(-obj.toInt()));
    } else if (obj.isFloat()) {
      vm.push(Datum.ofFloat(-obj.toFloat()));
    } else if (!obj.isNumber()) {
      throw Exception("Cannot inv non-numeric value");
    }
    return HandlerExecutionResult.advance;
  }

  static HandlerExecutionResult div(PlayerVM vm, Bytecode bytecode) {
    var right = vm.pop();
    var left = vm.pop();
    
    if (left.isNumber() && right.isNumber()) {
      if (left.type == DatumType.kDatumFloat || right.type == DatumType.kDatumFloat) {
        vm.push(Datum.ofFloat(left.toFloat() / right.toFloat()));
      } else {
        vm.push(Datum.ofInt(left.toInt() ~/ right.toInt()));
      }
    } else {
      throw Exception("Cannot divide non-numeric datums");
    }
    return HandlerExecutionResult.advance;
  }

  static HandlerExecutionResult mul(PlayerVM vm, Bytecode bytecode) {
    var right = vm.pop();
    var left = vm.pop();
    
    if (left.isNumber() && right.isNumber()) {
      if (left.type == DatumType.kDatumFloat || right.type == DatumType.kDatumFloat) {
        vm.push(Datum.ofFloat(left.toFloat() * right.toFloat()));
      } else {
        vm.push(Datum.ofInt(left.toInt() * right.toInt()));
      }
    } else {
      throw Exception("Cannot multiply non-numeric datums");
    }
    return HandlerExecutionResult.advance;
  }
}
