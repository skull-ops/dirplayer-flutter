import 'package:dirplayer/director/lingo/chunk_expr_type.dart';

import '../node.dart';
import '../node_type.dart';
import 'expression.dart';

class StringChunkCountExprNode extends ExprNode {
	ChunkExprType chunkType;
	Node obj;

	StringChunkCountExprNode(this.chunkType, this.obj)
		: super(NodeType.kStringChunkCountExprNode) {
		obj.parent = this;
	}
  
	//virtual void writeScriptText(Common::CodeWriter &code, bool dot, bool sum) const;
}
