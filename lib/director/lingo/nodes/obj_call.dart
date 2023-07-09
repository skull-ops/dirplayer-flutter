import 'package:dirplayer/common/codewriter.dart';
import 'package:dirplayer/director/lingo/datum.dart';

import '../node.dart';
import '../node_type.dart';
import 'expression.dart';

class ObjCallNode extends ExprNode {
	String name;
  Node argList;

	ObjCallNode(this.name, this.argList) : super(NodeType.kObjCallNode) {
		argList.parent = this;
    if (argList.getValue().type == DatumType.kDatumArgListNoRet) {
      isStatement = true;
    } else {
      isExpression = true;
    }
	}

  @override
  void writeScriptText(CodeWriter code, bool dot, bool sum) {
    var rawArgs = argList.getValue().toNodeList();

    var obj = rawArgs[0];
    bool parenObj = obj.hasSpaces(dot);
    if (parenObj) {
      code.write("(");
    }
    obj.writeScriptText(code, dot, sum);
    if (parenObj) {
      code.write(")");
    }

    code.write(".");
    code.write(name);
    code.write("(");
    for (var i = 1; i < rawArgs.length; i++) {
      if (i > 1) {
        code.write(", ");
      }
      rawArgs[i].writeScriptText(code, dot, sum);
    }
    code.write(")");
  }

  @override
  bool hasSpaces(bool dot) {
    return false;
  }
}
