import '../node.dart';
import '../node_type.dart';
import 'block.dart';
import 'loop.dart';

class RepeatWithInStmtNode extends LoopNode {
	String varName;
	Node list;
	BlockNode block = BlockNode();

	RepeatWithInStmtNode(int startIndex, this.varName, this.list)
		: super(NodeType.kRepeatWithInStmtNode, startIndex) {
		list.parent = this;
		block.parent = this;
	}

	//virtual void writeScriptText(Common::CodeWriter &code, bool dot, bool sum) const;
}
