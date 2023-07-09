import 'package:dirplayer/director/lingo/addable.dart';
import 'package:dirplayer/player/runtime/data_reference.dart';
import 'package:dirplayer/player/runtime/prop_interface.dart';

import '../../../common/codewriter.dart';
import '../../../common/util.dart';
import '../datum.dart';

class StringDatum extends Datum implements PropInterface, DatumEquatable {
  @override DatumType type;
  String value;

  StringDatum(this.value, this.type);

  //@override
  //DatumType get type => DatumType.kDatumString;
  
  @override
  bool isString() => true;

  @override
  String stringValue() => value;

  @override
  double toFloat() => double.tryParse(stringValue()) ?? 0.0;

  @override
  int toInt() => int.tryParse(stringValue()) ?? 0;

  @override
  bool toBool() => value.isNotEmpty;

  @override
  String ilk() => "string";

  @override
  bool isIlk(String ilk) => ilk.toLowerCase() == "string";

  @override
  String toDebugString() {
    return "\"${stringValue()}\"";
  }

  @override 
  void writeScriptText(CodeWriter code, bool dot, bool sum) {
    var s = value;
    if (s.isEmpty) {
      code.write("EMPTY");
      return;
    }
    if (s.length == 1) {
      switch (s[0]) {
      case '\x03':
        code.write("ENTER");
        return;
      case '\x08':
        code.write("BACKSPACE");
        return;
      case '\t':
        code.write("TAB");
        return;
      case '\r':
        code.write("RETURN");
        return;
      case '"':
        code.write("QUOTE");
        return;
      default:
        break;
      }
    }
    if (sum) {
      code.write("\"${escapeString(s)}\"");
      return;
    }
    code.write("\"$s\"");
  }
  
  @override
  Ref<Datum>? getPropRef(String propName) {
    switch (propName) {
    case "ilk":
      return CallbackRef(get: () => Datum.ofSymbol("string"));
    default:
      return null;
    }
  }

  @override
  bool equalsDatum(Datum other) {
    if (other.isString() || other.isSymbol()) {
      return stringValue().toLowerCase() == other.stringValue().toLowerCase();
    } else if (other.isInt()) {
      var thisIntValue = int.tryParse(stringValue());
      return thisIntValue != null && thisIntValue == other.toInt();
    } else if (other.isFloat()) {
      var thisFloatValue = double.tryParse(stringValue());
      return thisFloatValue != null && thisFloatValue == other.toFloat();
    } else {
      print("Unsupported comparison between StringDatum and ${other.type}");
      return false;
    }
  }
}
