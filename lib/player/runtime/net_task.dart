
import 'dart:async';
import 'dart:typed_data';

sealed class NetResult {
}

class NetResultSuccess extends NetResult {
  Uint8List bytes;
  NetResultSuccess(this.bytes);
}

class NetResultError extends NetResult {
  Exception error;
  NetResultError(this.error);

  int get errorCode => 4; // TODO
}

// TODO add state
class NetTask {
  int id;
  String url;
  Uri resolvedUri;
  Uint8List? data;
  Completer<NetResult> completer = Completer();
  NetResult? result;

  bool get isDone => result != null;

  NetTask(this.id, this.url, this.resolvedUri);
}
