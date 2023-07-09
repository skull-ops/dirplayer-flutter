import 'package:dirplayer/director/lingo/nodes/expression.dart';
import 'package:dirplayer/director/lingo/nodes/statement.dart';

import '../node.dart';
import '../node_type.dart';

class SpritePropExprNode extends ExprNode {
	Node spriteID;
  int prop;

	SpritePropExprNode(this.spriteID, this.prop) : super(NodeType.kSpritePropExprNode) {
		spriteID.parent = this;
	}
	//virtual void writeScriptText(Common::CodeWriter &code, bool dot, bool sum) const;
}
