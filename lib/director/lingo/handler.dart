import 'package:dirplayer/director/chunks/script.dart';
import 'package:dirplayer/director/lingo/chunk_expr_type.dart';
import 'package:dirplayer/director/lingo/datum.dart';
import 'package:dirplayer/director/lingo/handler_translate_bytecode.dart';
import 'package:dirplayer/director/lingo/node_type.dart';
import 'package:dirplayer/director/lingo/nodes/case_label.dart';
import 'package:dirplayer/director/lingo/opcode.dart';
import 'package:dirplayer/director/util.dart';

import '../../common/codewriter.dart';
import '../../common/util.dart';
import '../../reader.dart';
import 'ast.dart';
import 'bytecode.dart';
import 'bytecode_tag.dart';
import 'constants.dart';
import 'lingo.dart';
import 'node.dart';
import 'nodes/case_statement.dart';
import 'nodes/chunk_expr.dart';
import 'nodes/comment.dart';
import 'nodes/error.dart';
import 'nodes/if_statement.dart';
import 'nodes/last_string_chunk_expr.dart';
import 'nodes/literal.dart';
import 'nodes/member_expr.dart';
import 'nodes/menu_item_prop_expr.dart';
import 'nodes/menu_prop_expr.dart';
import 'nodes/sound_prop_expr.dart';
import 'nodes/sprite_prop_expr.dart';
import 'nodes/string_chunk_count_expr.dart';
import 'nodes/the_expr.dart';
import 'nodes/the_prop_expr.dart';

class Handler {
  int nameID = 0;
	int vectorPos = 0;
	int compiledLen = 0;
	int compiledOffset = 0;
	int argumentCount = 0;
	int argumentOffset = 0;
	int localsCount = 0;
	int localsOffset = 0;
	int globalsCount = 0;
	int globalsOffset = 0;
	int unknown1 = 0;
	int unknown2 = 0;
	int lineCount = 0;
	int lineOffset = 0;
	int stackHeight = 0;

	List<int> argumentNameIDs = [];
	List<int> localNameIDs = [];
	List<int> globalNameIDs = [];

	ScriptChunk script;
	List<Bytecode> bytecodeArray = [];
	Map<int, int> bytecodePosMap = {};
	List<String> argumentNames = [];
	List<String> localNames = [];
	List<String> globalNames = [];
	String name = "";

	List<Node> stack = [];
	AST? ast;

	bool isGenericEvent = false;

  Handler(this.script);

  void readRecord(Reader stream) {
    nameID = stream.readInt16();
    vectorPos = stream.readUint16();
    compiledLen = stream.readUint32();
    compiledOffset = stream.readUint32();
    argumentCount = stream.readUint16();
    argumentOffset = stream.readUint32();
    localsCount = stream.readUint16();
    localsOffset = stream.readUint32();
    globalsCount = stream.readUint16();
    globalsOffset = stream.readUint32();
    unknown1 = stream.readUint32();
    unknown2 = stream.readUint16();
    lineCount = stream.readUint16();
    lineOffset = stream.readUint32();
    // yet to implement
    if (script.dir.capitalX) {
      stackHeight = stream.readUint32();
    }
  }

	void readData(Reader stream) {
    stream.position = compiledOffset;
    while (stream.position < compiledOffset + compiledLen) {
      int pos = stream.position - compiledOffset;
      int op = stream.readUint8();
      OpCode opcode = OpCode.fromValue(op >= 0x40 ? 0x40 + op % 0x40 : op);
      // argument can be one, two or four bytes
      int obj = 0;
      if (op >= 0xc0) {
        // four bytes
        obj = stream.readInt32();
      } else if (op >= 0x80) {
        // two bytes
        if (opcode == OpCode.kOpPushInt16 || opcode == OpCode.kOpPushInt8) {
          // treat pushint's arg as signed
          // pushint8 may be used to push a 16-bit int in older Lingo
          obj = stream.readInt16();
        } else {
          obj = stream.readUint16();
        }
      } else if (op >= 0x40) {
        // one byte
        if (opcode == OpCode.kOpPushInt8) {
          // treat pushint's arg as signed
          obj = stream.readInt8();
        } else {
          obj = stream.readUint8();
        }
      }
      var bytecode = Bytecode(op, obj, pos);
      bytecodeArray.add(bytecode);
      bytecodePosMap[pos] = bytecodeArray.length - 1;
    }

    argumentNameIDs = readVarnamesTable(stream, argumentCount, argumentOffset);
    localNameIDs = readVarnamesTable(stream, localsCount, localsOffset);
    globalNameIDs = readVarnamesTable(stream, globalsCount, globalsOffset);
  }

