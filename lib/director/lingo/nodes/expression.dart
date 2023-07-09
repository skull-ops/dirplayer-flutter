import '../node.dart';

class ExprNode extends Node {
	ExprNode(super.type) {
		isExpression = true;
	}
}
