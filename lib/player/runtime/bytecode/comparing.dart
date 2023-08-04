import 'package:dirplayer/director/lingo/bytecode.dart';
import 'package:dirplayer/director/lingo/datum.dart';
import 'package:dirplayer/director/lingo/opcode.dart';
import 'package:dirplayer/player/runtime/bytecode/handler_manager.dart';
import 'package:dirplayer/player/runtime/vm.dart';

import '../compare.dart';

class ComparingBytecodeHandler extends BytecodeHandler {
  @override
  get syncHandlers => {
    OpCode.kOpNtEq: ntEq,
    OpCode.kOpAnd: and,
    OpCode.kOpOr: or,
    OpCode.kOpEq: eq,
    OpCode.kOpLtEq: ltEq,
    OpCode.kOpGt: gt,
    OpCode.kOpGtEq: gtEq,
    OpCode.kOpLt: lt,
    OpCode.kOpNot: not,
  };
  
  static HandlerExecutionResult ntEq(PlayerVM vm, Bytecode bytecode) {
    var left = vm.pop();
    var right = vm.pop();
    vm.push(Datum.ofBool(!datumEquals(left, right)));
    return HandlerExecutionResult.advance;
  }

  static HandlerExecutionResult and(PlayerVM vm, Bytecode bytecode) {
    var left = vm.pop();
    var right = vm.pop();
    vm.push(Datum.ofBool(left.toBool() && right.toBool()));
    return HandlerExecutionResult.advance;
  }

  static HandlerExecutionResult or(PlayerVM vm, Bytecode bytecode) {
    var left = vm.pop();
    var right = vm.pop();
    vm.push(Datum.ofBool(left.toBool() || right.toBool()));
    return HandlerExecutionResult.advance;
  }

  static HandlerExecutionResult eq(PlayerVM vm, Bytecode bytecode) {
    var left = vm.pop();
    var right = vm.pop();
    vm.push(Datum.ofBool(datumEquals(left, right)));
    return HandlerExecutionResult.advance;
  }

  static HandlerExecutionResult ltEq(PlayerVM vm, Bytecode bytecode) {
    var right = vm.pop();
    var left = vm.pop();
    var comparison = compareDatums(left, right);
    var isLtEq = comparison == ComparisonResult.lessThan || comparison == ComparisonResult.same;
    vm.push(Datum.ofInt(isLtEq ? 1 : 0));
    return HandlerExecutionResult.advance;
  }

  static HandlerExecutionResult gt(PlayerVM vm, Bytecode bytecode) {
    var right = vm.pop();
    var left = vm.pop();
    var comparison = compareDatums(left, right);
    var isGt = comparison == ComparisonResult.greaterThan;
    vm.push(Datum.ofInt(isGt ? 1 : 0));
    return HandlerExecutionResult.advance;
  }

  static HandlerExecutionResult gtEq(PlayerVM vm, Bytecode bytecode) {
    var right = vm.pop();
    var left = vm.pop();
    var comparison = compareDatums(left, right);
    var isGtEq = comparison == ComparisonResult.greaterThan || comparison == ComparisonResult.same;
    vm.push(Datum.ofBool(isGtEq));
    return HandlerExecutionResult.advance;
  }

  static HandlerExecutionResult lt(PlayerVM vm, Bytecode bytecode) {
    var right = vm.pop();
    var left = vm.pop();
    var comparison = compareDatums(left, right);
    var isLt = comparison == ComparisonResult.lessThan;
    vm.push(Datum.ofInt(isLt ? 1 : 0));
    return HandlerExecutionResult.advance;
  }

  static HandlerExecutionResult not(PlayerVM vm, Bytecode bytecode) {
    var obj = vm.pop();
    if (obj.type == DatumType.kDatumVoid) {
      vm.push(Datum.ofInt(1));
    } else if (obj.type == DatumType.kDatumInt || obj.type == DatumType.kDatumFloat) {
      vm.push(Datum.ofInt(obj.toInt() == 0 ? 1 : 0));
    } else {
      vm.push(Datum.ofInt(0));
    }
    return HandlerExecutionResult.advance;
  }
}