  List<int> readVarnamesTable(Reader stream, int count, int offset) {
    stream.position = offset;
    return List.generate(count, (index) => stream.readUint16());
  }

  void readNames() {
    if (!isGenericEvent) {
      name = getName(nameID);
    }
    for (int i = 0; i < argumentNameIDs.length; i++) {
      if (i == 0 && script.isFactory()) {
        continue;
      }
      argumentNames.add(getName(argumentNameIDs[i]));
    }
    for (var nameID in localNameIDs) {
      if (validName(nameID)) {
        localNames.add(getName(nameID));
      }
    }
    for (var nameID in globalNameIDs) {
      if (validName(nameID)) {
        globalNames.add(getName(nameID));
      }
    }
  }

  bool validName(int id) {
    return script.validName(id);
  }

  String getName(int id) {
    return script.getName(id);
  }


	String getArgumentName(int id) {
    if (-1 < id && /*(unsigned)*/id < argumentNameIDs.length) {
      return getName(argumentNameIDs[id]);
    }
    return "UNKNOWN_ARG_$id";
  }

	String getLocalName(int id) {
    if (-1 < id && /*(unsigned)*/id < localNameIDs.length) {
      return getName(localNameIDs[id]);
    }
    return "UNKNOWN_LOCAL_$id";
  }

	Node pop() {
    if (stack.isEmpty) {
      return ErrorNode();
    }

    return stack.removeLast();
  }
  
	int variableMultiplier() {
    // TODO: Determine what version this changed to 1.
    // For now approximating it with the point at which Lctx changed to LctX.
    if (script.dir.capitalX) {
      return 1;
    }
    if (script.dir.version >= 500) {
      return 8;
    }
    return 6;
  }

	Node readVar(int varType) {
    Node castID = Node(NodeType.kNoneNode);
    if (varType == 0x6 && script.dir.version >= 500) { // field cast ID
      castID = pop();
    }
    Node id = pop();

    switch (varType) {
    case 0x1: // global
    case 0x2: // global
    case 0x3: // property/instance
      return id;
    case 0x4: // arg
      {
        String name = getArgumentName(id.getValue().toInt() ~/ variableMultiplier());
        var ref = Datum.ofString(name, type: DatumType.kDatumVarRef);
        return LiteralNode(ref);
      }
    case 0x5: // local
      {
        String name = getLocalName(id.getValue().toInt() ~/ variableMultiplier());
        var ref = Datum.ofString(name, type: DatumType.kDatumVarRef);
        return LiteralNode(ref);
      }
    case 0x6: // field
      return MemberExprNode("field", id, castID);
    default:
      print("findVar: unhandled var type $varType");
      break;
    }
    return ErrorNode();
  }

	String getVarNameFromSet(Bytecode bytecode) {
    String varName;
    switch (bytecode.opcode) {
    case OpCode.kOpSetGlobal:
    case OpCode.kOpSetGlobal2:
      varName = getName(bytecode.obj);
      break;
    case OpCode.kOpSetProp:
      varName = getName(bytecode.obj);
      break;
    case OpCode.kOpSetParam:
      varName = getArgumentName(bytecode.obj ~/ variableMultiplier());
      break;
    case OpCode.kOpSetLocal:
      varName = getLocalName(bytecode.obj ~/ variableMultiplier());
      break;
    default:
      varName = "ERROR";
      break;
    }
    return varName;
  }
	
