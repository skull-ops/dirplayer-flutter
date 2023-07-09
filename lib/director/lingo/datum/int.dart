import 'package:dirplayer/director/lingo/addable.dart';
import 'package:logging/logging.dart';

import '../../../common/codewriter.dart';
import '../datum.dart';

class IntDatum extends Datum implements DatumEquatable, DatumComparable {
  final Logger log = Logger("IntDatum");
  int intValue;

  IntDatum(this.intValue);

  @override
  DatumType get type => DatumType.kDatumInt;
  
  @override
  bool isInt() => true;
  
  @override
  bool isNumber() => true;

  @override
  String stringValue() => intValue.toString();

  @override
  double toFloat() => intValue.toDouble();

  @override
  int toInt() => intValue;

  @override
  bool toBool() => intValue != 0;

  @override
  String ilk() => "integer";

  @override
  bool isIlk(String ilk) => ilk == "integer";

  @override
  String toDebugString() => intValue.toString();

  @override 
  void writeScriptText(CodeWriter code, bool dot, bool sum) {
    code.write(intValue.toString());
  }

  @override
  bool equalsDatum(Datum other) {
    if (other.isNumber()) {
      return other.toInt() == intValue;
    } else if (other.isVoid()) {
      return intValue == 0;
    } else if (other.isString()) {
      var parsedValue = int.tryParse(other.stringValue());
      if (parsedValue != null) {
        return parsedValue == intValue;
      } else {
        return false;
      }
    } else {
      log.warning("Datum comparison not supported between IntDatum and $other");
      return false;
    }
  }
  
  @override
  bool isGreaterThan(Datum other) {
    if (other.isNumber()) {
      return intValue > other.toInt();
    } else if (other.isVoid()) {
      return false;
    } else if (other.isString()) {
      var parsedValue = int.tryParse(other.stringValue());
      if (parsedValue != null) {
        return intValue > parsedValue;
      } else {
        return other.stringValue().isEmpty;
      }
    } else {
      log.warning("Datum isGreaterThan not supported between IntDatum and $other");
      return false;
    }
  }
  
  @override
  bool isLessThan(Datum other) {
    if (other.isNumber()) {
      return intValue < other.toInt();
    } else if (other.isVoid()) {
      return false;
    } else if (other.isString()) {
      var parsedValue = int.tryParse(other.stringValue());
      if (parsedValue != null) {
        return intValue < parsedValue;
      } else {
        return other.stringValue().isNotEmpty;
      }
    } else {
      log.warning("Datum isLessThan not supported between IntDatum and $other");
      return false;
    }
  }
}

