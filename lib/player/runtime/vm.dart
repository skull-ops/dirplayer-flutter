import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dirplayer/common/exceptions.dart';
import 'package:dirplayer/director/file.dart';
import 'package:dirplayer/director/lingo/constants.dart';
import 'package:dirplayer/director/lingo/datum.dart';
import 'package:dirplayer/director/lingo/datum/eval/evaluated.dart';
import 'package:dirplayer/director/lingo/datum/prop_list.dart';
import 'package:dirplayer/director/lingo/datum/string.dart';
import 'package:dirplayer/director/lingo/datum/symbol.dart';
import 'package:dirplayer/director/lingo/datum/var_ref.dart';
import 'package:dirplayer/director/lingo/handler.dart';
import 'package:dirplayer/director/lingo/lingo.dart';
import 'package:dirplayer/player/runtime/bytecode/handler_manager.dart';
import 'package:dirplayer/player/runtime/castlib.dart';
import 'package:dirplayer/player/runtime/color_ref.dart';
import 'package:dirplayer/player/runtime/data_reference.dart';
import 'package:dirplayer/player/runtime/debug/breakpoint_context.dart';
import 'package:dirplayer/player/runtime/debug/breakpoint_manager.dart';
import 'package:dirplayer/player/runtime/eval.dart';
import 'package:dirplayer/player/runtime/image_ref.dart';
import 'package:dirplayer/player/runtime/movie.dart';
import 'package:dirplayer/player/runtime/net_manager.dart';
import 'package:dirplayer/player/runtime/net_task.dart';
import 'package:dirplayer/player/runtime/palette_ref.dart';
import 'package:dirplayer/player/runtime/prop_interface.dart';
import 'package:dirplayer/player/runtime/rect.dart';
import 'package:dirplayer/player/runtime/scope.dart';
import 'package:dirplayer/player/runtime/score.dart';
import 'package:dirplayer/player/runtime/stage.dart';
import 'package:dirplayer/player/runtime/timeout.dart';
import 'package:dirplayer/player/runtime/wrappers/prop_list.dart';
import 'package:dirplayer/player/runtime/wrappers/string.dart';
import 'package:dirplayer/player/runtime/xtras/interface.dart';
import 'package:dirplayer/player/runtime/xtras/manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

import '../../director/lingo/bytecode.dart';
import '../../director/lingo/datum/list.dart';
import 'cast_member.dart';
import 'script.dart';
import 'sprite.dart';

enum HandlerExecutionResult {
  advance,
  stop,
  jump,
}

class ExtCallResult {
  HandlerExecutionResult handlerExecutionResult;
  Datum result;

  ExtCallResult(this.handlerExecutionResult, this.result);
}

typedef OnScriptErrorCallback = void Function(Scope scope, dynamic err);
typedef PlayerVMExecutionCallback = Future<Datum> Function();

class PlayerVMExecutionItem {
  PlayerVMExecutionCallback callback;
  Completer<Datum> completer = Completer();

  PlayerVMExecutionItem(this.callback);
}

class PlayerVM with ChangeNotifier {
  final log = Logger("PlayerVM");
  Movie movie = Movie();
  List<Scope> scopes = [];
  int? nextFrame;
  Map<String, Datum> globals = {};
  String itemDelimiter = ".";
  OnScriptErrorCallback? onScriptError;
  final BreakpointManager breakpointManager = BreakpointManager();
  BreakpointContext? currentBreakpoint;
  final random = Random();
  final bytecodeHandlerManager = BytecodeHandlerManager();
  dynamic alertHook;
  int keyboardFocusSprite = -1; // Setting keyboardFocusSprite to -1 returns keyboard focus control to the Score, and setting it to 0 disables keyboard entry into any editable sprite.
  Stage stage = Stage();
  int intCursorNum = 0;
  final netManager = NetManager();
  final timeoutManager = TimeoutManager();
  DateTime startTime = DateTime.now();
  PublishSubject<PlayerVMExecutionItem> executionQueue = PublishSubject();
  final IntPoint mouseLoc = IntPoint(0, 0);

  bool _isPlaying = false;
  bool _isScriptPaused = false;
  
  Scope? get currentScope {
    return scopes.lastOrNull;
  }

  Handler? get currentHandler {
    return scopes.lastOrNull?.handler;
  }
  List<Datum> get stack {
    return currentScope!.stack;
  }

  int get currentHandlerPosition {
    return scopes.lastOrNull?.handlerPosition ?? -1;
  }

  bool get isScriptPaused => _isScriptPaused;

