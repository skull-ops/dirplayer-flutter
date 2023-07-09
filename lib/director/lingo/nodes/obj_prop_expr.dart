import 'package:dirplayer/common/codewriter.dart';

import '../node.dart';
import '../node_type.dart';
import 'expression.dart';

class ObjPropExprNode extends ExprNode {
	Node obj;
	String prop;

	ObjPropExprNode(this.obj, this.prop)
		: super(NodeType.kObjPropExprNode) {
		obj.parent = this;
	}

  @override
  void writeScriptText(CodeWriter code, bool dot, bool sum) {
    if (dot) {
      bool parenObj = obj.hasSpaces(dot);
      if (parenObj) {
        code.write("(");
      }
      obj.writeScriptText(code, dot, sum);
      if (parenObj) {
        code.write(")");
      }

      code.write(".");
      code.write(prop);
    } else {
      code.write("the ");
      code.write(prop);
      code.write(" of ");

      bool parenObj = (obj.type == NodeType.kBinaryOpNode);
      if (parenObj) {
        code.write("(");
      }
      obj.writeScriptText(code, dot, sum);
      if (parenObj) {
        code.write(")");
      }
    }
  }

  @override
  bool hasSpaces(bool dot) {
    return !dot;
  }
}
