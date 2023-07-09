import '../node.dart';
import '../node_type.dart';
import 'expression.dart';

class NewObjNode extends ExprNode {
	String objType;
	Node objArgs;

	NewObjNode(this.objType, this.objArgs) : super(NodeType.kNewObjNode);
	//virtual void writeScriptText(Common::CodeWriter &code, bool dot, bool sum) const;
}