  Future loadMovieDir(DirectorFile dir) async {
    movie = Movie();
    await movie.loadFromFile(dir, netManager);
    //stage.resize(movie.movieRight - movie.movieLeft, movie.movieBottom - movie.movieTop);
    notifyListeners();
  }

  Future loadMovieFromFile(String path) async {
    var dir = await readDirectorFile(netManager, path);
    await loadMovieDir(dir);
  }

  Future loadMovieFromBytes(Uint8List bytes, String fileName) async {
    var dir = await readDirectorFileFromBytes(bytes, fileName, netManager.basePath);
    await loadMovieDir(dir);
  }

  Future play() async {
    if (_isPlaying) {
      return;
    }
    _isPlaying = true;
    _isScriptPaused = false;
    runVM(); // TODO store this somewhere
    await dispatch("prepareMovie", []);
    while (_isPlaying) {
      int fps = movie.puppetTempo > 0 ? movie.puppetTempo : 1;
      await playFrame();
      if (!_isPlaying) {
        break;
      }
      await Future.delayed(Duration(milliseconds: 1000 ~/ fps));
      if (!_isPlaying) {
        break;
      }
      advanceFrame();
    }
  }

  void stop() {
    // TODO dispatch stop movie
    _isPlaying = false;
    nextFrame = null;
    //scopes.clear();
    currentBreakpoint?.completer.completeError(CancelledException());
    currentBreakpoint = null;
    timeoutManager.clear();
    notifyListeners();
  }

  void pauseScript() {
    _isScriptPaused = true;
    notifyListeners();
  }

  void resumeScript() {
    _isScriptPaused = false;
    notifyListeners();
  }

  List<Datum> popN(int n) {
    //print("popping $n");
    if (n > stack.length) {
      throw Exception("Popping too far");
    }
    var result = stack.getRange(stack.length - n, stack.length).toList();
    stack.removeRange(stack.length - n, stack.length);
    return result;
  }

  T pop<T extends Datum>() {
    return popN(1)[0] as T;
  }

  void push(Datum datum) {
    //print("pushing ${datum.toDebugString()}");
    stack.add(datum);
  }

  Ref<Datum>? getObjPropRef(dynamic obj, String propName) {
    VMPropInterface? vmPropInterface;
    PropInterface? propInterface;
    Ref<Datum>? propRef;

    if (obj is VMPropInterface) {
      vmPropInterface = obj;
    }
    if (obj is PropInterface) {
      propInterface = obj;
    }

    propRef = vmPropInterface?.getVMPropRef(propName, this);
    if (propRef != null) {
      return propRef;
    }
    propRef = propInterface?.getPropRef(propName);
    if (propRef != null) {
      return propRef;
    }
    return null;
  }

  Datum getObjProp(Datum obj, String propName) {
    var propRef = getObjPropRef(obj, propName);
    if (propRef != null) {
      return propRef.get();
    }
    switch (obj.type) {
    case DatumType.kDatumString:
      return StringWrapper.getProp(obj.stringValue(), propName);
    case DatumType.kDatumPropList:
      return PropListWrapper.getProp(obj, propName);
    default:
      throw Exception("Unknown prop $propName for $obj");
    }
  }

  // Returns an object accessed via `the objName` syntax
  Datum getTheBuiltinProp(String propName) {
    switch (propName) {
      case "paramCount":
        return Datum.ofInt(currentScope!.arguments.length);
      default:
        return getMovieProp(propName);
    }
  }

  void setObjProp(dynamic obj, String propName, Datum value) {
    var propRef = getObjPropRef(obj, propName);
    if (propRef != null) {
      if (propRef is MutableRef) {
        (propRef as MutableRef).set(value);
      } else {
        throw Exception("Cannot set property $propName of $obj");
      }
      return;
    }
    if (obj is PropInterface) {
      return obj.setProp(propName, value);
    } else if (obj is VMPropInterface) {
      return obj.setVMProp(propName, value, this);
    } else {
      throw Exception("Cannot set prop $propName of $obj");
    }
  }

  Future<ExtCallResult> extCall(String name, List<Datum> argList) async {
    var result = Datum.ofVoid();
    var handlerExecutionResult = HandlerExecutionResult.advance;

    switch (name) {
    case "return": {
      var returnValue = argList.firstOrNull;
      if (returnValue != null) {
        currentScope!.returnValue = returnValue;
        result = argList.first;
      }
      handlerExecutionResult = HandlerExecutionResult.stop;
      break;
    }
    default:
      result = await callGlobalHandler(name, argList);
      break;
    }

    return ExtCallResult(handlerExecutionResult, result);
  }