  Node readV4Property(int propertyType, int propertyID) {
    switch (propertyType) {
    case 0x00:
      {
        if (propertyID <= 0x0b) { // movie property
          var propName = Lingo.getName(moviePropertyNames, propertyID);
          return TheExprNode(propName);
        } else { // last chunk
          var string = pop();
          var chunkType = ChunkExprType.fromValue(propertyID - 0x0b);
          return LastStringChunkExprNode(chunkType, string);
        }
      }
      break;
    case 0x01: // number of chunks
      {
        var string = pop();
        return StringChunkCountExprNode(ChunkExprType.fromValue(propertyID), string);
      }
      break;
    case 0x02: // menu property
      {
        var menuID = pop();
        return MenuPropExprNode(menuID, propertyID);
      }
      break;
    case 0x03: // menu item property
      {
        var menuID = pop();
        var itemID = pop();
        return MenuItemPropExprNode(menuID, itemID, propertyID);
      }
      break;
    case 0x04: // sound property
      {
        var soundID = pop();
        return SoundPropExprNode(soundID, propertyID);
      }
      break;
    case 0x05: // resource property - unused?
      return CommentNode("ERROR: Resource property");
    case 0x06: // sprite property
      {
        var spriteID = pop();
        return SpritePropExprNode(spriteID, propertyID);
      }
      break;
    case 0x07: // animation property
      return TheExprNode(Lingo.getName(animationPropertyNames, propertyID));
    case 0x08: // animation 2 property
      if (propertyID == 0x02 && script.dir.version >= 500) { // the number of castMembers supports castLib selection from Director 5.0
        var castLib = pop();
        if (!(castLib.type == NodeType.kLiteralNode && castLib.getValue().type == DatumType.kDatumInt && castLib.getValue().toInt() == 0)) {
          var castLibNode = MemberExprNode("castLib", castLib, null);
          return ThePropExprNode(castLibNode, Lingo.getName(animation2PropertyNames, propertyID));
        }
      }
      return TheExprNode(Lingo.getName(animation2PropertyNames, propertyID));
    case 0x09: // generic cast member
    case 0x0a: // chunk of cast member
    case 0x0b: // field
    case 0x0c: // chunk of field
    case 0x0d: // digital video
    case 0x0e: // bitmap
    case 0x0f: // sound
    case 0x10: // button
    case 0x11: // shape
    case 0x12: // movie
    case 0x13: // script
    case 0x14: // scriptText
    case 0x15: // chunk of scriptText
      {
        var propName = Lingo.getName(memberPropertyNames, propertyID);
        Node castID = Node(NodeType.kNoneNode);
        if (script.dir.version >= 500) {
          castID = pop();
        }
        var memberID = pop();
        String prefix;
        if (propertyType == 0x0b || propertyType == 0x0c) {
          prefix = "field";
        } else if (propertyType == 0x14 || propertyType == 0x15) {
          prefix = "script";
        } else {
          prefix = (script.dir.version >= 500) ? "member" : "cast";
        }
        var member = MemberExprNode(prefix, memberID, castID);
        Node entity;
        if (propertyType == 0x0a || propertyType == 0x0c || propertyType == 0x15) {
          entity = readChunkRef(member);
        } else {
          entity = member;
        }
        return ThePropExprNode(entity, propName);
      }
      break;
    default:
      break;
    }
    return CommentNode("ERROR: Unknown property type $propertyType");
  }

	Node readChunkRef(Node string) {
    var lastLine = pop();
    var firstLine = pop();
    var lastItem = pop();
    var firstItem = pop();
    var lastWord = pop();
    var firstWord = pop();
    var lastChar = pop();
    var firstChar = pop();

    if (!(firstLine.type == NodeType.kLiteralNode && firstLine.getValue().type == DatumType.kDatumInt && firstLine.getValue().toInt() == 0)) {
      string = ChunkExprNode(ChunkExprType.kChunkLine, firstLine, lastLine, string);
    }
    if (!(firstItem.type == NodeType.kLiteralNode && firstItem.getValue().type == DatumType.kDatumInt && firstItem.getValue().toInt() == 0)) {
      string = ChunkExprNode(ChunkExprType.kChunkItem, firstItem, lastItem, string);
    }
    if (!(firstWord.type == NodeType.kLiteralNode && firstWord.getValue().type == DatumType.kDatumInt && firstWord.getValue().toInt() == 0)) {
      string = ChunkExprNode(ChunkExprType.kChunkWord, firstWord, lastWord, string);
    }
    if (!(firstChar.type == NodeType.kLiteralNode && firstChar.getValue().type == DatumType.kDatumInt && firstChar.getValue().toInt() == 0)) {
      string = ChunkExprNode(ChunkExprType.kChunkChar, firstChar, lastChar, string);
    }

    return string;
  }
  
