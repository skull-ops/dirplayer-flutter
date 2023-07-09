import 'package:dirplayer/director/lingo/nodes/expression.dart';
import 'package:dirplayer/director/lingo/nodes/statement.dart';

import '../node.dart';
import '../node_type.dart';

class SoundPropExprNode extends ExprNode {
	Node soundID;
  int prop;

	SoundPropExprNode(this.soundID, this.prop) : super(NodeType.kSoundPropExprNode) {
		soundID.parent = this;
	}
	//virtual void writeScriptText(Common::CodeWriter &code, bool dot, bool sum) const;
}
