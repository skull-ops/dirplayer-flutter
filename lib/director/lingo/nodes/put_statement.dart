import 'package:dirplayer/common/codewriter.dart';

import '../constants.dart';
import '../lingo.dart';
import '../node.dart';
import '../node_type.dart';
import '../put_type.dart';
import 'statement.dart';

class PutStmtNode extends StmtNode {
	PutType putType;
	Node variable;
	Node value;

	PutStmtNode(this.putType, this.variable, this.value)
		: super(NodeType.kPutStmtNode) {
		variable.parent = this;
		value.parent = this;
	}

  @override
  void writeScriptText(CodeWriter code, bool dot, bool sum) {
    code.write("put ");
    value.writeScriptText(code, dot, sum);
    code.write(" ");
    code.write(Lingo.getName(putTypeNames, type));
    code.write(" ");
    variable.writeScriptText(code, false, sum); 
  }
}
