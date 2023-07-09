import 'package:dirplayer/common/codewriter.dart';
import 'package:dirplayer/director/lingo/datum.dart';

import '../node.dart';
import '../node_type.dart';
import 'expression.dart';

class MemberExprNode extends ExprNode {
  String memberType;
	Node memberID;
  Node? castID;

	MemberExprNode(this.memberType, this.memberID, this.castID) : super(NodeType.kMemberExprNode) {
		memberID.parent = this;
    castID?.parent = this;
	}

  @override
  void writeScriptText(CodeWriter code, bool dot, bool sum) {
    bool hasCastID = castID != null && !(castID!.type == NodeType.kLiteralNode && castID!.getValue().type == DatumType.kDatumInt && castID!.getValue().toInt() == 0);
    code.write(memberType);
    if (dot) {
      code.write("(");
      memberID.writeScriptText(code, dot, sum);
      if (hasCastID) {
        code.write(", ");
        castID!.writeScriptText(code, dot, sum);
      }
      code.write(")");
    } else {
      code.write(" ");

      bool parenMemberID = (memberID.type == NodeType.kBinaryOpNode);
      if (parenMemberID) {
        code.write("(");
      }
      memberID.writeScriptText(code, dot, sum);
      if (parenMemberID) {
        code.write(")");
      }

      if (hasCastID) {
        code.write(" of castLib ");

        bool parenCastID = (castID!.type == NodeType.kBinaryOpNode);
        if (parenCastID) {
          code.write("(");
        }
        castID!.writeScriptText(code, dot, sum);
        if (parenCastID) {
          code.write(")");
        }
      }
    }
  }

  @override
  bool hasSpaces(bool dot) {
    return !dot;
  }
}
