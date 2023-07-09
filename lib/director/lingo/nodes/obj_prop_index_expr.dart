import 'package:dirplayer/common/codewriter.dart';

import '../node.dart';
import '../node_type.dart';
import 'expression.dart';

class ObjPropIndexExprNode extends ExprNode {
	Node obj;
	String prop;
	Node index;
	Node? index2;

	ObjPropIndexExprNode(this.obj, this.prop, this.index, this.index2)
		: super(NodeType.kObjPropIndexExprNode) {
		obj.parent = this;
		index.parent = this;
		index2?.parent = this;
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

    code.write(".");
    code.write(prop);
    code.write("[");
    index.writeScriptText(code, dot, sum);
    if (index2 != null) {
      code.write("..");
      index2!.writeScriptText(code, dot, sum);
    }
    code.write("]");
  }

  @override
  bool hasSpaces(bool dot) {
    return false;
  }
}
