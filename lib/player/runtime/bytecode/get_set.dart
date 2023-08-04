import 'dart:math';

import 'package:dirplayer/director/lingo/bytecode.dart';
import 'package:dirplayer/director/lingo/datum.dart';
import 'package:dirplayer/director/lingo/datum/string_chunk.dart';
import 'package:dirplayer/director/lingo/datum/var_ref.dart';
import 'package:dirplayer/director/lingo/opcode.dart';
import 'package:dirplayer/player/runtime/bytecode/handler_manager.dart';
import 'package:dirplayer/player/runtime/chunk_ref.dart';
import 'package:dirplayer/player/runtime/vm.dart';
import 'package:dirplayer/player/runtime/wrappers/string.dart';

import '../../../director/lingo/chunk_expr_type.dart';
import '../../../director/lingo/constants.dart';
import '../../../director/lingo/lingo.dart';
import '../../../director/lingo/put_type.dart';
import '../castlib.dart';
import '../prop_interface.dart';

class GetSetBytecodeHandler implements BytecodeHandler {
  @override
  Future<HandlerExecutionResult?> executeBytecode(PlayerVM vm, Bytecode bytecode) async {
    switch (bytecode.opcode) {
    case OpCode.kOpSetObjProp:
      var value = vm.pop();
      var obj = vm.pop().toRef();
      var propName = vm.currentHandler!.getName(bytecode.obj);

      vm.setObjProp(obj, propName, value);
      break;

    case OpCode.kOpGetObjProp:
      var obj = vm.pop();
      var propName = vm.currentHandler!.getName(bytecode.obj);
      vm.push(vm.getObjProp(obj, propName));
      break;

    case OpCode.kOpGetMovieProp:
      var propName = vm.currentHandler!.getName(bytecode.obj);
      vm.push(vm.getMovieProp(propName));
      break;
    
    case OpCode.kOpSetMovieProp: {
      var propName = vm.currentHandler!.getName(bytecode.obj);
      var value = vm.pop();
      vm.setMovieProp(propName, value);
      break;
    }

    case OpCode.kOpSet:
      int propertyID = vm.pop().toInt();
      var value = vm.pop();
      var propertyType = bytecode.obj;
      
      if (propertyType == 0x07) {
        // anim property
        var propName = Lingo.getName(animationPropertyNames, propertyID);
        vm.movie.setProp(propName, value);
      } else {
        throw Exception("Invalid propertyType/propertyID for kOpSet");
      }
      break;

    case OpCode.kOpTheBuiltin:
      vm.pop(); // empty arglist
      var propName = vm.currentHandler!.getName(bytecode.obj);
      vm.push(vm.getTheBuiltinProp(propName));
      break;
    case OpCode.kOpGet:
      int propertyID = vm.pop().toInt();
      int propertyType = bytecode.obj;
      if (propertyType == 0 && propertyID <= moviePropertyNames.keys.reduce(max)) {
        // movie property
        vm.push(vm.getTheBuiltinProp(Lingo.getName(moviePropertyNames, propertyID)));
      } else if (propertyType == 0) {
        // last chunk
        var string = vm.pop().stringValue();
        var chunkType = ChunkExprType.fromValue(propertyID - 0x0b);
        var chunks = StringWrapper.getChunks(string, chunkType, vm.itemDelimiter);
        vm.push(Datum.ofString(chunks.lastOrNull ?? ""));
      } else if (propertyType == 0x07) {
        // animation property
        vm.push(vm.getAnimProp(propertyID));
      } else if (propertyType == 0x08) {
        // animation 2 property
        if (propertyID == 0x02 && vm.movie.dirVersion >= 500) { 
          // the number of castMembers supports castLib selection from Director 5.0
          var castLib = vm.pop();
          CastLib? cast;
          if (castLib.isString()) {
            cast = vm.movie.castManager.getCastByName(castLib.stringValue());
          } else {
            cast = vm.movie.castManager.getCastByNumber(castLib.toInt());
          }
          if (cast == null) {
            throw Exception("Cast not fount $castLib");
          } else {
            vm.push(Datum.ofInt(cast.memberCount));
          }
        } else {
          vm.push(vm.getAnim2Prop(propertyID));
        }
      } else if (propertyType == 0x01) {
        // number of chunks
        var stringRef = vm.pop();
        var string = stringRef.stringValue();
        var chunkType = ChunkExprType.fromValue(propertyID);
        vm.push(Datum.ofInt(StringWrapper.getChunks(string, chunkType, vm.itemDelimiter).length));
      } else {
        throw Exception("OpCode.kOpGet call not implemented propertyID=$propertyID propertyType=$propertyType");
      }
      break;

    case OpCode.kOpGetGlobal: {
      var name = vm.currentHandler!.getName(bytecode.obj);
      var result = vm.globals[name];
      vm.push(result ?? Datum.ofVoid());
      break;
    }
    case OpCode.kOpSetGlobal: {
      var name = vm.currentHandler!.getName(bytecode.obj);
      var value = vm.pop();
      vm.globals[name] = value;
      break;
    }
    case OpCode.kOpGetField: {
      Datum castId = Datum.ofInt(0);
      if (vm.movie.dirVersion >= 500) {
        castId = vm.pop();
      }
      var fieldNameOrNum = vm.pop();

      vm.push(Datum.ofString(vm.movie.castManager.getFieldValueByIdentifiers(fieldNameOrNum, castId)));
      break;
    }

    case OpCode.kOpSetLocal: {
      var nameInt = bytecode.obj ~/ vm.currentHandler!.variableMultiplier();
      var varName = vm.currentHandler!.getLocalName(nameInt);
      var value = vm.pop();

      vm.currentScope!.locals[varName] = value;
      break;
    }
    case OpCode.kOpGetLocal: {
      var nameInt = bytecode.obj ~/ vm.currentHandler!.variableMultiplier();
      var varName = vm.currentHandler!.getLocalName(nameInt);
      var value = vm.currentScope!.locals[varName];

      vm.push(value ?? Datum.ofVoid());
      break;
    }
    case OpCode.kOpGetParam: {
      var paramNumber = bytecode.obj;
      var result = vm.currentScope!.arguments.elementAtOrNull(paramNumber);
      vm.push(result ?? Datum.ofVoid());
      break;
    }
    case OpCode.kOpSetParam: {
      var argumentCount = vm.currentScope!.arguments.length;
      var argumentIndex = bytecode.obj;
      var value = vm.pop();

      if (argumentIndex < argumentCount) {
        vm.currentScope!.arguments[argumentIndex] = value;
      } else if (argumentIndex == argumentCount) {
        vm.currentScope!.arguments.add(value);
      } else {
        throw Exception("setting argument out of bounds");
      }
      break;
    }
    case OpCode.kOpSetProp: {
      var propName = vm.currentHandler!.getName(bytecode.obj);
      var obj = vm.currentScope!.receiver;
      var value = vm.pop();

      if (obj != null) {
        vm.setObjProp(obj, propName, value);
      } else {
        throw Exception("No receiver to set prop $propName");
      }
      break;
    }
    case OpCode.kOpGetProp: {
      var propName = vm.currentHandler!.getName(bytecode.obj);
      var obj = vm.currentScope!.receiver;

      if (obj != null) {
        vm.push(obj.getProp(propName));
      } else {
        throw Exception("No receiver to get prop $propName");
      }
      break;
    }
    case OpCode.kOpGetChainedProp: {
      var obj = vm.pop();
      var propName = vm.currentHandler!.getName(bytecode.obj);
      vm.push(vm.getObjProp(obj, propName));
      break;
    }
    case OpCode.kOpPut: {
      PutType putType = PutType.fromValue((bytecode.obj >> 4) & 0xF);
      int varType = bytecode.obj & 0xF;
      var ref = vm.readVar(varType);
      var val = vm.pop();

      switch (putType) {
      case PutType.kPutInto:
        ref.set(val);
        break;
      case PutType.kPutBefore:
        var newString = "${val.stringValue()}${ref.get().stringValue()}";
        ref.set(Datum.ofString(newString));
        break;
      case PutType.kPutAfter:
        var newString = "${ref.get().stringValue()}${val.stringValue()}";
        ref.set(Datum.ofString(newString));
        break;
      }
    }
    default:
      return null;
    }
    return HandlerExecutionResult.advance;
  }
}
