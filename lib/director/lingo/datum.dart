
import 'package:dirplayer/director/lingo/datum/datum_null.dart';
import 'package:dirplayer/director/lingo/datum/list.dart';
import 'package:dirplayer/director/lingo/datum/node_list.dart';
import 'package:dirplayer/director/lingo/datum/prop_list.dart';
import 'package:dirplayer/director/lingo/datum/string.dart';
import 'package:dirplayer/director/lingo/datum/symbol.dart';
import 'package:dirplayer/director/lingo/datum/var_ref.dart';
import 'package:dirplayer/director/lingo/datum/void.dart';
import 'package:dirplayer/player/runtime/compare.dart';

import '../../common/codewriter.dart';
import 'datum/float.dart';
import 'datum/int.dart';
import 'node.dart';

enum DatumType {
  kDatumNull,
	kDatumVoid,
	kDatumSymbol,
	kDatumVarRef,
	kDatumString,
	kDatumInt,
	kDatumFloat,
	kDatumList,
	kDatumArgList,
	kDatumArgListNoRet,
	kDatumPropList,
  kDatumEval,
}

abstract class Datum {
  DatumType get type;

  static Datum ofNull() => nullDatum;
	static Datum ofVoid() => VoidDatum();
	static Datum ofInt(int val) => IntDatum(val);
  static Datum ofFloat(double val) => FloatDatum(val);
  static Datum ofString(String val, {DatumType type = DatumType.kDatumString}) => StringDatum(val, type);
  static Datum ofSymbol(String val) => SymbolDatum(val);
  static Datum ofNodeList(DatumType type, List<Node> val) => NodeListDatum(type, val);
  static Datum ofDatumList(DatumType type, List<Datum> val) => ListDatum(val, type: type);
  static Datum ofVarRef(dynamic val) => VarRefDatum(val);
  static Datum ofPropList(Map<Datum, Datum> propList) => PropListDatum(propList);
  static Datum ofBool(bool val) => IntDatum(val ? 1 : 0);

  bool isNumber() {
    return type == DatumType.kDatumInt || type == DatumType.kDatumFloat;
  }
  bool isInt() => false;
  bool isFloat() => false;
  bool isString() => false;
  bool isSymbol() {
    return type == DatumType.kDatumSymbol;
  }

  String stringValue() {
    throw Exception("Can not convert datum of type $type to string");
  }

	int toInt() {
    throw Exception("Can not convert datum of type $type to int");
  }

  double toFloat() {
    throw Exception("Can not convert datum of type $type to float");
  }

  Map<Datum, Datum> toMap() {
    throw Exception("Can not convert datum of type $type to map");
  }

  String ilk() {
    throw Exception("Unknown datum type for ilk: $type");
  }

  bool isIlk(String ilk) {
    throw Exception("Unknown datum type for ilk: $type");
  }

  bool isVoid() => false;
  bool isList() => false;

  List<Datum> toList() {
    throw Exception("Can not convert datum of type $type to list");
  }

  List<Node> toNodeList() {
    throw Exception("Can not convert datum of type $type to node list");
  }

  bool toBool() {
    print("$type cannot be converted to bool");
    return false;
  }

  T toRef<T>() {
    throw Exception("Can not convert datum of type $type to ref of type $T");
  }
  
	void writeScriptText(CodeWriter code, bool dot, bool sum) {
    code.write("[NOT_IMPLEMENTED:$runtimeType+$type]");
  }
	//void writeJSON(Common::JSONWriter &json) const;

  String toDebugString() {
    return type.toString();
  }

  @override
  String toString() {
    return toDebugString();
  }

  @override
  bool operator ==(dynamic other) {
    // TODO update
    if (other is Datum) {
      return datumEquals(this, other);
    } else if (other == null) {
      return isVoid();
    } else {
      return false;
    }
  }

  @override
  int get hashCode {
    // TODO update
    if (isList()) {
      return toList().hashCode;
    } else if (isInt()) {
      return toInt().hashCode;
    } else if (isFloat()) {
      return toFloat().hashCode;
    } else if (isString() || isSymbol()) {
      return stringValue().hashCode;
    } else {
      throw Exception("hashCode not implemented for $this");
    }
  }
}
