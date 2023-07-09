import 'dart:typed_data';

import 'package:dirplayer/director/lingo/bytecode_tag.dart';
import 'package:dirplayer/director/lingo/datum/int.dart';
import 'package:dirplayer/director/lingo/datum/list.dart';
import 'package:dirplayer/director/lingo/datum/node_list.dart';
import 'package:dirplayer/director/lingo/node_type.dart';

import 'bytecode.dart';
import 'datum.dart';
import 'handler.dart';
import 'lingo.dart';
import 'node.dart';
import 'nodes/assignment_stmt.dart';
import 'nodes/binary_op.dart';
import 'nodes/block.dart';
import 'nodes/call.dart';
import 'nodes/case_label.dart';
import 'nodes/case_statement.dart';
import 'nodes/chunk_delete_stmt.dart';
import 'nodes/chunk_hilite_stmt.dart';
import 'nodes/comment.dart';
import 'nodes/end_case.dart';
import 'nodes/error.dart';
import 'nodes/exit_repeat_stmt.dart';
import 'nodes/exit_stmt.dart';
import 'nodes/if_statement.dart';
import 'nodes/inverse_op.dart';
import 'nodes/literal.dart';
import 'nodes/member_expr.dart';
import 'nodes/new_obj.dart';
import 'nodes/next_repeat_stmt.dart';
import 'nodes/not_op.dart';
import 'nodes/obj_bracket_expr.dart';
import 'nodes/obj_call.dart';
import 'nodes/obj_call_v4.dart';
import 'nodes/obj_prop_expr.dart';
import 'nodes/obj_prop_index_expr.dart';
import 'nodes/put_statement.dart';
import 'nodes/repeat_while_stmt.dart';
import 'nodes/repeat_with_in_stmt.dart';
import 'nodes/repeat_with_to_stmt.dart';
import 'nodes/sound_cmd_stmt.dart';
import 'nodes/sprite_intersects_expr.dart';
import 'nodes/sprite_within_expr.dart';
import 'nodes/tell_stmt.dart';
import 'nodes/the_expr.dart';
import 'nodes/variable.dart';
import 'nodes/when_stmt.dart';
import 'opcode.dart';
import 'put_type.dart';

