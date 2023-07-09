import '../../../common/codewriter.dart';
import '../datum.dart';
import '../node.dart';

class NodeListDatum extends Datum {
  @override DatumType type;
	int i = 0;
	double f = 0;
	String s = "";
	List<Node> l = [];
  List<Datum> datumList = [];
  dynamic varRef;
  Map<Datum, Datum> propList = {};

  @override List<Node> toNodeList() {
    return l;
  }

  @override List<Datum> toList() {
    if ({ DatumType.kDatumArgList, DatumType.kDatumArgListNoRet, DatumType.kDatumList }.contains(type)) {
      return datumList;
    } else {
      throw Exception("Cannot convert NodeListDatum of type $type to list");
    }
  }

  @override void writeScriptText(CodeWriter code, bool dot, bool sum) {
    code.write("[");
    for (var i = 0; i < l.length; i++) {
      if (i > 0) {
        code.write(", ");
      }
      l[i].writeScriptText(code, dot, sum);
    }
    code.write("]");
  }

  NodeListDatum(this.type, this.l);
}
