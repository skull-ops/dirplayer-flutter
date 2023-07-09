import 'statement.dart';

class LoopNode extends StmtNode {
	int startIndex;

	LoopNode(super.type, this.startIndex) {
		isLoop = true;
	}
}