extension TranslateBytecode on Handler {
  int translateBytecode(Bytecode bytecode, int index) {
    if (bytecode.tag == BytecodeTag.kTagSkip || bytecode.tag == BytecodeTag.kTagNextRepeatTarget) {
      // This is internal loop logic. Skip it.
      return 1;
    }

    Node? translation;
    BlockNode? nextBlock;

    switch (bytecode.opcode) {
    case OpCode.kOpRet:
    case OpCode.kOpRetFactory:
      if (index == bytecodeArray.length - 1) {
        return 1; // end of handler
      }
      translation = ExitStmtNode();
      break;
    case OpCode.kOpPushZero:
      translation = LiteralNode(Datum.ofInt(0));
      break;
    case OpCode.kOpMul:
    case OpCode.kOpAdd:
    case OpCode.kOpSub:
    case OpCode.kOpDiv:
    case OpCode.kOpMod:
    case OpCode.kOpJoinStr:
    case OpCode.kOpJoinPadStr:
    case OpCode.kOpLt:
    case OpCode.kOpLtEq:
    case OpCode.kOpNtEq:
    case OpCode.kOpEq:
    case OpCode.kOpGt:
    case OpCode.kOpGtEq:
    case OpCode.kOpAnd:
    case OpCode.kOpOr:
    case OpCode.kOpContainsStr:
    case OpCode.kOpContains0Str:
      {
        var b = pop();
        var a = pop();
        translation = BinaryOpNode(bytecode.opcode, a, b);
      }
      break;
    case OpCode.kOpInv:
      {
        var x = pop();
        translation = InverseOpNode(x);
      }
      break;
    case OpCode.kOpNot:
      {
        var x = pop();
        translation = NotOpNode(x);
      }
      break;
    case OpCode.kOpGetChunk:
      {
        var string = pop();
        translation = readChunkRef(string);
      }
      break;
    case OpCode.kOpHiliteChunk:
      {
        Node castID = Node(NodeType.kNoneNode);
        if (script.dir.version >= 500) {
          castID = pop();
        }
        var fieldID = pop();
        var field = MemberExprNode("field", fieldID, castID);
        var chunk = readChunkRef(field);
        if (chunk.type == NodeType.kCommentNode) { // error comment
          translation = chunk;
        } else {
          translation = ChunkHiliteStmtNode(chunk);
        }
      }
      break;
    case OpCode.kOpOntoSpr:
      {
        var secondSprite = pop();
        var firstSprite = pop();
        translation = SpriteIntersectsExprNode(firstSprite, secondSprite);
      }
      break;
    case OpCode.kOpIntoSpr:
      {
        var secondSprite = pop();
        var firstSprite = pop();
        translation = SpriteWithinExprNode(firstSprite, secondSprite);
      }
      break;
    case OpCode.kOpGetField:
      {
        Node castID = Node(NodeType.kNoneNode);
        if (script.dir.version >= 500) {
          castID = pop();
        }
        var fieldID = pop();
        translation = MemberExprNode("field", fieldID, castID);
      }
      break;
    case OpCode.kOpStartTell:
      {
        var window = pop();
        var tellStmt = TellStmtNode(window);
        translation = tellStmt;
        nextBlock = tellStmt.block;
      }
      break;
    case OpCode.kOpEndTell:
      {
        ast!.exitBlock();
        return 1;
      }
      break;
    case OpCode.kOpPushList:
      {
        var list = pop();
        (list.getValue() as NodeListDatum).type = DatumType.kDatumList;
        translation = list;
      }
      break;
    case OpCode.kOpPushPropList:
      {
        var list = pop();
        var listValues = list.getValue().toList();
        assert(listValues.length % 2 == 0);
        var entryCount = listValues.length ~/ 2;
        var entries = List.generate(entryCount, (index) {
          var keyIndex = index * 2;
          var valueIndex = keyIndex + 1;

          return MapEntry(listValues[keyIndex], listValues[valueIndex]);
        });

        var newValue = Datum.ofPropList(Map.fromEntries(entries));
        list.setValue(newValue);

        translation = list;
      }
      break;
    case OpCode.kOpSwap:
      if (stack.length >= 2) {
        var tmp = stack[stack.length - 1];
        stack[stack.length - 1] = stack[stack.length - 2];
        stack[stack.length - 2] = tmp;
        //std::swap(stack[stack.length - 1], stack[stack.length - 2]);
      } else {
        print("kOpSwap: Stack too small!");
      }
      return 1;
    case OpCode.kOpPushInt8:
    case OpCode.kOpPushInt16:
    case OpCode.kOpPushInt32:
      {
        var i = Datum.ofInt(bytecode.obj);
        translation = LiteralNode(i);
      }
      break;
    case OpCode.kOpPushFloat32:
      {
        //throw Exception("TODO");
        // TODO check if this works
        var val = Int32List.fromList([bytecode.obj])
          .buffer
          .asFloat32List()
          .first;

        //var f = Datum.ofFloat(*(float *)(&bytecode.obj));
        var f = Datum.ofFloat(val);
        //print("push float ${bytecode.obj} -> $val");
        translation = LiteralNode(f);
      }
      break;
    case OpCode.kOpPushArgListNoRet:
      {
        var argCount = bytecode.obj;
        List<Node> args = List.generate(argCount, (index) => pop());
        var argList = Datum.ofNodeList(DatumType.kDatumArgListNoRet, args);
        translation = LiteralNode(argList);
      }
      break;
    case OpCode.kOpPushArgList:
      {
        var argCount = bytecode.obj;
        List<Node> args = List.generate(argCount, (index) => pop());
        var argList = Datum.ofNodeList(DatumType.kDatumArgList, args);
        translation = LiteralNode(argList);
      }
      break;
    case OpCode.kOpPushCons:
      {
        int literalID = bytecode.obj ~/ variableMultiplier();
        if (-1 < literalID && /*(unsigned)*/literalID < script.literals.length) {
          translation = LiteralNode(script.literals[literalID].value!);
        } else {
          translation = ErrorNode();
        }
        break;
      }
    case OpCode.kOpPushSymb:
      {
        var sym = Datum.ofSymbol(getName(bytecode.obj));
        translation = LiteralNode(sym);
      }
      break;
    case OpCode.kOpPushVarRef:
      {
        // TODO check this
        var ref = Datum.ofString(getName(bytecode.obj), type: DatumType.kDatumVarRef);
        translation = LiteralNode(ref);
      }
      break;
    case OpCode.kOpGetGlobal:
    case OpCode.kOpGetGlobal2:
      {
        var name = getName(bytecode.obj);
        translation = VarNode(name);
      }
      break;
    case OpCode.kOpGetProp:
      translation = VarNode(getName(bytecode.obj));
      break;
    case OpCode.kOpGetParam:
      translation = VarNode(getArgumentName(bytecode.obj ~/ variableMultiplier()));
      break;
    case OpCode.kOpGetLocal:
      translation = VarNode(getLocalName(bytecode.obj ~/ variableMultiplier()));
      break;
    case OpCode.kOpSetGlobal:
    case OpCode.kOpSetGlobal2:
      {
        var varName = getName(bytecode.obj);
        var _var = VarNode(varName);
        var value = pop();
        translation = AssignmentStmtNode(_var, value);
      }
      break;
    case OpCode.kOpSetProp:
      {
        var _var = VarNode(getName(bytecode.obj));
        var value = pop();
        translation = AssignmentStmtNode(_var, value);
      }
      break;
    case OpCode.kOpSetParam:
      {
        var _var = VarNode(getArgumentName(bytecode.obj ~/ variableMultiplier()));
        var value = pop();
        translation = AssignmentStmtNode(_var, value);
      }
      break;
    case OpCode.kOpSetLocal:
      {
        var _var = VarNode(getLocalName(bytecode.obj ~/ variableMultiplier()));
        var value = pop();
        translation = AssignmentStmtNode(_var, value);
      }
      break;
    case OpCode.kOpJmp:
      {
        int targetPos = bytecode.pos + bytecode.obj;
        int targetIndex = bytecodePosMap[targetPos]!;
        var targetBytecode = bytecodeArray[targetIndex];
        var ancestorLoop = ast?.currentBlock?.ancestorLoop();
        if (ancestorLoop != null) {
          if (bytecodeArray[targetIndex - 1].opcode == OpCode.kOpEndRepeat && bytecodeArray[targetIndex - 1].ownerLoop == ancestorLoop.startIndex) {
            translation = ExitRepeatStmtNode();
            break;
          } else if (bytecodeArray[targetIndex].tag == BytecodeTag.kTagNextRepeatTarget && bytecodeArray[targetIndex].ownerLoop == ancestorLoop.startIndex) {
            translation = NextRepeatStmtNode();
            break;
          }
        }
        var nextBytecode = bytecodeArray[index + 1];
        var ancestorStatement = ast?.currentBlock?.ancestorStatement();
        if (ancestorStatement != null && nextBytecode.pos == ast!.currentBlock!.endPos) {
          if (ancestorStatement.type == NodeType.kIfStmtNode) {
            var ifStmt = ancestorStatement as IfStmtNode;
            if (ast!.currentBlock == ifStmt.block1) {
              ifStmt.hasElse = true;
              ifStmt.block2.endPos = targetPos;
              return 1; // if statement amended, nothing to push
            }
          } else if (ancestorStatement.type == NodeType.kCaseStmtNode) {
            var caseStmt = ancestorStatement as CaseStmtNode;
            caseStmt.potentialOtherwisePos = bytecode.pos;
            caseStmt.endPos = targetPos;
            targetBytecode.tag = BytecodeTag.kTagEndCase;
            return 1;
          }
        }
        if (targetBytecode.opcode == OpCode.kOpPop && targetBytecode.obj == 1) {
          // This is a case statement starting with 'otherwise'
          var value = pop();
          var caseStmt = CaseStmtNode(value);
          caseStmt.endPos = targetPos;
          targetBytecode.tag = BytecodeTag.kTagEndCase;
          caseStmt.addOtherwise();
          translation = caseStmt;
          nextBlock = caseStmt.otherwise!.block;
          break;
        }
        translation = CommentNode("ERROR: Could not identify jmp");
      }
      break;
    case OpCode.kOpEndRepeat:
      // This should normally be tagged kTagSkip or kTagNextRepeatTarget and skipped.
      translation = CommentNode("ERROR: Stray endrepeat");
      break;
    case OpCode.kOpJmpIfZ:
      {
        int endPos = bytecode.pos + bytecode.obj;
        int endIndex = bytecodePosMap[endPos]!;
        switch (bytecode.tag) {
        case BytecodeTag.kTagRepeatWhile:
          {
            var condition = pop();
            var loop = RepeatWhileStmtNode(index, condition);
            loop.block.endPos = endPos;
            translation = loop;
            nextBlock = loop.block;
          }
          break;
        case BytecodeTag.kTagRepeatWithIn:
          {
            var list = pop();
            String varName = getVarNameFromSet(bytecodeArray[index + 5]);
            var loop = RepeatWithInStmtNode(index, varName, list);
            loop.block.endPos = endPos;
            translation = loop;
            nextBlock = loop.block;
          }
          break;
        case BytecodeTag.kTagRepeatWithTo:
        case BytecodeTag.kTagRepeatWithDownTo:
          {
            bool up = (bytecode.tag == BytecodeTag.kTagRepeatWithTo);
            var end = pop();
            var start = pop();
            var endRepeat = bytecodeArray[endIndex - 1];
            int conditionStartIndex = bytecodePosMap[endRepeat.pos - endRepeat.obj]!;
            String varName = getVarNameFromSet(bytecodeArray[conditionStartIndex - 1]);
            var loop = RepeatWithToStmtNode(index, varName, start, up, end);
            loop.block.endPos = endPos;
            translation = loop;
            nextBlock = loop.block;
          }
          break;
        default:
          {
            var condition = pop();
            var ifStmt = IfStmtNode(condition);
            ifStmt.block1.endPos = endPos;
            translation = ifStmt;
            nextBlock = ifStmt.block1;
          }
          break;
        }
      }
      break;
    case OpCode.kOpLocalCall:
      {
        var argList = pop();
        translation = CallNode(script.handlers[bytecode.obj].name, argList);
      }
      break;
    case OpCode.kOpExtCall:
    case OpCode.kOpTellCall:
      {
        String name = getName(bytecode.obj);
        var argList = pop();
        bool isStatement = (argList.getValue().type == DatumType.kDatumArgListNoRet);
        var rawArgList = argList.getValue().toNodeList();
        int nargs = rawArgList.length;
        if (isStatement && name == "sound" && nargs > 0 && rawArgList[0].type == NodeType.kLiteralNode && rawArgList[0].getValue().type == DatumType.kDatumSymbol) {
          String cmd = rawArgList[0].getValue().stringValue();
          rawArgList.removeAt(0);
          translation = SoundCmdStmtNode(cmd, argList);
        } else {
          translation = CallNode(name, argList);
        }
      }
      break;
    case OpCode.kOpObjCallV4:
      {
        var object = readVar(bytecode.obj);
        var argList = pop();
        var rawArgList = argList.getValue().toNodeList();
        if (rawArgList.isNotEmpty) {
          // first arg is a symbol
          // replace it with a variable
          rawArgList[0] = VarNode(rawArgList[0].getValue().stringValue());
        }
        translation = ObjCallV4Node(object, argList);
      }
      break;
    case OpCode.kOpPut:
      {
        PutType putType = PutType.fromValue((bytecode.obj >> 4) & 0xF);
        int varType = bytecode.obj & 0xF;
        var _var = readVar(varType);
        var val = pop();
        translation = PutStmtNode(putType, _var, val);
      }
      break;
    case OpCode.kOpPutChunk:
      {
        PutType putType = PutType.fromValue((bytecode.obj >> 4) & 0xF);
        int varType = bytecode.obj & 0xF;
        var _var = readVar(varType);
        var chunk = readChunkRef(_var);
        var val = pop();
        if (chunk.type == NodeType.kCommentNode) { // error comment
          translation = chunk;
        } else {
          translation = PutStmtNode(putType, chunk, val);
        }
      }
      break;
    case OpCode.kOpDeleteChunk:
      {
        var _var = readVar(bytecode.obj);
        var chunk = readChunkRef(_var);
        if (chunk.type == NodeType.kCommentNode) { // error comment
          translation = chunk;
        } else {
          translation = ChunkDeleteStmtNode(chunk);
        }
      }
      break;
    case OpCode.kOpGet:
      {
        int propertyID = pop().getValue().toInt();
        translation = readV4Property(bytecode.obj, propertyID);
      }
      break;
    case OpCode.kOpSet:
      {
        int propertyID = pop().getValue().toInt();
        var value = pop();
        if (bytecode.obj == 0x00 && 0x01 <= propertyID && propertyID <= 0x05 && value.getValue().type == DatumType.kDatumString) {
          // This is either a `set eventScript to "script"` or `when event then script` statement.
          // If the script starts with a space, it's probably a when statement.
          // If the script contains a line break, it's definitely a when statement.
          String script = value.getValue().stringValue();
          if (script.isNotEmpty && (script[0] == ' ' || script.contains('\r'))) {
            translation = WhenStmtNode(propertyID, script);
          }
        }
        if (translation == null) {
          var prop = readV4Property(bytecode.obj, propertyID);
          if (prop.type == NodeType.kCommentNode) { // error comment
            translation = prop;
          } else {
            translation = AssignmentStmtNode(prop, value);//, true);
            (translation as AssignmentStmtNode).forceVerbose = true;
          }
        }
      }
      break;
    case OpCode.kOpGetMovieProp:
      translation = TheExprNode(getName(bytecode.obj));
      break;
    case OpCode.kOpSetMovieProp:
      {
        var value = pop();
        var prop = TheExprNode(getName(bytecode.obj));
        translation = AssignmentStmtNode(prop, value);
      }
      break;
    case OpCode.kOpGetObjProp:
    case OpCode.kOpGetChainedProp:
      {
        var object = pop();
        translation = ObjPropExprNode(object, getName(bytecode.obj));
      }
      break;
    case OpCode.kOpSetObjProp:
      {
        var value = pop();
        var object = pop();
        var prop = ObjPropExprNode(object, getName(bytecode.obj));
        translation = AssignmentStmtNode(prop, value);
      }
      break;
    case OpCode.kOpPeek:
      {
        // This op denotes the beginning of a 'repeat with ... in list' statement or a case in a cases statement.

        // In a 'repeat with ... in list' statement, this peeked value is the list.
        // In a cases statement, this is the switch expression.

        var prevLabel = ast!.currentBlock!.currentCaseLabel;

        // This must be a case. Find the comparison against the switch expression.
        var originalStackSize = stack.length;
        int currIndex = index + 1;
        Bytecode currBytecode = bytecodeArray[currIndex];
        do {
          translateBytecode(currBytecode, currIndex);
          currIndex += 1;
          currBytecode = bytecodeArray[currIndex];
        } while (
          currIndex < bytecodeArray.length
          && !(stack.length == originalStackSize + 1 && (currBytecode.opcode == OpCode.kOpEq || currBytecode.opcode == OpCode.kOpNtEq))
        );
        if (currIndex >= bytecodeArray.length) {
          bytecode.translation = CommentNode("ERROR: Expected eq or nteq!");
          ast!.addStatement(bytecode.translation!);
          return currIndex - index + 1;
        }

        // If the comparison is <>, this is followed by another, equivalent case.
        // (e.g. this could be case1 in `case1, case2: statement`)
        bool notEq = (currBytecode.opcode == OpCode.kOpNtEq);
        Node caseValue = pop(); // This is the value the switch expression is compared against.

        currIndex += 1;
        currBytecode = bytecodeArray[currIndex];
        if (currIndex >= bytecodeArray.length || currBytecode.opcode != OpCode.kOpJmpIfZ) {
          bytecode.translation = CommentNode("ERROR: Expected jmpifz!");
          ast!.addStatement(bytecode.translation!);
          return currIndex - index + 1;
        }

        var jmpifz = currBytecode;
        var jmpPos = jmpifz.pos + jmpifz.obj;
        int targetIndex = bytecodePosMap[jmpPos]!;
        var targetBytecode = bytecodeArray[targetIndex];
        var prevFromTarget = bytecodeArray[targetIndex - 1];
        CaseExpect expect;
        if (notEq) {
          expect = CaseExpect.kCaseExpectOr; // Expect an equivalent case after this one.
        } else if (targetBytecode.opcode == OpCode.kOpPeek) {
          expect = CaseExpect.kCaseExpectNext; // Expect a different case after this one.
        } else if (targetBytecode.opcode == OpCode.kOpPop
            && targetBytecode.obj == 1
            && (prevFromTarget.opcode != OpCode.kOpJmp || prevFromTarget.pos + prevFromTarget.obj == targetBytecode.pos)) {
          expect = CaseExpect.kCaseExpectEnd; // Expect the end of the switch statement.
        } else {
          expect = CaseExpect.kCaseExpectOtherwise; // Expect an 'otherwise' block.
        }

        var currLabel = CaseLabelNode(caseValue, expect);
        jmpifz.translation = currLabel;
        ast!.currentBlock!.currentCaseLabel = currLabel;

        if (prevLabel == null) {
          var peekedValue = pop();
          var caseStmt = CaseStmtNode(peekedValue);
          caseStmt.firstLabel = currLabel;
          currLabel.parent = caseStmt;
          bytecode.translation = caseStmt;
          ast!.addStatement(caseStmt);
        } else if (prevLabel.expect == CaseExpect.kCaseExpectOr) {
          prevLabel.nextOr = currLabel;
          currLabel.parent = prevLabel;
        } else if (prevLabel.expect == CaseExpect.kCaseExpectNext) {
          prevLabel.nextLabel = currLabel;
          currLabel.parent = prevLabel;
        }

        // The block doesn't start until the after last equivalent case,
        // so don't create a block yet if we're expecting an equivalent case.
        if (currLabel.expect != CaseExpect.kCaseExpectOr) {
          currLabel.block = BlockNode();
          currLabel.block!.parent = currLabel;
          currLabel.block!.endPos = jmpPos;
          ast!.enterBlock(currLabel.block);
        }

        return currIndex - index + 1;
      }
      break;
    case OpCode.kOpPop:
      {
        // Pop instructions in 'repeat with in' loops are tagged kTagSkip and skipped.
        if (bytecode.tag == BytecodeTag.kTagEndCase) {
          // We've already recognized this as the end of a case statement.
          // Attach an 'end case' node for the summary only.
          bytecode.translation = EndCaseNode();
          return 1;
        }
        if (bytecode.obj == 1 && stack.length == 1) {
          // We have an unused value on the stack, so this must be the end
          // of a case statement with no labels.
          var value = pop();
          translation = CaseStmtNode(value);
          break;
        }
        // Otherwise, this pop instruction occurs before a 'return' within
        // a case statement. No translation needed.
        return 1;
      }
      break;
    case OpCode.kOpTheBuiltin:
      {
        pop(); // empty arglist
        translation = TheExprNode(getName(bytecode.obj));
      }
      break;
    case OpCode.kOpObjCall:
      {
        String method = getName(bytecode.obj);
        var argList = pop();
        var rawArgList = argList.getValue().toNodeList();
        var nargs = rawArgList.length;
        if (method == "getAt" && nargs == 2)  {
          // obj.getAt(i) => obj[i]
          var obj = rawArgList[0];
          var prop = rawArgList[1];
          translation = ObjBracketExprNode(obj, prop);
        } else if (method == "setAt" && nargs == 3) {
          // obj.setAt(i) => obj[i] = val
          var obj = rawArgList[0];
          var prop = rawArgList[1];
          var val = rawArgList[2];
          Node propExpr = ObjBracketExprNode(obj, prop);
          translation = AssignmentStmtNode(propExpr, val);
        } else if ((method == "getProp" || method == "getPropRef") && (nargs == 3 || nargs == 4) && rawArgList[1].getValue().type == DatumType.kDatumSymbol) {
          // obj.getProp(#prop, i) => obj.prop[i]
          // obj.getProp(#prop, i, i2) => obj.prop[i..i2]
          var obj = rawArgList[0];
          String propName  = rawArgList[1].getValue().stringValue();
          var i = rawArgList[2];
          var i2 = (nargs == 4) ? rawArgList[3] : null;
          translation = ObjPropIndexExprNode(obj, propName, i, i2);
        } else if (method == "setProp" && (nargs == 4 || nargs == 5) && rawArgList[1].getValue().type == DatumType.kDatumSymbol) {
          // obj.setProp(#prop, i, val) => obj.prop[i] = val
          // obj.setProp(#prop, i, i2, val) => obj.prop[i..i2] = val
          var obj = rawArgList[0];
          String propName  = rawArgList[1].getValue().stringValue();
          var i = rawArgList[2];
          var i2 = (nargs == 5) ? rawArgList[3] : null;
          var propExpr = ObjPropIndexExprNode(obj, propName, i, i2);
          var val = rawArgList[nargs - 1];
          translation = AssignmentStmtNode(propExpr, val);
        } else if (method == "count" && nargs == 2 && rawArgList[1].getValue().type == DatumType.kDatumSymbol) {
          // obj.count(#prop) => obj.prop.count
          var obj = rawArgList[0];
          String propName  = rawArgList[1].getValue().stringValue();
          var propExpr = ObjPropExprNode(obj, propName);
          translation = ObjPropExprNode(propExpr, "count");
        } else if ((method == "setContents" || method == "setContentsAfter" || method == "setContentsBefore") && nargs == 2) {
          // var.setContents(val) => put val into var
          // var.setContentsAfter(val) => put val after var
          // var.setContentsBefore(val) => put val before var
          PutType putType;
          if (method == "setContents") {
            putType = PutType.kPutInto;
          } else if (method == "setContentsAfter") {
            putType = PutType.kPutAfter;
          } else {
            putType = PutType.kPutBefore;
          }
          var _var = rawArgList[0];
          var val = rawArgList[1];
          translation = PutStmtNode(putType, _var, val);
        } else if (method == "hilite" && nargs == 1) {
          // chunk.hilite() => hilite chunk
          var chunk = rawArgList[0];
          translation = ChunkHiliteStmtNode(chunk);
        } else if (method == "delete" && nargs == 1) {
          // chunk.delete() => delete chunk
          var chunk = rawArgList[0];
          translation = ChunkDeleteStmtNode(chunk);
        } else {
          translation = ObjCallNode(method, argList);
        }
      }
      break;
    case OpCode.kOpPushChunkVarRef:
      translation = readVar(bytecode.obj);
      break;
    case OpCode.kOpGetTopLevelProp:
      {
        var name = getName(bytecode.obj);
        translation = VarNode(name);
      }
      break;
    case OpCode.kOpNewObj:
      {
        var objType = getName(bytecode.obj);
        var objArgs = pop();
        translation = NewObjNode(objType, objArgs);
      }
      break;
    default:
      {
        var commentText = Lingo.getOpcodeName(bytecode.opID);
        if (bytecode.opcode.rawValue >= 0x40) {
          commentText += " ${bytecode.obj}";
        }
        translation = CommentNode(commentText);
        stack.clear(); // Clear stack so later bytecode won't be too screwed up
      }
    }

    translation ??= ErrorNode();

    bytecode.translation = translation;
    if (translation.isExpression) {
      stack.add(translation);
    } else {
      ast!.addStatement(translation);
    }

    if (nextBlock != null) {
      ast!.enterBlock(nextBlock);
    }

    return 1;
  }
}