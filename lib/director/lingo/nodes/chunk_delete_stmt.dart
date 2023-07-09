import 'package:dirplayer/director/lingo/nodes/statement.dart';

import '../node.dart';
import '../node_type.dart';
import 'expression.dart';

class ChunkDeleteStmtNode extends StmtNode {
	Node chunk;

	ChunkDeleteStmtNode(this.chunk) : super(NodeType.kChunkDeleteStmtNode) {
		chunk.parent = this;
	}
	//virtual void writeScriptText(Common::CodeWriter &code, bool dot, bool sum) const;
	//virtual unsigned int getPrecedence() const;
}
