
import 'package:dirplayer/common/codewriter.dart';

import '../node_type.dart';
import 'expression.dart';

class TheExprNode extends ExprNode {
	String prop;

	TheExprNode(this.prop) : super(NodeType.kTheExprNode);
	
  @override
  void writeScriptText(CodeWriter code, bool dot, bool sum) {
    code.write("the ");
	  code.write(prop);
  }

  @override
  bool hasSpaces(bool dot) {
    return false;
  }
}

