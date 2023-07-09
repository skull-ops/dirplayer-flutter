import '../../director/lingo/addable.dart';
import '../../director/lingo/datum.dart';
import '../../director/lingo/datum/var_ref.dart';

Datum addDatums(Datum left, Datum right) {
  if (left.isVoid() && !right.isVoid()) {
    return right;
  } else if (!left.isVoid() && right.isVoid()) {
    return left;
  } else if (left.isNumber() && right.isNumber()) {
    if (left.type == DatumType.kDatumFloat || right.type == DatumType.kDatumFloat) {
      return Datum.ofFloat(left.toFloat() + right.toFloat());
    } else {
      return Datum.ofInt(left.toInt() + right.toInt());
    }
  } else if (left is Addable) {
    return (left as Addable).addOperator(right);
  } else if (left is VarRefDatum && left.value is Addable) {
    var leftAddable = left.toRef<Addable>();
    return leftAddable.addOperator(right);
  } else {
    throw Exception("Cannot add non-numeric datums $left and $right");
  }
}

Datum subtractDatums(Datum left, Datum right) {
  if (left.isNumber() && right.isNumber()) {
    if (left.type == DatumType.kDatumFloat || right.type == DatumType.kDatumFloat) {
      return Datum.ofFloat(left.toFloat() - right.toFloat());
    } else {
      return Datum.ofInt(left.toInt() - right.toInt());
    }
  } else if (left is Subtractable) {
    return (left as Subtractable).subtractOperator(right);
  } else if (left is VarRefDatum && left.value is Subtractable) {
    var leftSubbable = left.toRef<Subtractable>();
    return leftSubbable.subtractOperator(right);
  } else {
    throw Exception("Cannot subtract non-numeric datums $left and $right");
  }
}
