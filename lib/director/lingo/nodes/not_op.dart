import '../node.dart';
import '../node_type.dart';
import 'expression.dart';

class NotOpNode extends ExprNode {
	Node operand;

	NotOpNode(this.operand) : super(NodeType.kNotOpNode) {
		operand.parent = this;
	}
	//virtual void writeScriptText(Common::CodeWriter &code, bool dot, bool sum) const;
	//virtual unsigned int getPrecedence() const;
}
