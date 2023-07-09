import '../node.dart';
import '../node_type.dart';
import '../opcode.dart';
import 'expression.dart';

class MenuPropExprNode extends ExprNode {
	Node menuID;
	int prop;

	MenuPropExprNode(this.menuID, this.prop)
		: super(NodeType.kMenuPropExprNode) {
		menuID.parent = this;
	}
	//virtual void writeScriptText(Common::CodeWriter &code, bool dot, bool sum) const;
}
