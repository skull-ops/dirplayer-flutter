import '../node.dart';
import '../node_type.dart';
import 'block.dart';
import 'loop.dart';

class RepeatWithToStmtNode extends LoopNode {
	String varName;
	Node start;
	bool up;
	Node end;
	BlockNode block = BlockNode();

	RepeatWithToStmtNode(int startIndex, this.varName, this.start, this.up, this.end)
		: super(NodeType.kRepeatWithToStmtNode, startIndex) {
		start.parent = this;
		end.parent = this;
		block.parent = this;
	}
	//virtual void writeScriptText(Common::CodeWriter &code, bool dot, bool sum) const;
}
