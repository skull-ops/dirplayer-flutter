import 'package:dirplayer/director/lingo/nodes/statement.dart';

import '../node.dart';
import '../node_type.dart';
import 'expression.dart';

class ChunkHiliteStmtNode extends StmtNode {
	Node chunk;

	ChunkHiliteStmtNode(this.chunk) : super(NodeType.kChunkHiliteStmtNode) {
		chunk.parent = this;
	}
	//virtual void writeScriptText(Common::CodeWriter &code, bool dot, bool sum) const;
}
