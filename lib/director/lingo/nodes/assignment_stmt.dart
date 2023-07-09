import 'package:dirplayer/common/codewriter.dart';

import '../node.dart';
import '../node_type.dart';
import 'statement.dart';

class AssignmentStmtNode extends StmtNode {
	Node variable;
	Node value;
	bool forceVerbose = false;

	AssignmentStmtNode(this.variable, this.value/*, this.forceVerbose = false*/)
		: super(NodeType.kAssignmentStmtNode) {
		variable.parent = this;
		value.parent = this;
	}

  @override
  void writeScriptText(CodeWriter code, bool dot, bool sum) {
    if (!dot || forceVerbose) {
      code.write("set ");
      variable.writeScriptText(code, false, sum); // we want the variable to always be verbose
      code.write(" to ");
      value.writeScriptText(code, dot, sum);
    } else {
      variable.writeScriptText(code, dot, sum);
      code.write(" = ");
      value.writeScriptText(code, dot, sum);
    }
  }
}
