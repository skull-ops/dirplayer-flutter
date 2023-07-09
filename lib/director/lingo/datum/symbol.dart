import 'package:dirplayer/player/runtime/data_reference.dart';
import 'package:dirplayer/player/runtime/prop_interface.dart';

import '../../../common/codewriter.dart';
import '../datum.dart';

class SymbolDatum extends Datum implements PropInterface {
  String value;

  SymbolDatum(this.value);

  @override
  DatumType get type => DatumType.kDatumSymbol;
  
  @override
  bool isSymbol() => true;

  @override
  String stringValue() => value;

  @override
  bool toBool() => true;

  @override
  String ilk() => "symbol";

  @override
  bool isIlk(String ilk) => ilk == "symbol";

  @override
  String toDebugString() {
    return "#$value";
  }

  @override 
  void writeScriptText(CodeWriter code, bool dot, bool sum) {
    code.write(toDebugString());
  }

  @override
  Ref<Datum>? getPropRef(String propName) {
    switch (propName) {
    case "ilk":
      return CallbackRef(get: () => Datum.ofSymbol(ilk()));
    default:
      return null;
    }
  }
}
