import 'package:dirplayer/director/lingo/node_type.dart';

import '../../../common/codewriter.dart';
import '../../chunks/script.dart';
import '../handler.dart';
import '../node.dart';
import 'block.dart';

class HandlerNode extends Node {
	Handler handler;
	BlockNode block = BlockNode();

	HandlerNode(this.handler) : super(NodeType.kHandlerNode) {
		block.parent = this;
	}

	@override
	void writeScriptText(CodeWriter code, bool dot, bool sum) {
    if (handler.isGenericEvent) {
      block.writeScriptText(code, dot, sum);
    } else {
      ScriptChunk script = handler.script;
      bool isMethod = script.isFactory();
      if (isMethod) {
        code.write("method ");
      } else {
        code.write("on ");
      }
      code.write(handler.name);
      if (handler.argumentNames.isNotEmpty) {
        code.write(" ");
        for (int i = 0; i < handler.argumentNames.length; i++) {
          if (i > 0) {
            code.write(", ");
          }
          code.write(handler.argumentNames[i]);
        }
      }
      code.writeEmptyLine();
      code.indent();
      if (isMethod && script.propertyNames.isNotEmpty && handler == script.handlers[0]) {
        code.write("instance ");
        for (int i = 0; i < script.propertyNames.length; i++) {
          if (i > 0) {
            code.write(", ");
          }
          code.write(script.propertyNames[i]);
        }
        code.writeEmptyLine();
      }
      if (handler.globalNames.isNotEmpty) {
        code.write("global ");
        for (int i = 0; i < handler.globalNames.length; i++) {
          if (i > 0) {
            code.write(", ");
          }
          code.write(handler.globalNames[i]);
        }
        code.writeEmptyLine();
      }
      block.writeScriptText(code, dot, sum);
      code.unindent();
      if (!isMethod) {
        code.writeLine("end");
      }
    }
  }
}
