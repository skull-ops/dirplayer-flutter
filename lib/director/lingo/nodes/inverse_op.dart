import 'package:dirplayer/common/codewriter.dart';

import '../node.dart';
import '../node_type.dart';
import 'expression.dart';

class InverseOpNode extends ExprNode {
	Node operand;

	InverseOpNode(this.operand) : super(NodeType.kInverseOpNode) {
		operand.parent = this;
	}

  @override
  void writeScriptText(CodeWriter code, bool dot, bool sum) {
    code.write("-");

    bool parenOperand = operand.hasSpaces(dot);
    if (parenOperand) {
      code.write("(");
    }
    operand.writeScriptText(code, dot, sum);
    if (parenOperand) {
      code.write(")");
    }
  }

  @override
  bool hasSpaces(bool dot) {
    return false;
  }
}
