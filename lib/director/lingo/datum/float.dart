
import 'package:dirplayer/common/util.dart';

import '../../../common/codewriter.dart';
import '../datum.dart';

class FloatDatum extends Datum {
  double floatValue;

  FloatDatum(this.floatValue);

  @override
  DatumType get type => DatumType.kDatumFloat;
  
  @override
  bool isFloat() => true;

  @override
  bool isNumber() => true;

  @override
  String stringValue() => floatValue.toString();

  @override
  double toFloat() => floatValue;

  @override
  int toInt() => floatValue.toInt();

  @override
  String ilk() => "float";

  @override
  bool isIlk(String ilk) => ilk == "float";

  @override
  String toDebugString() => floatValue.toString();

  @override 
  void writeScriptText(CodeWriter code, bool dot, bool sum) {
    code.write(floatToString(floatValue));
  }
}
