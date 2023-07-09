import 'package:dirplayer/common/codewriter.dart';

import '../node_type.dart';
import 'expression.dart';

class VarNode extends ExprNode {
	String varName;

	VarNode(this.varName) : super(NodeType.kVarNode);

  @override
  void writeScriptText(CodeWriter code, bool dot, bool sum) {
    code.write(varName);
  }

  @override
  bool hasSpaces(bool dot) {
    return false;
  }
}
