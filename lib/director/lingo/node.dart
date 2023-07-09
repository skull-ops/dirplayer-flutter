import 'package:dirplayer/common/codewriter.dart';
import 'package:dirplayer/director/lingo/datum.dart';

import 'node_type.dart';
import 'nodes/loop.dart';

class Node {
	NodeType type;
	bool isExpression = false;
	bool isStatement = false;
	bool isLabel = false;
	bool isLoop = false;
	Node? parent;

	Node(this.type);
  void writeScriptText(CodeWriter code, bool dot, bool sum) { code.write("[NOT_IMPLEMENTED:$this]"); }

	Datum getValue() {
    return Datum.ofVoid();
  }

  void setValue(Datum val) {
    throw Exception("Cannot set datum of node $this");
  }

  Node? ancestorStatement() {
    Node? ancestor = parent;
    while (ancestor != null && !ancestor.isStatement) {
      ancestor = ancestor.parent;
    }
    return ancestor;
  }
  
	LoopNode? ancestorLoop() {
    Node? ancestor = parent;
    while (ancestor != null && !ancestor.isLoop) {
      ancestor = ancestor.parent;
    }
    return ancestor as LoopNode?;
  }

	bool hasSpaces(bool dot) { 
    throw Exception("Not Implemented ${this}");
  }
}
