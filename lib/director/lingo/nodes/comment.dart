import '../node.dart';
import '../node_type.dart';

class CommentNode extends Node {
	String text;

	CommentNode(this.text) : super(NodeType.kCommentNode);
	//virtual void writeScriptText(Common::CodeWriter &code, bool dot, bool sum) const;
}
