import '../node.dart';
import '../node_type.dart';
import 'block.dart';
import 'label.dart';

enum CaseExpect {
	kCaseExpectEnd,
	kCaseExpectOr,
	kCaseExpectNext,
	kCaseExpectOtherwise
}

class CaseLabelNode extends LabelNode {
	Node value;
	CaseExpect expect;

	CaseLabelNode? nextOr;
	CaseLabelNode? nextLabel;
	BlockNode? block;

	CaseLabelNode(this.value, this.expect) : super(NodeType.kCaseLabelNode) {
		value.parent = this;
	}

	// virtual void writeScriptText(Common::CodeWriter &code, bool dot, bool sum) const;
}
