import 'package:dirplayer/director/lingo/chunk_expr_type.dart';

import '../node.dart';
import '../node_type.dart';
import 'expression.dart';

class LastStringChunkExprNode extends ExprNode {
	ChunkExprType chunkType;
	Node obj;

	LastStringChunkExprNode(this.chunkType, this.obj)
		: super(NodeType.kLastStringChunkExprNode) {
		obj.parent = this;
	}
  
	//virtual void writeScriptText(Common::CodeWriter &code, bool dot, bool sum) const;
}