  Future<Datum> callBuiltinHandler(String name, List<Datum> argList) async {
    //trace("$name(${argList.join(", ")})");
    var result = Datum.ofVoid();

    switch (name) {
    case "castLib":
      var nameOrNumber = argList[0];
      CastLib? resultCast;
      if (nameOrNumber.isNumber()) {
        resultCast = movie.castManager.casts[nameOrNumber.toInt() - 1];
      } else {
        resultCast = movie.castManager.getCastByName(nameOrNumber.stringValue());
      }
      if (resultCast == null) {
        throw Exception("Cast not found $nameOrNumber");
      }
      result = Datum.ofVarRef(resultCast);
      break;
    case "member":
      assert(argList.length <= 2);
      var memberNameOrNum = argList[0];
      var castNameOrNum = argList.elementAtOrNull(1);

      var member = movie.castManager.findMemberByIdentifiers(memberNameOrNum, castNameOrNum);
      if (member != null) {
        result = Datum.ofVarRef(member.reference);
      } else {
        result = Datum.ofVarRef(InvalidMember());
      }
      break;
    case "sprite":
      var spriteNumer = argList[0].toInt();
      var sprite = movie.score.getSprite(spriteNumer);
      result = Datum.ofVarRef(sprite);
      break;
    case "preloadNetThing":
      var url = argList[0].stringValue();
      var task = netManager.preloadNetThing(url);
      result = Datum.ofInt(task.id);
      break;
    case "moveToFront":
      break;
    case "puppetTempo":
      var number = argList[0].toInt();
      movie.puppetTempo = number;
      break;
    case "puppetSprite":
      var spriteNumber = argList[0].toInt();
      var isPuppet = argList[1].toBool();

      movie.score.getSprite(spriteNumber).puppet = isPuppet;
      break;
    case "netDone":
      NetTask? task = netManager.findTask(argList.firstOrNull);
      result = Datum.ofBool(task?.isDone ?? true);
      break;
    case "netError":
      NetTask? task = netManager.findTask(argList.firstOrNull);
      var taskResult = task?.result;
      if (taskResult is NetResultSuccess) {
        result = Datum.ofString("OK");
      } else if (taskResult is NetResultError) {
        result = Datum.ofInt(taskResult.errorCode);
      } else {
        result = Datum.ofInt(0);
      }
      break;
    case "getNetText":
      var task = netManager.getNetText(argList.first.stringValue());
      result = Datum.ofInt(task.id);
    case "go":
      var dest = argList.first;
      goToFrame(dest.toInt());
      break;
    case "objectp": {
      var obj = argList[0];
      var isObject = obj.type != DatumType.kDatumVoid && obj.type != DatumType.kDatumFloat && obj.type != DatumType.kDatumInt && obj.type != DatumType.kDatumSymbol && obj.type != DatumType.kDatumString;
      result = Datum.ofInt(isObject ? 1 : 0);
      break;
    }
    case "voidp": {
      var obj = argList[0];
      var isVoid = obj.type == DatumType.kDatumVoid || (obj.type == DatumType.kDatumVarRef && obj.toRef() == null);
      result = Datum.ofInt(isVoid ? 1 : 0);
      break;
    }
    case "integerp": {
      var obj = argList[0];
      result = Datum.ofBool(obj.type == DatumType.kDatumInt);
      break;
    }
    case "floatp": {
      var obj = argList[0];
      result = Datum.ofBool(obj.type == DatumType.kDatumFloat);
      break;
    }
    case "listp": {
      var obj = argList[0];
      var isList = obj.type == DatumType.kDatumList || obj.type == DatumType.kDatumArgList || obj.type == DatumType.kDatumArgListNoRet || obj.type == DatumType.kDatumPropList;
      result = Datum.ofInt(isList ? 1 : 0);
      break;
    }
    case "symbolp": {
      var obj = argList[0];
      var isSymbol = obj.type == DatumType.kDatumSymbol;
      result = Datum.ofInt(isSymbol ? 1 : 0);
      break;
    }
    case "stringp": {
      var obj = argList[0];
      var isString = obj.type == DatumType.kDatumString;
      result = Datum.ofInt(isString ? 1 : 0);
      break;
    }
    case "offset": {
      var stringToFind = argList[0].stringValue();
      var findIn = argList[1].stringValue();
      result = Datum.ofInt(findIn.indexOf(stringToFind) + 1);
      break;
    }
    case "length": {
      var obj = argList[0];
      if (obj.type == DatumType.kDatumString) {
        result = Datum.ofInt(obj.stringValue().length);
      } else {
        result = Datum.ofInt(0);
      }
      break;
    }
    case "value": {
      var exprDatum = argList.first;
      if (exprDatum.type == DatumType.kDatumString) {
        result = eval(this, argList.first.stringValue());
      } else {
        result = exprDatum;
      }
    }
    case "script": {
      // TODO syntax:
      // script(number, castLib)
      // script(number)
      // script(member())

      var identifier = argList.first;
      Script? script;
      if (identifier.isString()) {
        var scriptName = identifier.stringValue();
        script = movie.castManager.getScript(scriptName);
      } else if (identifier.isNumber()) {
        var memberNumber = identifier.toInt();
        var member = movie.castManager.findMemberByNumber(memberNumber);
        script = member?.cast.getScriptForMember(memberNumber);
      }
      if (script != null) {
        result = Datum.ofVarRef(script);
      } else {
        throw Exception("Script not found $identifier args: $argList");
      }
      break;
    }
    case "void": {
      result = Datum.ofVoid();
      break;
    }
    case "param": {
      var paramNumber = argList.first.toInt();
      result = currentScope!.arguments[paramNumber - 1];
      break;
    }
    case "count": {
      var obj = argList[0];
      if (obj.isList()) {
        result = Datum.ofInt(obj.toList().length);
      } else if (obj is PropListDatum) {
        result = Datum.ofInt(obj.value.length);
      } else {
        throw Exception("List expected for handler");
      }
      break;
    }
    case "getAt": {
      var obj = argList[0];
      var position = argList[1].toInt();
      if (obj.isList()) {
        result = obj.toList()[position - 1];
      } else if (obj is PropListDatum) {
        result = obj.value.values.elementAt(position - 1);
      } else {
        throw Exception("List expected for handler");
      }
      break;
    }
    case "ilk": {
      var obj = argList[0];
      var ilkType = argList.elementAtOrNull(1);

      if (ilkType != null) {
        result = Datum.ofBool(obj.isIlk(ilkType.stringValue()));
      } else {
        result = Datum.ofSymbol(obj.ilk());
      }
      break;
    }
    case "string": {
      var obj = argList.first;
      result = Datum.ofString(obj.toString());
      break;
    }
    case "put": {
      var line = argList.map((e) => e.stringValue()).join(" ");
      print("-- $line");
      break;
    }
    case "space": {
      result = Datum.ofString(" ");
      break;
    }
    case "integer": {
      var value = argList.first;
      if (value.isNumber() || value.isString()) {
        result = Datum.ofInt(value.toInt());
      } else if (value.isVoid()) {
        result = Datum.ofVoid();
      } else {
        throw Exception("Cannot convert $value to integer");
      }
      break;
    }
    case "charToNum":
      var stringValue = argList.first.stringValue();
      var num = stringValue.characters.firstOrNull?.codeUnits.firstOrNull ?? 0;
      result = Datum.ofInt(num);
      break;
    case "float":
      var value = argList.first;
      if (value.isNumber()) {
        result = Datum.ofFloat(value.toFloat());
      } else if (value.isString()) {
        var floatValue = double.tryParse(value.stringValue());
        if (floatValue != null) {
          result = Datum.ofFloat(floatValue);
        } else {
          result = value;
        }
      }
      break;
    case "numToChar":
      var value = argList.first.toInt();
      result = Datum.ofString(String.fromCharCode(value));
      break;
    case "random":
      var maxValue = argList.first.toInt();
      assert(maxValue >= 0);
      result = Datum.ofInt(random.nextInt(maxValue) + 1);
      break;
    case "bitAnd":
      var left = argList[0].toInt();
      var right = argList[1].toInt();
      result = Datum.ofInt(left & right);
      break;
    case "bitOr":
      var left = argList[0].toInt();
      var right = argList[1].toInt();
      result = Datum.ofInt(left | right);
      break;
    case "symbol":
      var symbolName = argList.first;
      if (symbolName is SymbolDatum) {
        result = symbolName;
      } else if (symbolName is StringDatum) {
        var stringValue = symbolName.stringValue();
        if (stringValue.isEmpty) {
          result = Datum.ofSymbol("");
        } else if (symbolName.stringValue().startsWith("#")) {
          result = Datum.ofSymbol("#");
        } else {
          result = Datum.ofSymbol(symbolName.stringValue());
        }
      } else {
        result = Datum.ofVoid();
      }
      break;
    case "point":
      var locH = argList[0].toInt();
      var locV = argList[1].toInt();
      result = Datum.ofVarRef(IntPoint(locH, locV));
      break;
    case "cursor":
      if (argList.length == 1) {
        var arg = argList.first;
        if (arg.isInt()) {
          // intCursorNum
          intCursorNum = arg.toInt();
          // TODO apply cursor
        } else if (arg is VarRefDatum && arg.value is CastMemberReference) {
          throw Exception("Unsupported cursor call");
        } else {
          throw Exception("Unsupported cursor call");
        }
      } else if (argList.length == 2) {
        var cursorMemNum = argList[0];
        var maskMemNum = argList[1];

        throw Exception("Unsupported cursor call");
      } else {
        throw Exception("Unsupported cursor call");
      }
      break;
    case "new":
      var firstArg = argList.first;
      if (firstArg.isSymbol()) {
        var type = firstArg.stringValue();
        var location = argList[1].toRef();

        if (location is CastLib) {
          var member = location.addMemberAt(location.firstFreeMemberNumber, type);
          result = Datum.ofVarRef(member.reference);
        } else if (location is CastMemberReference) {
          throw Exception("Unsupported new call location $location");
        } else {
          throw Exception("Unsupported new call location $location");
        }
      } else if (firstArg is VarRefDatum && firstArg.value is Script && firstArg.value is! ScriptInstance) {
        var script = firstArg.toRef<Script>();
        result = await script.callHandler(this, "new", argList.sublist(1));
      } else if (firstArg is VarRefDatum && firstArg.value is XtraFactory) {
        var xtraFactory = firstArg.toRef<XtraFactory>();
        result = Datum.ofVarRef(await xtraFactory.newInstance(argList.sublist(1)));
      } else {
        throw Exception("Unsupported new call");
      }
      break;
    case "timeout":
      var name = argList.first.stringValue();
      result = Datum.ofVarRef(TimeoutRef(name, timeoutManager));
      break;
    case "call":
      var handlerName = argList[0];
      var receiver = argList[1];
      var args = argList.sublist(2);
      assert(handlerName.isSymbol());

      if (receiver is PropListDatum) {
        for (var value in receiver.value.values.toList()) {
          await callObjectHandler(value, handlerName.stringValue(), args);
        }
        result = Datum.ofVoid();
      } else if (receiver is ListDatum) {
        result = Datum.ofNull();
        for (var value in receiver.value.toList()) {
          // TODO check if receiver has handler, catching an exception will result in a broken stack
          try {
            result = await callObjectHandler(value, handlerName.stringValue(), args);
          } on UnknownHandlerException catch (_) {
            // No handling needed
          }
        }
      } else if (receiver is HandlerInterface) {
        result = await (receiver as HandlerInterface).callHandler(this, handlerName.stringValue(), args);
      } else {
        throw Exception("Invalid call");
      }
      break;
    case "rect":
      var left = argList[0].toInt();
      var top = argList[1].toInt();
      var right = argList[2].toInt();
      var bottom = argList[3].toInt();
      result = Datum.ofVarRef(IntRect(left, top, right, bottom));
      break;
    case "getStreamStatus":
      // TODO
      print("[!!] warn: TODO getStreamStatus");
      var arg = argList.first;
      assert(arg.isInt());
      var netTask = netManager.tasks.where((element) => element.id == arg.toInt()).first;
      String state;
      String error;
      if (netTask.isDone && netTask.result is NetResultSuccess) {
        state = "Complete";
        error = "OK";
      } else if (netTask.isDone && netTask.result is NetResultError) {
        state = "Error";
        error = (netTask.result as NetResultError).error.toString();
      } else {
        state = "InProgress";
        error = "";
      }
      result = Datum.ofPropList({
        Datum.ofSymbol("URL"): Datum.ofString(netTask.url),
        Datum.ofSymbol("state"): Datum.ofString(state), //String consisting of Connecting, Started, InProgress, Complete, “Error”, or “NoInformation” (this last string is for the condition when either the net ID is so old that the status information has been dropped or the URL specified in URLString was not found in the cache).
        Datum.ofSymbol("bytesSoFar"): Datum.ofInt(netTask.result is NetResultSuccess ? 100 : 0),
        Datum.ofSymbol("bytesTotal"): Datum.ofInt(100),
        Datum.ofSymbol("error"): Datum.ofString(error) // String containing ““ (EMPTY) if the download is not complete, OK if it completed successfully, or an error code if the download ended with an error.
      });
      break;
    case "netTextresult": {
      // TODO check if text task
      NetTask? task = netManager.findTask(argList.firstOrNull);
      var taskResult = task?.result;
      if (taskResult != null && taskResult is NetResultSuccess) {
        var stringResult = String.fromCharCodes(taskResult.bytes);
        var lines = const LineSplitter().convert(stringResult);
        // TODO use utf8?
        result = Datum.ofString(lines.join("\r")); // TODO should this be done?
      } else {
        result = Datum.ofString("");
      }
      break;
    }
    case "rgb": {
      ColorRef colorRef;
      if (argList.length == 3) {
        var r = argList[0].toInt();
        var g = argList[1].toInt();
        var b = argList[2].toInt();

        colorRef = ColorRef.fromRgb(r, g, b);
      } else if (argList.first.isString()) {
        colorRef = ColorRef.fromHex(argList.first.stringValue());
      } else {
        throw Exception("Invalid rgb call");
      }

      result = Datum.ofVarRef(colorRef);
      break;
    }
    case "paletteIndex": {
      assert(argList.length == 1);
      result = Datum.ofVarRef(PaletteIndexColorRef(argList[0].toInt()));
      break;
    }
    case "list":
      result = Datum.ofDatumList(DatumType.kDatumList, argList);
      break;
    case "image":
      var width = argList[0].toInt();
      var height = argList[1].toInt();
      var bitDepth = argList[2].toInt();

      img.Format format;
      int numChannels;

      switch (bitDepth) {
      case 8:
        format = img.Format.uint8;
        numChannels = 1;
      case 32:
        format = img.Format.uint8;
        numChannels = 4;
      default:
        return Future.error(Exception("Unknown bitDepth $bitDepth"));
      }

      var image = img.Image(
        width: width,
        height: height, 
        format: format,
        numChannels: numChannels,
      );
      return Datum.ofVarRef(ImageRef(image, 8, PaletteRef(BuiltInPalette.systemDefault.intValue)));
    case "externalParamValue":
      // TODO
      return Datum.ofString("");
    case "chars":
      var str = argList[0].stringValue();
      var start = argList[1].toInt();
      var end = argList[2].toInt();
      return Datum.ofString(str.substring(start - 1, end));
    case "abs":
      assert(argList.length == 1);
      var value = argList.first;
      if (value.isFloat()) {
        return Datum.ofFloat(value.toFloat().abs());
      } else if (value.isInt()) {
        return Datum.ofInt(value.toInt().abs());
      } else {
        return Future.error(Exception("Invalid abs call for $value"));
      }
    case "xtra":
      assert(argList.length == 1);
      var xtraName = argList.first.stringValue();
      var xtra = XtraManager.getXtra(xtraName);
      if (xtra != null) {
        return Datum.ofVarRef(xtra);
      } else {
        return Future.error(Exception("Unknown xtra $xtraName"));
      }
    case "stopEvent":
      // TODO stopEvent
      break;
    default:
      return Future.error(Exception("Handler not defined $name($argList)"));
    }
    return result;
  }