	void tagLoops() {
    // Tag any jmpifz which is a loop with the loop type
    // (kTagRepeatWhile, kTagRepeatWithIn, kTagRepeatWithTo, kTagRepeatWithDownTo).
    // Tag the instruction which `next repeat` jumps to with kTagNextRepeatTarget.
    // Tag any instructions which are internal loop logic with kTagSkip, so that
    // they will be skipped during translation.

    for (var startIndex = 0; startIndex < bytecodeArray.length; startIndex++) {
      // All loops begin with jmpifz...
      var jmpifz = bytecodeArray[startIndex];
      if (jmpifz.opcode != OpCode.kOpJmpIfZ) {
        continue;
      }

      // ...and end with endrepeat.
      var jmpPos = jmpifz.pos + jmpifz.obj;
      var endIndex = bytecodePosMap[jmpPos]!;
      var endRepeat = bytecodeArray[endIndex - 1];
      if (endRepeat.opcode != OpCode.kOpEndRepeat || (endRepeat.pos - endRepeat.obj) > jmpifz.pos) {
        continue;
      }

      BytecodeTag loopType = identifyLoop(startIndex, endIndex);
      bytecodeArray[startIndex].tag = loopType;

      if (loopType == BytecodeTag.kTagRepeatWithIn) {
        for (int i = startIndex - 7, end = startIndex - 1; i <= end; i++) {
          bytecodeArray[i].tag = BytecodeTag.kTagSkip;
        }
        for (int i = startIndex + 1, end = startIndex + 5; i <= end; i++) {
          bytecodeArray[i].tag = BytecodeTag.kTagSkip;
        }
        bytecodeArray[endIndex - 3].tag = BytecodeTag.kTagNextRepeatTarget; // pushint8 1
        bytecodeArray[endIndex - 3].ownerLoop = startIndex;
        bytecodeArray[endIndex - 2].tag = BytecodeTag.kTagSkip; // add
        bytecodeArray[endIndex - 1].tag = BytecodeTag.kTagSkip; // endrepeat
        bytecodeArray[endIndex - 1].ownerLoop = startIndex;
        bytecodeArray[endIndex].tag = BytecodeTag.kTagSkip; // pop 3
      } else if (loopType == BytecodeTag.kTagRepeatWithTo || loopType == BytecodeTag.kTagRepeatWithDownTo) {
        int conditionStartIndex = bytecodePosMap[endRepeat.pos - endRepeat.obj]!;
        bytecodeArray[conditionStartIndex - 1].tag = BytecodeTag.kTagSkip; // set
        bytecodeArray[conditionStartIndex].tag = BytecodeTag.kTagSkip; // get
        bytecodeArray[startIndex - 1].tag = BytecodeTag.kTagSkip; // lteq / gteq
        bytecodeArray[endIndex - 5].tag = BytecodeTag.kTagNextRepeatTarget; // pushint8 1 / pushint8 -1
        bytecodeArray[endIndex - 5].ownerLoop = startIndex;
        bytecodeArray[endIndex - 4].tag = BytecodeTag.kTagSkip; // get
        bytecodeArray[endIndex - 3].tag = BytecodeTag.kTagSkip; // add
        bytecodeArray[endIndex - 2].tag = BytecodeTag.kTagSkip; // set
        bytecodeArray[endIndex - 1].tag = BytecodeTag.kTagSkip; // endrepeat
        bytecodeArray[endIndex - 1].ownerLoop = startIndex;
      } else if (loopType == BytecodeTag.kTagRepeatWhile) {
        bytecodeArray[endIndex - 1].tag = BytecodeTag.kTagNextRepeatTarget; // endrepeat
        bytecodeArray[endIndex - 1].ownerLoop = startIndex;
      }
    }
  }

