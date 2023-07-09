import '../node.dart';
import '../node_type.dart';
import '../opcode.dart';
import 'expression.dart';

class MenuItemPropExprNode extends ExprNode {
	Node menuID;
	Node itemID;
  int prop;

	MenuItemPropExprNode(this.menuID, this.itemID, this.prop)
		: super(NodeType.kMenuPropExprNode) {
		menuID.parent = this;
    itemID.parent = this;
	}
	//virtual void writeScriptText(Common::CodeWriter &code, bool dot, bool sum) const;
}
