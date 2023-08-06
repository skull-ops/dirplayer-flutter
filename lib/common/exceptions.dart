class CancelledException implements Exception {
  
}

class UnknownHandlerException implements Exception {
  final String message;
  UnknownHandlerException(String handlerName, dynamic obj)
    : message = "Unknown handler $handlerName for $obj";
}
