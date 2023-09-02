import 'package:dirplayer/player/runtime/scope.dart';

import '../director/lingo/datum.dart';

class CancelledException implements Exception {
  
}

class UnknownHandlerException implements Exception {
  final String message;
  final StackTrace stackTrace;

  UnknownHandlerException(String handlerName, List<Datum> args, dynamic obj) : 
    message = "Unknown handler $handlerName(${args.join(", ")}) for $obj",
    stackTrace = StackTrace.current;

  @override
  String toString() {
    return "$message\r\n$stackTrace";
  }
}

class ScriptExecutionException implements Exception {
  final Object cause;
  final List<Scope> lingoStack;

  ScriptExecutionException(this.cause, this.lingoStack);

  @override
  String toString() {
    return "ScriptExecutionException caused by: $cause";
  }

  String lingoStackTrace() {
    var message = StringBuffer();
    for (var scope in lingoStack.reversed) {
      var currentBytecode = scope.handler.bytecodeArray[scope.handlerPosition];
      message.writeln("at ${scope.script}.${scope.handler.name}:${currentBytecode.pos} => receiver ${scope.receiver}");
    }

    return message.toString();
  }
}
