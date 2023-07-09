import 'package:dirplayer/director/lingo/datum.dart';

import '../node.dart';
import '../node_type.dart';
import 'expression.dart';

class ObjCallV4Node extends ExprNode {
	Node obj;
  Node argList;

	ObjCallV4Node(this.obj, this.argList) : super(NodeType.kObjCallV4Node) {
		argList.parent = this;
    if (argList.getValue().type == DatumType.kDatumArgListNoRet) {
      isStatement = true;
    } else {
      isExpression = true;
    }
	}
	//virtual void writeScriptText(Common::CodeWriter &code, bool dot, bool sum) const;
	//virtual bool hasSpaces(bool dot);
}
