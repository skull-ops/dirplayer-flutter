import 'dart:math';

import 'package:dirplayer/director/lingo/bytecode.dart';
import 'package:dirplayer/director/lingo/datum.dart';
import 'package:dirplayer/director/lingo/opcode.dart';
import 'package:dirplayer/player/runtime/bytecode/handler_manager.dart';
import 'package:dirplayer/player/runtime/vm.dart';
import 'package:dirplayer/player/runtime/wrappers/string.dart';

import '../../../director/lingo/chunk_expr_type.dart';
import '../../../director/lingo/constants.dart';
import '../../../director/lingo/lingo.dart';
import '../../../director/lingo/put_type.dart';
import '../castlib.dart';
import '../prop_interface.dart';

class GetSetBytecodeHandler extends BytecodeHandler {
  @override
  get syncHandlers => {
    OpCode.kOpSetObjProp: setObjProp,
    OpCode.kOpGetObjProp: getObjProp,
    OpCode.kOpGetMovieProp: getMovieProp,
    OpCode.kOpSetMovieProp: setMovieProp,
    OpCode.kOpSet: set,
    OpCode.kOpTheBuiltin: theBuiltin,
    OpCode.kOpGet: get,
    OpCode.kOpGetGlobal: getGlobal,
    OpCode.kOpSetGlobal: setGlobal,
    OpCode.kOpGetField: getField,
    OpCode.kOpSetLocal: setLocal,
    OpCode.kOpGetLocal: getLocal,
    OpCode.kOpGetParam: getParam,
    OpCode.kOpSetParam: setParam,
    OpCode.kOpSetProp: setProp,
    OpCode.kOpGetProp: getProp,
    OpCode.kOpGetChainedProp: getChainedProp,
    OpCode.kOpPut: put,
  };

  static HandlerExecutionResult setObjProp(PlayerVM vm, Bytecode bytecode) {
    var value = vm.pop();
    var obj = vm.pop().toRef();
    var propName = vm.currentHandler!.getName(bytecode.obj);

    vm.setObjProp(obj, propName, value);
    return HandlerExecutionResult.advance;
  }

  static HandlerExecutionResult getObjProp(PlayerVM vm, Bytecode bytecode) {
    var obj = vm.pop();
    var propName = vm.currentHandler!.getName(bytecode.obj);
    vm.push(vm.getObjProp(obj, propName));
    return HandlerExecutionResult.advance;
  }

  static HandlerExecutionResult getMovieProp(PlayerVM vm, Bytecode bytecode) {
    var propName = vm.currentHandler!.getName(bytecode.obj);
    vm.push(vm.getMovieProp(propName));
    return HandlerExecutionResult.advance;
  }

  static HandlerExecutionResult setMovieProp(PlayerVM vm, Bytecode bytecode) {
    var propName = vm.currentHandler!.getName(bytecode.obj);
    var value = vm.pop();
    vm.setMovieProp(propName, value);
    return HandlerExecutionResult.advance;
  }

  static HandlerExecutionResult set(PlayerVM vm, Bytecode bytecode) {
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
    return HandlerExecutionResult.advance;
  }

  static HandlerExecutionResult theBuiltin(PlayerVM vm, Bytecode bytecode) {
    vm.pop(); // empty arglist
    var propName = vm.currentHandler!.getName(bytecode.obj);
    vm.push(vm.getTheBuiltinProp(propName));
    return HandlerExecutionResult.advance;
  }

  static HandlerExecutionResult get(PlayerVM vm, Bytecode bytecode) {
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
    return HandlerExecutionResult.advance;
  }

  static HandlerExecutionResult getGlobal(PlayerVM vm, Bytecode bytecode) {
    var name = vm.currentHandler!.getName(bytecode.obj);
    var result = vm.globals[name];
    vm.push(result ?? Datum.ofVoid());
    return HandlerExecutionResult.advance;
  }

  static HandlerExecutionResult setGlobal(PlayerVM vm, Bytecode bytecode) {
    var name = vm.currentHandler!.getName(bytecode.obj);
    var value = vm.pop();
    vm.globals[name] = value;
    return HandlerExecutionResult.advance;
  }

  static HandlerExecutionResult getField(PlayerVM vm, Bytecode bytecode) {
    Datum castId = Datum.ofInt(0);
    if (vm.movie.dirVersion >= 500) {
      castId = vm.pop();
    }
    var fieldNameOrNum = vm.pop();

    vm.push(Datum.ofString(vm.movie.castManager.getFieldValueByIdentifiers(fieldNameOrNum, castId)));
    return HandlerExecutionResult.advance;
  }

  static HandlerExecutionResult setLocal(PlayerVM vm, Bytecode bytecode) {
    var nameInt = bytecode.obj ~/ vm.currentHandler!.variableMultiplier();
    var varName = vm.currentHandler!.getLocalName(nameInt);
    var value = vm.pop();

    vm.currentScope!.locals[varName] = value;
    return HandlerExecutionResult.advance;
  }

  static HandlerExecutionResult getLocal(PlayerVM vm, Bytecode bytecode) {
    var nameInt = bytecode.obj ~/ vm.currentHandler!.variableMultiplier();
    var varName = vm.currentHandler!.getLocalName(nameInt);
    var value = vm.currentScope!.locals[varName];

    vm.push(value ?? Datum.ofVoid());
    return HandlerExecutionResult.advance;
  }

  static HandlerExecutionResult getParam(PlayerVM vm, Bytecode bytecode) {
    var paramNumber = bytecode.obj;
    var result = vm.currentScope!.arguments.elementAtOrNull(paramNumber);
    vm.push(result ?? Datum.ofVoid());
    return HandlerExecutionResult.advance;
  }

  static HandlerExecutionResult setParam(PlayerVM vm, Bytecode bytecode) {
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
    return HandlerExecutionResult.advance;
  }

  static HandlerExecutionResult setProp(PlayerVM vm, Bytecode bytecode) {
    var propName = vm.currentHandler!.getName(bytecode.obj);
    var obj = vm.currentScope!.receiver;
    var value = vm.pop();

    if (obj != null) {
      vm.setObjProp(obj, propName, value);
    } else {
      throw Exception("No receiver to set prop $propName");
    }
    return HandlerExecutionResult.advance;
  }

  static HandlerExecutionResult getProp(PlayerVM vm, Bytecode bytecode) {
    var propName = vm.currentHandler!.getName(bytecode.obj);
    var obj = vm.currentScope!.receiver;

    if (obj != null) {
      vm.push(obj.getProp(propName));
    } else {
      throw Exception("No receiver to get prop $propName");
    }
    return HandlerExecutionResult.advance;
  }

  static HandlerExecutionResult getChainedProp(PlayerVM vm, Bytecode bytecode) {
    var obj = vm.pop();
    var propName = vm.currentHandler!.getName(bytecode.obj);
    vm.push(vm.getObjProp(obj, propName));
    return HandlerExecutionResult.advance;
  }

  static HandlerExecutionResult put(PlayerVM vm, Bytecode bytecode) {
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
    return HandlerExecutionResult.advance;
  }
}