  Datum getMovieProp(String propName) {
    switch (propName) {
      case "itemDelimiter":
        return Datum.ofString(itemDelimiter);
      case "alertHook":
        if (alertHook != null) {
          return Datum.ofVarRef(alertHook);
        } else {
          return Datum.ofInt(0);
        }
      case "stage":
        return Datum.ofVarRef(stage);
      case "stageLeft":
        return Datum.ofInt(stage.left);
      case "stageTop":
        return Datum.ofInt(stage.top);
      case "stageRight":
        return Datum.ofInt(stage.right);
      case "stageBottom":
        return Datum.ofInt(stage.bottom);
      case "milliSeconds":
        return Datum.ofInt(DateTime.now().difference(startTime).inMilliseconds);
      case "productVersion":
        return Datum.ofString("10.1");
      case "keyboardFocusSprite":
        return Datum.ofInt(keyboardFocusSprite);
      case "mouseH":
        return Datum.ofInt(mouseLoc.locH);
      case "mouseV":
        return Datum.ofInt(mouseLoc.locV);
      case "mouseLoc":
        return Datum.ofVarRef(mouseLoc);
      default:
        return movie.getProp(propName);
    }
  }

  void setMovieProp(String propName, Datum value) {
    switch (propName) {
      case "itemDelimiter":
        itemDelimiter = value.stringValue();
        break;
      case "alertHook":
        if (value is VarRefDatum) {
          alertHook = value.toRef();
        } else if (value.isInt() && value.toInt() == 0) {
          alertHook = null;
        } else {
          throw Exception("Object or 0 expected for alertHook");
        }
        break;
      case "keyboardFocusSprite":
        // TODO
        keyboardFocusSprite = value.toInt();
        break;
      default:
        setObjProp(movie, propName, value);
        break;
    }
  }

