
import 'package:dirplayer/director/lingo/node_type.dart';

import '../../common/codewriter.dart';
import 'handler.dart';
import 'node.dart';
import 'nodes/block.dart';
import 'nodes/handler.dart';

class AST {
	late HandlerNode root;
	BlockNode? currentBlock;

	AST(Handler handler) {
		root = HandlerNode(handler);
		currentBlock = root.block;
	}

	void writeScriptText(CodeWriter code, bool dot, bool sum) {
    root.writeScriptText(code, dot, sum);
  }

	void addStatement(Node statement) {
    currentBlock!.addChild(statement);
  }
  
	void enterBlock(BlockNode? block) {
    currentBlock = block;
  }

	void exitBlock() {
    var ancestorStatement = currentBlock?.ancestorStatement();
    if (ancestorStatement == null) {
      currentBlock = null;
      return;
    }

    var block = ancestorStatement.parent;
    if (block == null || block.type != NodeType.kBlockNode) {
      currentBlock = null;
      return;
    }

    currentBlock = block as BlockNode;
  }
}
