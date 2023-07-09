import 'package:dirplayer/common/codewriter.dart';

import '../datum.dart';
import '../node.dart';
import '../node_type.dart';

class CallNode extends Node {
	String name;
	Node argList;

	CallNode(this.name, this.argList) : super(NodeType.kCallNode) {
		argList.parent = this;
		if (argList.getValue().type == DatumType.kDatumArgListNoRet) {
			isStatement = true;
    } else {
			isExpression = true;
    }
	}

	bool noParens() {
    if (isStatement) {
      // TODO: Make a complete list of commonly paren-less commands
      if (name == "put") {
        return true;
      }
      if (name == "return") {
        return true;
      }
    }

    return false;
  }

	bool isMemberExpr() {
    if (isExpression) {
      int nargs = argList.getValue().toNodeList().length;
      if (name == "cast" && (nargs == 1 || nargs == 2)) {
        return true;
      }
      if (name == "member" && (nargs == 1 || nargs == 2)) {
        return true;
      }
      if (name == "script" && (nargs == 1 || nargs == 2)) {
        return true;
      }
      if (name == "castLib" && nargs == 1) {
        return true;
      }
      if (name == "window" && nargs == 1) {
        return true;
      }
    }

    return false;
  }

  @override
  void writeScriptText(CodeWriter code, bool dot, bool sum) {
    if (isExpression && argList.getValue().toNodeList().isEmpty) {
      if (name == "pi") {
        code.write("PI");
        return;
      }
      if (name == "space") {
        code.write("SPACE");
        return;
      }
      if (name == "void") {
        code.write("VOID");
        return;
      }
    }

    if (!dot && isMemberExpr()) {
      /**
       * In some cases, member expressions such as `member 1 of castLib 1` compile
       * to the function call `member(1, 1)`. However, this doesn't parse correctly
       * in pre-dot-syntax versions of Director, and `put(member(1, 1))` does not
       * compile. Therefore, we rewrite these expressions to the verbose syntax when
       * in verbose mode.
       */
      code.write(name);
      code.write(" ");

      var memberID = argList.getValue().toNodeList()[0];
      bool parenMemberID = (memberID.type == NodeType.kBinaryOpNode);
      if (parenMemberID) {
        code.write("(");
      }
      memberID.writeScriptText(code, dot, sum);
      if (parenMemberID) {
        code.write(")");
      }

      if (argList.getValue().toNodeList().length == 2) {
        code.write(" of castLib ");

        var castID = argList.getValue().toNodeList()[1];
        bool parenCastID = (castID.type == NodeType.kBinaryOpNode);
        if (parenCastID) {
          code.write("(");
        }
        castID.writeScriptText(code, dot, sum);
        if (parenCastID) {
          code.write(")");
        }
      }
      return;
    }

    code.write(name);
    if (noParens()) {
      code.write(" ");
      argList.writeScriptText(code, dot, sum);
    } else {
      code.write("(");
      argList.writeScriptText(code, dot, sum);
      code.write(")");
    }
  }

  @override
  bool hasSpaces(bool dot) {
    if (!dot && isMemberExpr()) {
      return true;
    }

    if (noParens()) {
      return true;
    }

    return false;
  }
}