  Datum getAnim2Prop(int propertyID) {
    // TODO add id contants
    var propName = Lingo.getName(animation2PropertyNames, propertyID);
    switch (propertyID) {
    case 4: // the number of castLibs
      return Datum.ofInt(movie.castManager.casts.length);
    default:
      throw Exception("Unknown anim2 property $propName");
    }
  }

  Datum getAnimProp(int propertyID) {
    var propName = Lingo.getName(animationPropertyNames, propertyID);
    switch (propName) {
    case "colorDepth":
      return Datum.ofInt(32);
    default:
      throw Exception("Invalid anim property $propertyID");
    }
  }

  Future<HandlerExecutionResult> executeBytecode(Bytecode bytecode) async {
    //var code = CodeWriter();
    //bytecode.writeBytecodeText(code, movie.dotSyntax);
    //print("> ${code.str()}");
    return await bytecodeHandlerManager.executeBytecode(this, bytecode);
  }

  void jumpToBytecodePosition(int position) {
    currentScope!.handlerPosition = currentHandler!.bytecodeArray.indexWhere((element) => element.pos == position);
    notifyListeners();
  }

  void jumpToPosition(int position) {
    currentScope!.handlerPosition = position;
    notifyListeners();
  }

  Future<Datum> callObjectHandler(Datum obj, String handlerName, List<Datum> argList) async {
    // TODO use refactored datum interface
    //trace("$obj.${handlerName}(${argList.join(", ")})");

    if (obj is HandlerInterface) {
      return await (obj as HandlerInterface).callHandler(this, handlerName, argList);
    } else if (obj is StringDatum) {
      return StringWrapper.callHandler(this, obj, handlerName, argList);
    } else {
      switch (obj.type) {
      case DatumType.kDatumPropList:
        return PropListWrapper.callHandler(this, obj, handlerName, argList);
      default:
        return Future.error(UnknownHandlerException(handlerName, argList, obj));
      }
    }
  }

