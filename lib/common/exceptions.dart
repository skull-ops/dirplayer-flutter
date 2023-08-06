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
