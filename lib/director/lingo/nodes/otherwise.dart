import '../node_type.dart';
import 'block.dart';
import 'label.dart';

class OtherwiseNode extends LabelNode {
	BlockNode block = BlockNode();

	OtherwiseNode() : super(NodeType.kOtherwiseNode) {
		block.parent = this;
	}
	
  //virtual void writeScriptText(Common::CodeWriter &code, bool dot, bool sum) const;
}
