import 'package:dirplayer/director/lingo/datum.dart';

class _NullDatum extends Datum {
  @override
  DatumType get type => DatumType.kDatumNull;

  @override
  String toDebugString() {
    return "<Null>";
  }
}

final nullDatum = _NullDatum();
