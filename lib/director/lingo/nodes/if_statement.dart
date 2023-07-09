import 'package:dirplayer/common/codewriter.dart';
import 'package:dirplayer/director/lingo/node_type.dart';

import '../node.dart';
import 'block.dart';
import 'statement.dart';

class IfStmtNode extends StmtNode {
	bool hasElse = false;
	Node condition;
	var block1 = BlockNode();
	var block2 = BlockNode();

	IfStmtNode(this.condition) : super(NodeType.kIfStmtNode) {
		condition.parent = this;
		block1 = BlockNode();
		block1.parent = this;
		block2 = BlockNode();
		block2.parent = this;
	}

  @override
  void writeScriptText(CodeWriter code, bool dot, bool sum) {
    code.write("if ");
    condition.writeScriptText(code, dot, sum);
    code.write(" then");
    if (sum) {
      if (hasElse) {
        code.write(" / else");
      }
    } else {
      code.writeEmptyLine();
      code.indent();
      block1.writeScriptText(code, dot, sum);
      code.unindent();
      if (hasElse) {
        code.writeLine("else");
        code.indent();
        block2.writeScriptText(code, dot, sum);
        code.unindent();
      }
      code.write("end if");
    }
  }
	
}