  Future<Datum> callGlobalHandler(String name, List<Datum> argList) async {
    //trace("Calling global handler $name");

    var movieScripts = movie.castManager.getMovieScripts();
    for (var script in movieScripts) {
      var handler = script.getOwnHandler(name);
      if (handler != null) {
        return await callHandler(script, null, handler, argList);
      }
    }
    return await callBuiltinHandler(name, argList);
  }

  Future<Datum> callHandler(Script script, ScriptInstance? receiver, Handler handler, List<Datum> argList) async {
    log.finer("Calling $script.${handler.name}(${argList.map((it) => it.type).join(", ")}) - receiver $receiver");

    var scope = Scope(script, receiver, handler, argList);
    scopes.add(scope);

    var shouldReturn = false;
    do {
      var bytecode = handler.bytecodeArray[scope.handlerPosition];
      var breakpoint = breakpointManager.findBreakpointForBytecode(script, handler, bytecode.pos);
      if (breakpoint != null) {
        await triggerBreakpoint(breakpoint, script, handler, bytecode);
      }
      var result = await executeBytecode(bytecode);
      switch (result) {
      case HandlerExecutionResult.advance:
        scope.handlerPosition++;
        break;
      case HandlerExecutionResult.stop:
        shouldReturn = true;
        break;
      case HandlerExecutionResult.jump:
        break;
      }
    } while (!shouldReturn);

    scopes.remove(scope);
    notifyListeners();
    return scope.returnValue;
  }
  
