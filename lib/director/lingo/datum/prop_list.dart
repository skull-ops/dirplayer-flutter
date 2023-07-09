
import '../../../common/codewriter.dart';
import '../datum.dart';

class PropListDatum extends Datum {
  Map<Datum, Datum> value;
  @override final type = DatumType.kDatumPropList;

  PropListDatum(this.value);
  
  //@override
  //bool isList() => true;

  @override
  String ilk() => "proplist";

  @override
  bool isIlk(String ilk) => ["list", "proplist"].contains(ilk.toLowerCase());

  @override
  Map<Datum, Datum> toMap() => value;

  @override
  String toDebugString() {
    if (value.isEmpty) {
      return "[:]";
    } else {
      return "[${value.entries.map((e) => "${e.key.toDebugString()}: ${e.value.toDebugString()}").join(", ")}]";
    }
  }

  @override 
  void writeScriptText(CodeWriter code, bool dot, bool sum) {
    var l = value;
    code.write("[");
    if (l.isEmpty) {
      code.write(":");
    } else {
      for (var element in l.entries.indexed) {
        var (i, entry) = element;
        if (i > 0) {
          code.write(", ");
        }
        entry.key.writeScriptText(code, dot, sum);
        code.write(": ");
        entry.value.writeScriptText(code, dot, sum);
      }
    }
    code.write("]");
  }
}
