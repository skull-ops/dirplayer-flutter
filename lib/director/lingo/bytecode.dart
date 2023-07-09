import 'package:dirplayer/common/codewriter.dart';
import 'package:dirplayer/director/lingo/opcode.dart';

import '../../common/util.dart';
import '../util.dart';
import 'bytecode_tag.dart';
import 'lingo.dart';
import 'node.dart';

class Bytecode {
	int opID;
	OpCode opcode = OpCode.kOpInvalid;
	int obj;
	int pos;
	BytecodeTag tag = BytecodeTag.kTagNone;
	int ownerLoop = UINT32_MAX;
	Node? translation;

	Bytecode(this.opID, this.obj, this.pos) {
		opcode = OpCode.fromValue(opID >= 0x40 ? 0x40 + opID % 0x40 : opID);
	}

  void writeBytecodeText(CodeWriter code, bool dotSyntax) {
    var bytecode = this;
    
    code.write(posToString(bytecode.pos));
    code.write(" ");
    code.write(Lingo.getOpcodeName(bytecode.opID));
    switch (bytecode.opcode) {
    case OpCode.kOpJmp:
    case OpCode.kOpJmpIfZ:
      code.write(" ");
      code.write(posToString(bytecode.pos + bytecode.obj));
      break;
    case OpCode.kOpEndRepeat:
      code.write(" ");
      code.write(posToString(bytecode.pos - bytecode.obj));
      break;
    case OpCode.kOpPushFloat32:
      code.write(" ");
      code.write(floatToString(int32BytesToFloat(bytecode.obj)));
      break;
    default:
      if (bytecode.opID > 0x40) {
        code.write(" ");
        code.write(bytecode.obj.toString());
      }
      break;
    }
    if (bytecode.translation != null) {
      code.write(" ...");
      while (code.lineWidth() < 49) {
        code.write(".");
      }
      code.write(" ");
      if (bytecode.translation!.isExpression) {
        code.write("<");
      }
      bytecode.translation!.writeScriptText(code, dotSyntax, true);
      if (bytecode.translation!.isExpression) {
        code.write(">");
      }
    }
  }
}
