import '../node.dart';
import '../node_type.dart';
import 'block.dart';
import 'loop.dart';

class RepeatWhileStmtNode extends LoopNode {
	Node condition;
	BlockNode block = BlockNode();

	RepeatWhileStmtNode(int startIndex, this.condition)
		: super(NodeType.kRepeatWhileStmtNode, startIndex) {
		condition.parent = this;
		block.parent = this;
	}

	//virtual void writeScriptText(Common::CodeWriter &code, bool dot, bool sum) const;
}
