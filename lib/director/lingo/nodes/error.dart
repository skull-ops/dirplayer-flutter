import 'package:dirplayer/director/lingo/node_type.dart';

import 'expression.dart';

class ErrorNode extends ExprNode {
	ErrorNode() : super(NodeType.kErrorNode);
	//virtual void writeScriptText(Common::CodeWriter &code, bool dot, bool sum) const;
	//virtual bool hasSpaces(bool dot);
}
