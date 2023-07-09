import '../../../common/codewriter.dart';
import '../node.dart';
import '../node_type.dart';
import 'case_label.dart';

class BlockNode extends Node {
	List<Node> children = [];

	// for use during translation:
	int endPos = -1;
	CaseLabelNode? currentCaseLabel;

	BlockNode() : super(NodeType.kBlockNode);
  
  @override
	void writeScriptText(CodeWriter code, bool dot, bool sum) {
    for (var child in children) {
      child.writeScriptText(code, dot, sum);
      code.writeEmptyLine();
    }
  }

	void addChild(Node child) {
    child.parent = this;
	  children.add(child);
  }
}
