import 'package:dirplayer/common/codewriter.dart';

import '../constants.dart';
import '../lingo.dart';
import '../node.dart';
import '../node_type.dart';
import '../opcode.dart';
import 'expression.dart';

class BinaryOpNode extends ExprNode {
	OpCode opcode;
	Node left;
	Node right;

	BinaryOpNode(this.opcode, this.left, this.right)
		: super(NodeType.kBinaryOpNode) {
		left.parent = this;
		right.parent = this;
	}

  @override
  void writeScriptText(CodeWriter code, bool dot, bool sum) {
    int precedence = getPrecedence();
    bool parenLeft = false;
    bool parenRight = false;
    if (precedence != 0) {
      if (left.type == NodeType.kBinaryOpNode) {
        var leftBinaryOpNode = left as BinaryOpNode;
        parenLeft = (leftBinaryOpNode.getPrecedence() != precedence);
      }
      parenRight = (right.type == NodeType.kBinaryOpNode);
    }

    if (parenLeft) {
      code.write("(");
    }
    left.writeScriptText(code, dot, sum);
    if (parenLeft) {
      code.write(")");
    }

    code.write(" ");
    code.write(Lingo.getName(binaryOpNames, opcode));
    code.write(" ");

    if (parenRight) {
      code.write("(");
    }
    right.writeScriptText(code, dot, sum);
    if (parenRight) {
      code.write(")");
    }
  }

  int getPrecedence() {
    switch (opcode) {
    case OpCode.kOpMul:
    case OpCode.kOpDiv:
    case OpCode.kOpMod:
      return 1;
    case OpCode.kOpAdd:
    case OpCode.kOpSub:
      return 2;
    case OpCode.kOpLt:
    case OpCode.kOpLtEq:
    case OpCode.kOpNtEq:
    case OpCode.kOpEq:
    case OpCode.kOpGt:
    case OpCode.kOpGtEq:
      return 3;
    case OpCode.kOpAnd:
      return 4;
    case OpCode.kOpOr:
      return 5;
    default:
      break;
    }
    return 0;
  }

  @override
  bool hasSpaces(bool dot) {
    return false;
  }
	//virtual void writeScriptText(Common::CodeWriter &code, bool dot, bool sum) const;
	//virtual unsigned int getPrecedence() const;
}
