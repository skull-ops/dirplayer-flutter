import 'package:dirplayer/director/lingo/datum/string.dart';
import 'package:dirplayer/player/runtime/vm.dart';

import '../../../player/runtime/chunk_ref.dart';
import '../../../player/runtime/prop_interface.dart';
import '../../../player/runtime/wrappers/string.dart';
import '../datum.dart';

class StringChunkDatum extends StringDatum implements HandlerInterface {
  final StringDatum originalString;
  final StringChunkRef chunkRef;

  StringChunkDatum(this.originalString, this.chunkRef) : super(chunkRef.stringValue(originalString.stringValue()), DatumType.kDatumString);

  List<String> getItems() => chunkRef.getItems(originalString.stringValue());

  void delete() {
    var result = chunkRef.deletingFrom(originalString.value);
    originalString.value = result;
  }

  @override
  Future<Datum> callHandler(PlayerVM vm, String handlerName, List<Datum> argList) async {
    switch (handlerName) {
    case "delete":
      delete();
      return Datum.ofVoid();
    default:
      return StringWrapper.callHandler(vm, this, handlerName, argList);
    }
  }
}