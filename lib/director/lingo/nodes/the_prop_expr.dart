import 'package:dirplayer/director/lingo/nodes/expression.dart';
import 'package:dirplayer/director/lingo/nodes/statement.dart';

import '../node.dart';
import '../node_type.dart';

class ThePropExprNode extends ExprNode {
	Node obj;
  String prop;

	ThePropExprNode(this.obj, this.prop) : super(NodeType.kThePropExprNode) {
		obj.parent = this;
	}
	//virtual void writeScriptText(Common::CodeWriter &code, bool dot, bool sum) const;
}