  Future triggerBreakpoint(Breakpoint breakpoint, Script script, Handler handler, Bytecode bytecode) async {
    var completer = Completer();
    var context = BreakpointContext(
      breakpoint: breakpoint, 
      script: script, 
      handler: handler, 
      bytecode: bytecode,
      completer: completer,
    );
    currentBreakpoint = context;
    notifyListeners();

    pauseScript();
    await completer.future;
    resumeScript();
  }

  void resumeBreakpoint() {
    currentBreakpoint?.completer.complete();
    currentBreakpoint = null;
    notifyListeners();
  }

  MutableRef<Datum> readVar(int varType) {
    Datum? castID;
    if (varType == 0x6 && movie.dirVersion >= 500) { // field cast ID
      castID = pop();
    }
    Datum id = pop();

    switch (varType) {
    case 0x1: // global
    case 0x2: // global
    case 0x3: // property/instance
      throw Exception("readVar global/prop/instance not implemented");
    case 0x4: // arg
      {
        int argIndex = (id.toInt() ~/ currentHandler!.variableMultiplier());
        String argName = currentHandler!.getArgumentName(argIndex);
        return MutableCallbackRef(
          get: () => currentScope!.arguments[argIndex], 
          set: (value) => currentScope!.arguments[argIndex] = value
        );
      }
    case 0x5: // local
      {
        String name = currentHandler!.getLocalName(id.toInt() ~/ currentHandler!.variableMultiplier());
        return MutableCallbackRef(
          get: () => currentScope!.locals[name] ?? Datum.ofVoid(), 
          set: (value) => currentScope!.locals[name] = value
        );
      }
    case 0x6: // field
      //return MemberExprNode("field", id, castID);
      throw Exception("readVar field not implemented");
    default:
      throw Exception("findVar: unhandled var type $varType");
    }
  }

