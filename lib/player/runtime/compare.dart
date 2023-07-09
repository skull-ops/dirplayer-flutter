
import 'package:dirplayer/director/lingo/addable.dart';
import 'package:flutter/foundation.dart';

import '../../director/lingo/datum.dart';

enum ComparisonResult {
  lessThan,
  same,
  greaterThan
}

ComparisonResult compareDatums(Datum left, Datum right) {
  var types = {left.type, right.type};
  if (left is DatumComparable) {
    var leftComparable = left as DatumComparable;
    if (leftComparable.isLessThan(right)) {
      return ComparisonResult.lessThan;
    } else if (leftComparable.isGreaterThan(right)) {
      return ComparisonResult.greaterThan;
    } else {
      return ComparisonResult.same;
    }
  } else if (right is DatumComparable) {
    var rightComparable = right as DatumComparable;
    if (rightComparable.isLessThan(left)) {
      return ComparisonResult.greaterThan;
    } else if (rightComparable.isGreaterThan(left)) {
      return ComparisonResult.lessThan;
    } else {
      return ComparisonResult.same;
    }
  } else if (left.type == DatumType.kDatumInt && left.type == right.type) {
    return compareInts(left.toInt(), right.toInt());
  } else if (left.type == DatumType.kDatumString && left.type == right.type) {
    return compareStrings(left.stringValue().toLowerCase(), right.stringValue().toLowerCase());
  } else if (left.type == DatumType.kDatumSymbol && left.type == right.type) {
    return compareStrings(left.stringValue().toLowerCase(), right.stringValue().toLowerCase());
  } else if (setEquals(types, { DatumType.kDatumString, DatumType.kDatumInt })) {
    return compareInts(left.toInt(), right.toInt());
  } else if (setEquals(types, { DatumType.kDatumFloat })) {
    return compareFloats(left.toFloat(), right.toFloat());
  } else if (setEquals(types, { DatumType.kDatumFloat , DatumType.kDatumInt })) {
    return compareFloats(left.toFloat(), right.toFloat());
  } else if (setEquals(types, { DatumType.kDatumVarRef })) {
    var leftRef = left.toRef();
    var rightRef = right.toRef();
    if (identical(leftRef, rightRef)) {
      return ComparisonResult.same;
    } else {
      // TODO what do?
      return ComparisonResult.lessThan;
    }
  } else {
    throw Exception("Datum comparison not supported: $left and $right; ${left.type} and ${right.type}");
  }
}

bool datumEquals(Datum left, Datum right) {
  if (identical(left, right)) {
    return true;
  }

  var types = {left.type, right.type};
  if (left is DatumEquatable) {
    return (left as DatumEquatable).equalsDatum(right);
  } else if (setEquals(types, { DatumType.kDatumFloat })) {
    return left.toFloat() == right.toFloat();
  } else if (setEquals(types, { DatumType.kDatumSymbol })) {
    return left.stringValue().toLowerCase() == right.stringValue().toLowerCase();
  } else if (setEquals(types, { DatumType.kDatumVoid })) {
    return true;
  } else if (setEquals(types, { DatumType.kDatumVarRef })) {
    return left.toRef() == right.toRef();
  } else if (setEquals(types, { DatumType.kDatumFloat , DatumType.kDatumInt })) {
    return left.toFloat() == right.toFloat();
  } else if (setEquals(types, { DatumType.kDatumList })) {
    var leftList = left.toList();
    var rightList = right.toList();
    if (leftList.length != rightList.length) {
      return false;
    }
    var isEqual = true;
    for (var i = 0; i < leftList.length; i++) {
      if (!datumEquals(leftList[i], rightList[i])) {
        isEqual = false;
        break;
      }
    }
    return isEqual;
  } else if (setEquals(types, { DatumType.kDatumPropList })) {
    throw Exception("Comparing two propLists");
  } else {
    print("warn: [!!] Datum comparison not supported: $left and $right; ${left.type} and ${right.type}");
    return false;
  }
}

ComparisonResult compareInts(int left, int right) {
  if (left == right) {
    return ComparisonResult.same;
  } else if (left < right) {
    return ComparisonResult.lessThan;
  } else {
    return ComparisonResult.greaterThan;
  }
}

ComparisonResult compareFloats(double left, double right) {
  if (left == right) {
    return ComparisonResult.same;
  } else if (left < right) {
    return ComparisonResult.lessThan;
  } else {
    return ComparisonResult.greaterThan;
  }
}

ComparisonResult compareStrings(String left, String right) {
  // TODO when less or greater?
  if (left == right) {
    return ComparisonResult.same;
  } else if (left.length < right.length) {
    return ComparisonResult.lessThan;
  } else {
    return ComparisonResult.greaterThan;
  }
}
