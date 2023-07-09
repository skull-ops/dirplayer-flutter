import '../node.dart';
import '../node_type.dart';
import 'block.dart';
import 'statement.dart';

class TellStmtNode extends StmtNode {
	Node window;
	BlockNode block = BlockNode();

	TellStmtNode(this.window) : super(NodeType.kTellStmtNode) {
		window.parent = this;
		block.parent = this;
	}
	//virtual void writeScriptText(Common::CodeWriter &code, bool dot, bool sum) const;
}
