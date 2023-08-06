
import 'package:dirplayer/director/lingo/addable.dart';
import 'package:dirplayer/player/runtime/data_reference.dart';
import 'package:dirplayer/player/runtime/prop_interface.dart';

import '../../../common/codewriter.dart';
import '../datum.dart';

class _VoidDatum extends Datum implements DatumComparable, DatumEquatable, PropInterface {
  @override final type = DatumType.kDatumVoid;

  _VoidDatum();
  
  @override
  bool isVoid() => true;

  @override
  String ilk() => "void";

  @override
  int toInt() => 0;

  @override
  bool isIlk(String ilk) => ["void"].contains(ilk);

  @override
  String toDebugString() => "<Void>";

  @override
  String stringValue() {
    return "";
  }

  @override 
  void writeScriptText(CodeWriter code, bool dot, bool sum) {
    code.write("VOID");
  }
  
  @override
  bool isLessThan(Datum other) {
    if (other.isNumber()) {
      return true;
    } else if (other.isString() || other.isSymbol()) {
      return other.stringValue().isNotEmpty;
    } else {
      return false;
    }
  }

  @override
  bool isGreaterThan(Datum other) {
    return false;
  }

  @override
  bool equalsDatum(Datum other) {
    return other.isVoid() || (other.isNumber() && other.toInt() == 0);
  }

  @override
  Ref<Datum>? getPropRef(String propName) {
    switch (propName) {
    case "ilk":
      return CallbackRef(get: () => Datum.ofSymbol("void"));
    default:
      return null;
    }
  }
}

final voidDatum = _VoidDatum();