  Future reserve(PlayerVMExecutionCallback callback) async {
    var item = PlayerVMExecutionItem(callback);
    executionQueue.add(item);
    return await item.completer.future;
  }

  Future runVM() async {
    Future<Datum> onError(dynamic error) {
      if (error is CancelledException) {
        // Do nothing
      } else {
        log.severe("[!!] play failed with error: ${error.toString()}");
        for (var scope in scopes.reversed) {
          var currentBytecode = scope.handler.bytecodeArray[scope.handlerPosition];
          log.severe("at ${scope.script}.${scope.handler.name}:${currentBytecode.pos} => receiver ${scope.receiver}");
        }
        log.severe("");
        onScriptError?.call(currentScope!, error);
      }
      return Future.error(error);
    }
    log.info("Starting VM");
    await for (var item in executionQueue) {
      if (!_isPlaying) {
        break;
      }
      try {
        item.completer.complete(await item.callback().catchError(Future<Datum>.error));
      } catch (err) {
        await onError(err);
        break;
      }
    }
    log.warning("VM stopped!");
    stop();
  }

  void dispatchToSprite(Sprite sprite, String eventName) async {
    for (var scriptInstance in sprite.scriptInstanceList) {
      var handlerPair = scriptInstance.getHandler(eventName);
      if (handlerPair != null) {
        var (script, handler) = handlerPair;
        await reserve(() =>
          callHandler(script, scriptInstance, handler, [Datum.ofVarRef(scriptInstance)])
        );
      }
    }
  }
  
  Future dispatch(String name, List<Datum> args) async {
    // First stage behavior script
    // Then frame behavior script
    // Then movie script
    // If frame is changed during exitFrame, event is no longer propagated
    // TODO find stage behaviors first

    var frameScript = movie.score.getScriptInFrame(movie.currentFrame);
    var movieScripts = movie.castManager.getMovieScripts();

    var activeScripts = <Script>[
      ...movieScripts,
      if (frameScript != null) movie.castManager.castLib(frameScript.castLib)!.getScriptForMember(frameScript.castMember)!,
      ...globals.values.whereType<VarRefDatum>().map(
        (element) => element.toRef() is Script ? element.toRef<Script>() : null
      ).nonNulls
    ];
    var activeScriptInstances = [
      ...globals.values.whereType<VarRefDatum>().map(
        (element) => element.toRef() is ScriptInstance ? element.toRef<ScriptInstance>() : null
      ).nonNulls
    ];

    for (var script in activeScripts) {
      var handlerPair = script.getHandler(name);

      if (handlerPair != null) {
        await reserve(() => script.callHandler(this, name, args));
      }
    }
    for (var script in activeScriptInstances) {
      var handlerPair = script.getHandler(name);

      if (handlerPair != null) {
        await reserve(() => script.callHandler(this, name, args));
      }
    }
  }

  Future onEnterFrame(int frame) async {
    await dispatch("prepareFrame", []);
    await dispatch("enterFrame", []);
  }

  Future onExitFrame(int frame) async {
    await dispatch("exitFrame", []);
  }

  void onMouseMove(int x, int y) {
    mouseLoc.locH = x;
    mouseLoc.locV = y;
    // TODO dispatch mouseMove
  }

  void goToFrame(int frame) {
    nextFrame = frame;
  }

  Future playFrame() async {
    var currentFrame = movie.currentFrame;
    await onEnterFrame(currentFrame);
    if (nextFrame != null || !_isPlaying) {
      // enterFrame changed frame. skip.
      return;
    }
    await onExitFrame(currentFrame);
    if (nextFrame != null || !_isPlaying) {
      // exitFrame changed frame. skip.
      return;
    }
  }

  void advanceFrame() {
    if (nextFrame != null) {
      movie.currentFrame = nextFrame!;
      nextFrame = null;
    } else {
      movie.currentFrame++;
    }
    notifyListeners();
  }

  void reset() {
    stop();
    scopes.clear();
    globals.clear();
    timeoutManager.clear();
    netManager.clear();
    movie.score.reset();
    movie.currentFrame = 1;
    notifyListeners();
  }
}
