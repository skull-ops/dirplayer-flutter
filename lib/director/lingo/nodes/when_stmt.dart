import '../node_type.dart';
import 'statement.dart';

class WhenStmtNode extends StmtNode {
	int event;
	String script;

	WhenStmtNode(this.event, this.script) : super(NodeType.kWhenStmtNode);
	//virtual void writeScriptText(Common::CodeWriter &code, bool dot, bool sum) const;
}
