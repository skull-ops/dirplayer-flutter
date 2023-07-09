import '../node.dart';
import '../node_type.dart';
import 'case_label.dart';
import 'otherwise.dart';
import 'statement.dart';

class CaseStmtNode extends StmtNode {
	Node value;
	CaseLabelNode? firstLabel;
	OtherwiseNode? otherwise;

	// for use during translation:
	int endPos = -1;
	int potentialOtherwisePos = -1;

	CaseStmtNode(this.value) : super(NodeType.kCaseStmtNode) {
		value.parent = this;
	}
	
  //virtual void writeScriptText(Common::CodeWriter &code, bool dot, bool sum) const;
	
  void addOtherwise() {
    otherwise = OtherwiseNode();
    otherwise!.parent = this;
    otherwise!.block.endPos = endPos;
  }
}
