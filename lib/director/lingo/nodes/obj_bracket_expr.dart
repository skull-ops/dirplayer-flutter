import 'package:dirplayer/common/codewriter.dart';

import '../node.dart';
import '../node_type.dart';
import 'expression.dart';

class ObjBracketExprNode extends ExprNode {
	Node obj;
	Node prop;

	ObjBracketExprNode(this.obj, this.prop)
		: super(NodeType.kObjBracketExprNode) {
		obj.parent = this;
		prop.parent = this;
	}

  @override
  void writeScriptText(CodeWriter code, bool dot, bool sum) {
    bool parenObj = obj.hasSpaces(dot);
    if (parenObj) {
      code.write("(");
    }
    obj.writeScriptText(code, dot, sum);
    if (parenObj) {
      code.write(")");
    }

    code.write("[");
    prop.writeScriptText(code, dot, sum);
    code.write("]");
  }

  @override
  bool hasSpaces(bool dot) {
    return false;
  }
}
