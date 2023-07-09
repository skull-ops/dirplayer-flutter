import 'package:dirplayer/director/lingo/nodes/statement.dart';

import '../node.dart';
import '../node_type.dart';

class SoundCmdStmtNode extends StmtNode {
	String cmd;
  Node argList;

	SoundCmdStmtNode(this.cmd, this.argList) : super(NodeType.kSoundCmdStmtNode) {
		argList.parent = this;
	}
	//virtual void writeScriptText(Common::CodeWriter &code, bool dot, bool sum) const;
}
