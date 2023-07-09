
import 'package:dirplayer/player/runtime/vm.dart';

import '../../datum.dart';

abstract class EvaluatedDatum extends Datum {
  Future<Datum> evaluate(PlayerVM vm);
}

class HandlerCallDatum extends EvaluatedDatum {
  String handlerName;
  List<Datum> args;

  HandlerCallDatum(this.handlerName, this.args);

  @override
  DatumType get type => DatumType.kDatumEval;

  @override
  Future<Datum> evaluate(PlayerVM vm) async {
    return await vm.callGlobalHandler(handlerName, args);
  }
}