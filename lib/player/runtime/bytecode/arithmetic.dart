import 'package:dirplayer/director/lingo/bytecode.dart';
import 'package:dirplayer/director/lingo/datum.dart';
import 'package:dirplayer/director/lingo/datum/var_ref.dart';
import 'package:dirplayer/director/lingo/opcode.dart';
import 'package:dirplayer/player/runtime/bytecode/handler_manager.dart';
import 'package:dirplayer/player/runtime/datum_operations.dart';
import 'package:dirplayer/player/runtime/vm.dart';

import '../../../director/lingo/addable.dart';

class ArithmeticBytecodeHandler implements BytecodeHandler {
  @override
  Future<HandlerExecutionResult?> executeBytecode(PlayerVM vm, Bytecode bytecode) async {
    switch (bytecode.opcode) {
    case OpCode.kOpAdd:
      final right = vm.pop();
      final left = vm.pop();
      vm.push(addDatums(left, right));
      break;
    case OpCode.kOpMod:
      var right = vm.pop();
      var left = vm.pop();

      if (left.isNumber() && right.isNumber()) {
        if (left.type == DatumType.kDatumFloat || right.type == DatumType.kDatumFloat) {
          vm.push(Datum.ofFloat(left.toFloat() % right.toFloat()));
        } else {
          vm.push(Datum.ofInt(left.toInt() % right.toInt()));
        }
      } else {
        return Future.error(Exception("Cannot mod non-numeric datums"));
      }
      break;
    case OpCode.kOpSub: {
      var right = vm.pop();
      var left = vm.pop();
      vm.push(subtractDatums(left, right));
      break;
    }
    case OpCode.kOpInv: {
      var obj = vm.pop();
      if (obj.isInt()) {
        vm.push(Datum.ofInt(-obj.toInt()));
      } else if (obj.isFloat()) {
        vm.push(Datum.ofFloat(-obj.toFloat()));
      } else if (!obj.isNumber()) {
        throw Exception("Cannot inv non-numeric value");
      }
    }
    case OpCode.kOpDiv: {
      var right = vm.pop();
      var left = vm.pop();
      
      if (left.isNumber() && right.isNumber()) {
        if (left.type == DatumType.kDatumFloat || right.type == DatumType.kDatumFloat) {
          vm.push(Datum.ofFloat(left.toFloat() / right.toFloat()));
        } else {
          vm.push(Datum.ofInt(left.toInt() ~/ right.toInt()));
        }
      } else {
        return Future.error(Exception("Cannot divide non-numeric datums"));
      }
      break;
    }
    case OpCode.kOpMul: {
      var right = vm.pop();
      var left = vm.pop();
      
      if (left.isNumber() && right.isNumber()) {
        if (left.type == DatumType.kDatumFloat || right.type == DatumType.kDatumFloat) {
          vm.push(Datum.ofFloat(left.toFloat() * right.toFloat()));
        } else {
          vm.push(Datum.ofInt(left.toInt() * right.toInt()));
        }
      } else {
        return Future.error(Exception("Cannot multiply non-numeric datums"));
      }
      break;
    }
    default:
      return null;
    }
    return HandlerExecutionResult.advance;
  }
}
