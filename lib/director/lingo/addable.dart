import 'package:dirplayer/director/lingo/datum.dart';

import '../../player/runtime/compare.dart';

abstract class Addable {
  Datum addOperator(Datum other);
}

abstract class Subtractable {
  Datum subtractOperator(Datum other);
}

abstract class DatumEquatable {
  bool equalsDatum(Datum other);
}

abstract class DatumComparable {
  bool isGreaterThan(Datum other);
  bool isLessThan(Datum other);
}
