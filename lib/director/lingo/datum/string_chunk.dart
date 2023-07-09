import 'package:dirplayer/director/lingo/datum/string.dart';

import '../../../player/runtime/chunk_ref.dart';
import '../datum.dart';

class StringChunkDatum extends StringDatum {// implements HandlerInterface {
  final StringDatum originalString;
  final StringChunkRef chunkRef;

  StringChunkDatum(this.originalString, this.chunkRef) : super(chunkRef.stringValue(originalString.stringValue()), DatumType.kDatumString);

  List<String> getItems() => chunkRef.getItems(originalString.stringValue());
}