	bool isRepeatWithIn(int startIndex, int endIndex) {
    if (startIndex < 7 || startIndex > bytecodeArray.length - 6) {
      return false;
    }
    if (!(bytecodeArray[startIndex - 7].opcode == OpCode.kOpPeek && bytecodeArray[startIndex - 7].obj == 0)) {
      return false;
    }
    if (!(bytecodeArray[startIndex - 6].opcode == OpCode.kOpPushArgList && bytecodeArray[startIndex - 6].obj == 1)) {
      return false;
    }
    if (!(bytecodeArray[startIndex - 5].opcode == OpCode.kOpExtCall && getName(bytecodeArray[startIndex - 5].obj) == "count")) {
      return false;
    }
    if (!(bytecodeArray[startIndex - 4].opcode == OpCode.kOpPushInt8 && bytecodeArray[startIndex - 4].obj == 1)) {
      return false;
    }
    if (!(bytecodeArray[startIndex - 3].opcode == OpCode.kOpPeek && bytecodeArray[startIndex - 3].obj == 0)) {
      return false;
    }
    if (!(bytecodeArray[startIndex - 2].opcode == OpCode.kOpPeek && bytecodeArray[startIndex - 2].obj == 2)) {
      return false;
    }
    if (!(bytecodeArray[startIndex - 1].opcode == OpCode.kOpLtEq)) {
      return false;
    }
    // if (!(bytecodeArray[startIndex].opcode == kOpJmpIfZ))
    //     return false;
    if (!(bytecodeArray[startIndex + 1].opcode == OpCode.kOpPeek && bytecodeArray[startIndex + 1].obj == 2)) {
      return false;
    }
    if (!(bytecodeArray[startIndex + 2].opcode == OpCode.kOpPeek && bytecodeArray[startIndex + 2].obj == 1)) {
      return false;
    }
    if (!(bytecodeArray[startIndex + 3].opcode == OpCode.kOpPushArgList && bytecodeArray[startIndex + 3].obj == 2)) {
      return false;
    }
    if (!(bytecodeArray[startIndex + 4].opcode == OpCode.kOpExtCall && getName(bytecodeArray[startIndex + 4].obj) == "getAt")) {
      return false;
    }
    if (!(bytecodeArray[startIndex + 5].opcode == OpCode.kOpSetGlobal || bytecodeArray[startIndex + 5].opcode == OpCode.kOpSetProp
        || bytecodeArray[startIndex + 5].opcode == OpCode.kOpSetParam || bytecodeArray[startIndex + 5].opcode == OpCode.kOpSetLocal)) {
      return false;
    }

    if (endIndex < 3) {
      return false;
    }
    if (!(bytecodeArray[endIndex - 3].opcode == OpCode.kOpPushInt8 && bytecodeArray[endIndex - 3].obj == 1)) {
      return false;
    }
    if (!(bytecodeArray[endIndex - 2].opcode == OpCode.kOpAdd)) {
      return false;
    }
    // if (!(bytecodeArray[startIndex - 1].opcode == kOpEndRepeat))
    //     return false;
    if (!(bytecodeArray[endIndex].opcode == OpCode.kOpPop && bytecodeArray[endIndex].obj == 3)) {
      return false;
    }

    return true;
  }
  
	BytecodeTag identifyLoop(int startIndex, int endIndex) {
    if (isRepeatWithIn(startIndex, endIndex)) {
      return BytecodeTag.kTagRepeatWithIn;
    }

    if (startIndex < 1) {
      return BytecodeTag.kTagRepeatWhile;
    }

    bool up;
    switch (bytecodeArray[startIndex - 1].opcode) {
    case OpCode.kOpLtEq:
      up = true;
      break;
    case OpCode.kOpGtEq:
      up = false;
      break;
    default:
      return BytecodeTag.kTagRepeatWhile;
    }

    var endRepeat = bytecodeArray[endIndex - 1];
    var conditionStartIndex = bytecodePosMap[endRepeat.pos - endRepeat.obj]!;

    if (conditionStartIndex < 1) {
      return BytecodeTag.kTagRepeatWhile;
    }

    OpCode getOp;
    switch (bytecodeArray[conditionStartIndex - 1].opcode) {
    case OpCode.kOpSetGlobal:
      getOp = OpCode.kOpGetGlobal;
      break;
    case OpCode.kOpSetGlobal2:
      getOp = OpCode.kOpGetGlobal2;
      break;
    case OpCode.kOpSetProp:
      getOp = OpCode.kOpGetProp;
      break;
    case OpCode.kOpSetParam:
      getOp = OpCode.kOpGetParam;
      break;
    case OpCode.kOpSetLocal:
      getOp = OpCode.kOpGetLocal;
      break;
    default:
      return BytecodeTag.kTagRepeatWhile;
    }
    OpCode setOp = bytecodeArray[conditionStartIndex - 1].opcode;
    int varID = bytecodeArray[conditionStartIndex - 1].obj;

    if (!(bytecodeArray[conditionStartIndex].opcode == getOp && bytecodeArray[conditionStartIndex].obj == varID)) {
      return BytecodeTag.kTagRepeatWhile;
    }

    if (endIndex < 5) {
      return BytecodeTag.kTagRepeatWhile;
    }
    if (up) {
      if (!(bytecodeArray[endIndex - 5].opcode == OpCode.kOpPushInt8 && bytecodeArray[endIndex - 5].obj == 1)) {
        return BytecodeTag.kTagRepeatWhile;
      }
    } else {
      if (!(bytecodeArray[endIndex - 5].opcode == OpCode.kOpPushInt8 && bytecodeArray[endIndex - 5].obj == -1)) {
        return BytecodeTag.kTagRepeatWhile;
      }
    }
    if (!(bytecodeArray[endIndex - 4].opcode == getOp && bytecodeArray[endIndex - 4].obj == varID)) {
      return BytecodeTag.kTagRepeatWhile;
    }
    if (!(bytecodeArray[endIndex - 3].opcode == OpCode.kOpAdd)) {
      return BytecodeTag.kTagRepeatWhile;
    }
    if (!(bytecodeArray[endIndex - 2].opcode == setOp && bytecodeArray[endIndex - 2].obj == varID)) {
      return BytecodeTag.kTagRepeatWhile;
    }

    return up ? BytecodeTag.kTagRepeatWithTo : BytecodeTag.kTagRepeatWithDownTo;
  }

