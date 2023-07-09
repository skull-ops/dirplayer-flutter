import '../node.dart';
import '../node_type.dart';
import '../opcode.dart';
import 'expression.dart';

class SpriteIntersectsExprNode extends ExprNode {
	Node firstSprite;
	Node secondSprite;

	SpriteIntersectsExprNode(this.firstSprite, this.secondSprite)
		: super(NodeType.kSpriteWithinExprNode) {
		firstSprite.parent = this;
		secondSprite.parent = this;
	}
	//virtual void writeScriptText(Common::CodeWriter &code, bool dot, bool sum) const;
}
