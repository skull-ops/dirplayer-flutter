import 'package:dirplayer/director/castmembers.dart';
import 'package:dirplayer/director/chunks/script.dart';
import 'package:dirplayer/director/lingo/datum.dart';
import 'package:dirplayer/director/lingo/datum/list.dart';
import 'package:dirplayer/director/lingo/datum/prop_list.dart';
import 'package:dirplayer/director/lingo/handler.dart';
import 'package:dirplayer/player/runtime/data_reference.dart';
import 'package:dirplayer/player/runtime/prop_interface.dart';
import 'package:dirplayer/player/runtime/vm.dart';
import 'package:logging/logging.dart';

class Script implements HandlerInterface {
  final log = Logger("Script");
  String name;
  ScriptChunk chunk;
  ScriptType scriptType;

  Script(this.name, this.chunk, this.scriptType);

  List<Handler> get handlers => chunk.handlers;

  @override
  Future<Datum> callHandler(PlayerVM vm, String handlerName, List<Datum> argList) async {
    switch (handlerName) {
      case "new": {
        assert(argList.isEmpty);
        log.fine("Creating instance of $name");
        var newInstance = ScriptInstance(this);
        var newHandler = getOwnHandler("new");
        if (newHandler != null) {
          return await vm.callHandler(this, newInstance, newHandler, argList);
        } else {
          return Datum.ofVarRef(newInstance);
        }
      }
      default:
        return await callScriptHandler(vm, handlerName, argList);
    }
  }

  Future<Datum> callScriptHandler(PlayerVM vm, String handlerName, List<Datum> argList) async {
    var handlerPair = getHandler(handlerName);

    if (handlerPair != null) {
      var (handlerScript, handler) = handlerPair;
      return await vm.callHandler(handlerScript, null, handler, argList);
    } else {
      throw Exception("Unknown handler $handlerName on $this");
    }
  }

  Handler? getOwnHandler(String name) {
    var handler = handlers.where((element) => element.name.toLowerCase() == name.toLowerCase()).firstOrNull;
    return handler;
  }

  (Script, Handler)? getHandler(String name) {
    var handler = getOwnHandler(name);
    if (handler != null) {
      return (this, handler);
    } else {
      return null;
    }
  }

  @override
  String toString() {
    return "(script $name)";
  }
}

class ScriptInstance implements HandlerInterface, PropInterface, CustomSetPropInterface {
  Script script;
  ScriptInstance? ancestor;
  Map<String, Datum> properties = {};

  ScriptInstance(this.script) :
    properties = Map.fromEntries(script.chunk.propertyNames.map((e) => MapEntry(e, Datum.ofVoid())));

  @override
  String toString() {
    return "<offspring ${script.name} _ _>";
  }

  (Script, Handler)? getHandler(String name) {
    var selfHandler = script.getHandler(name);
    if (selfHandler != null) {
      return selfHandler;
    }
    var ancestorHandler = ancestor?.getHandler(name);
    if (ancestorHandler != null) {
      return ancestorHandler;
    }
    return null;
  }

  @override
  Future<Datum> callHandler(PlayerVM vm, String handlerName, List<Datum> argList) async {
    var handlerPair = getHandler(handlerName);

    if (handlerPair != null) {
      var (handlerScript, handler) = handlerPair;
      return await vm.callHandler(handlerScript, this, handler, [Datum.ofVarRef(this), ...argList]);
    } else {
      return callBuiltinHandler(vm, handlerName, argList);
    }
  }

  bool hasProperty(String name) {
    return properties.keys.any((element) => element.toLowerCase() == name.toLowerCase());
  }

  Datum callBuiltinHandler(PlayerVM vm, String handlerName, List<Datum> args) {
    switch (handlerName) {
    case "setAt": {
      setAt(args[0], args[1]);
      return Datum.ofVoid();
    }
    case "setaProp":
      setProp(args[0].stringValue(), args[1]);
      return Datum.ofVoid();
    case "setProp":
      var localPropName = args[0].stringValue();
      var listPropName = args[1];//.stringValue();
      var value = args[2];
      var prop = getPropRef(localPropName)!.get();

      var list = prop.toMap();
      list[listPropName] = value;
      return Datum.ofVoid();
    case "getProp":
    case "getPropRef":
      var localPropName = args[0].stringValue();
      var listPropName = args[1];//.stringValue();
      var list = getPropRef(localPropName)!.get().toMap();
      return list[listPropName] ?? Datum.ofVoid();
    case "handler":
      var name = args.first.stringValue();
      return Datum.ofBool(script.getHandler(name) != null);
    case "count":
      var propertyName = args.first.stringValue();
      var propValue = getProp(propertyName);
      if (propValue is ListDatum) {
        return Datum.ofInt(propValue.toList().length);
      } else if (propValue is PropListDatum) {
        return Datum.ofInt(propValue.toMap().length);
      } else {
        throw Exception("Invalid count call");
      }
    default:
      throw Exception("Unknown handler $handlerName($args) on $this");
    }
  }

  void setAt(Datum key, Datum value) {
    switch (key.stringValue()) {
    case "ancestor":
      if (value.isVoid()) {
        // FIXME: Setting ancestor to void seems to be a no-op.
        // ancestor = null;
      } else if (value.type == DatumType.kDatumVarRef) {
        ancestor = value.toRef() as ScriptInstance;
      } else {
        throw Exception("Invalid ancestor");
      }
    default:
      throw Exception("Unknown prop $key for $this");
    }
  }

  @override
  Ref<Datum>? getPropRef(String propName) {
    var ancestorProp = ancestor?.getPropRef(propName);
    if (properties.containsKey(propName)) {
      return MutableCallbackRef(
        get: () => properties[propName] ?? Datum.ofVoid(), 
        set: (value) => properties[propName] = value
      );
    } else if (ancestorProp != null) {
      return ancestorProp;
    } else {
      return null;
    }
  }

  @override
  void customSetProp(String name, Datum value) {
    var mutableRef = getPropRef(name) as MutableCallbackRef?;
    if (mutableRef != null) {
      mutableRef.set(value);
    } else {
      properties[name] = value;
    }
  }
}
