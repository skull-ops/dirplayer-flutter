import 'package:dirplayer/director/lingo/bytecode.dart';
import 'package:dirplayer/director/lingo/datum.dart';
import 'package:dirplayer/director/lingo/opcode.dart';
import 'package:dirplayer/player/runtime/bytecode/handler_manager.dart';
import 'package:dirplayer/player/runtime/vm.dart';

import '../compare.dart';

class ComparingBytecodeHandler implements BytecodeHandler {
  @override
  Future<HandlerExecutionResult?> executeBytecode(PlayerVM vm, Bytecode bytecode) async {
    switch (bytecode.opcode) {
    case OpCode.kOpNtEq: {
      var left = vm.pop();
      var right = vm.pop();
      vm.push(Datum.ofBool(!datumEquals(left, right)));
      break;
    }
    case OpCode.kOpAnd: {
      var left = vm.pop();
      var right = vm.pop();
      vm.push(Datum.ofBool(left.toBool() && right.toBool()));
      break;
    }
    case OpCode.kOpOr: {
      var left = vm.pop();
      var right = vm.pop();
      vm.push(Datum.ofBool(left.toBool() || right.toBool()));
      break;
    }
    case OpCode.kOpEq: {
      var left = vm.pop();
      var right = vm.pop();
      vm.push(Datum.ofBool(datumEquals(left, right)));
      break;
    }
    case OpCode.kOpLtEq: {
      var right = vm.pop();
      var left = vm.pop();
      var comparison = compareDatums(left, right);
      var isLtEq = comparison == ComparisonResult.lessThan || comparison == ComparisonResult.same;
      vm.push(Datum.ofInt(isLtEq ? 1 : 0));
      break;
    }
    case OpCode.kOpGt: {
      var right = vm.pop();
      var left = vm.pop();
      var comparison = compareDatums(left, right);
      var isGt = comparison == ComparisonResult.greaterThan;
      vm.push(Datum.ofInt(isGt ? 1 : 0));
      break;
    }
    case OpCode.kOpGtEq: {
      var right = vm.pop();
      var left = vm.pop();
      var comparison = compareDatums(left, right);
      var isGtEq = comparison == ComparisonResult.greaterThan || comparison == ComparisonResult.same;
      vm.push(Datum.ofBool(isGtEq));
      break;
    }
    case OpCode.kOpLt: {
      var right = vm.pop();
      var left = vm.pop();
      var comparison = compareDatums(left, right);
      var isLt = comparison == ComparisonResult.lessThan;
      vm.push(Datum.ofInt(isLt ? 1 : 0));
      break;
    }
    case OpCode.kOpNot: {
      var obj = vm.pop();
      if (obj.type == DatumType.kDatumVoid) {
        vm.push(Datum.ofInt(1));
      } else if (obj.type == DatumType.kDatumInt || obj.type == DatumType.kDatumFloat) {
        vm.push(Datum.ofInt(obj.toInt() == 0 ? 1 : 0));
      } else {
        vm.push(Datum.ofInt(0));
      }
      break;
    }
    default:
      return null;
    }
    return HandlerExecutionResult.advance;
  }
}
