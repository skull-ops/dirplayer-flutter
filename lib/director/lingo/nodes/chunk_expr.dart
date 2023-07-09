import 'package:dirplayer/common/codewriter.dart';

import '../chunk_expr_type.dart';
import '../constants.dart';
import '../datum.dart';
import '../lingo.dart';
import '../node.dart';
import '../node_type.dart';
import 'expression.dart';

class ChunkExprNode extends ExprNode {
	ChunkExprType chunkType;
	Node first;
	Node last;
	Node string;

	ChunkExprNode(this.chunkType, this.first, this.last, this.string)
		: super(NodeType.kChunkExprNode) {
		first.parent = this;
		last.parent = this;
		string.parent = this;
	}

  @override
  void writeScriptText(CodeWriter code, bool dot, bool sum) {
    code.write(Lingo.getName(chunkTypeNames, type));
    code.write(" ");
    first.writeScriptText(code, dot, sum);
    if (!(last.type == NodeType.kLiteralNode && last.getValue().type == DatumType.kDatumInt && last.getValue().toInt() == 0)) {
      code.write(" to ");
      last.writeScriptText(code, dot, sum);
    }
    code.write(" of ");
    string.writeScriptText(code, false, sum); // we want the string to always be verbose

  }

  @override
  bool hasSpaces(bool dot) {
    return false;
  }

	//virtual void writeScriptText(Common::CodeWriter &code, bool dot, bool sum) const;
}