  void parse() {
    tagLoops();
    stack.clear();
    ast = AST(this);
    int i = 0;
    while (i < bytecodeArray.length) {
      var bytecode = bytecodeArray[i];
      int pos = bytecode.pos;
      // exit last block if at end
      while (pos == ast!.currentBlock!.endPos) {
        var exitedBlock = ast!.currentBlock!;
        var ancestorStmt = ast!.currentBlock!.ancestorStatement();
        ast!.exitBlock();
        if (ancestorStmt != null) {
          if (ancestorStmt.type == NodeType.kIfStmtNode) {
            var ifStatement = ancestorStmt as IfStmtNode;
            if (ifStatement.hasElse && exitedBlock == ifStatement.block1) {
              ast!.enterBlock(ifStatement.block2);
            }
          } else if (ancestorStmt.type == NodeType.kCaseStmtNode) {
            var caseStmt = ancestorStmt as CaseStmtNode;
            var caseLabel = ast!.currentBlock!.currentCaseLabel;
            if (caseLabel != null) {
              if (caseLabel.expect == CaseExpect.kCaseExpectOtherwise) {
                ast!.currentBlock!.currentCaseLabel = null;
                caseStmt.addOtherwise();
                int otherwiseIndex = bytecodePosMap[caseStmt.potentialOtherwisePos]!;
                bytecodeArray[otherwiseIndex].translation = caseStmt.otherwise;
                ast!.enterBlock(caseStmt.otherwise?.block);
              } else if (caseLabel.expect == CaseExpect.kCaseExpectEnd) {
                ast!.currentBlock!.currentCaseLabel = null;
              }
            }
          }
        }
      }
      var translateSize = translateBytecode(bytecode, i);
      i += translateSize;
    }
  }

  void writeHandlerDefinition(CodeWriter code) {
    bool isMethod = script.isFactory();
    if (!isGenericEvent) {
      if (isMethod) {
        code.write("method ");
      } else {
        code.write("on ");
      }
      code.write(name);
      if (argumentNames.isNotEmpty) {
        code.write(" ");
        for (int i = 0; i < argumentNames.length; i++) {
          if (i > 0) {
            code.write(", ");
          }
          code.write(argumentNames[i]);
        }
      }
    }
  }
  
  void writeBytecodeText(CodeWriter code) {
    bool dotSyntax = script.dir.dotSyntax;
    bool isMethod = script.isFactory();

    if (!isGenericEvent) {
      writeHandlerDefinition(code);
      code.writeEmptyLine();
      code.indent();
    }
    for (var bytecode in bytecodeArray) {
      bytecode.writeBytecodeText(code, dotSyntax);
      code.writeEmptyLine();
    }
    if (!isGenericEvent) {
      code.unindent();
      if (!isMethod) {
        code.writeLine("end");
      }
    }
  }

  @override
  String toString() {
    return "Handler #$name";
  }

	/*
	void writeJSON(Common::JSONWriter &json) const;
  */
}
