import 'package:dirplayer/common/codewriter.dart';
import 'package:dirplayer/director/lingo/node_type.dart';

import '../datum.dart';
import 'expression.dart';

class LiteralNode extends ExprNode {
	Datum value;

	LiteralNode(this.value) : super(NodeType.kLiteralNode);
  
  @override
  void writeScriptText(CodeWriter code, bool dot, bool sum) {
    value.writeScriptText(code, dot, sum);
  }

  @override
  Datum getValue() {
    return value;
  }

  @override
  void setValue(Datum val) {
    value = val;
  }

  @override
  bool hasSpaces(bool dot) {
    return false;
  }
}
