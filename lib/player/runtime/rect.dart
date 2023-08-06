import 'dart:math';

import 'package:dirplayer/common/exceptions.dart';
import 'package:dirplayer/director/lingo/addable.dart';
import 'package:dirplayer/director/lingo/datum.dart';
import 'package:dirplayer/director/lingo/datum/list.dart';
import 'package:dirplayer/director/lingo/datum/var_ref.dart';
import 'package:dirplayer/player/runtime/data_reference.dart';
import 'package:dirplayer/player/runtime/prop_interface.dart';
import 'package:dirplayer/player/runtime/vm.dart';

class IntPoint extends PropInterface implements Addable, Subtractable, HandlerInterface {
  int locH;
  int locV;

  IntPoint(this.locH, this.locV);

  @override
  Ref<Datum>? getPropRef(String propName) {
    switch (propName) {
    case "locH":
      return MutableCallbackRef(
        get: () => Datum.ofInt(locH),
        set: (value) => locH = value.toInt(),
      );
    case "locV":
      return MutableCallbackRef(
        get: () => Datum.ofInt(locV),
        set: (value) => locV = value.toInt(),
      );
    default:
      return null;
    }
  }

  @override
  String toString() {
    return "point($locH, $locV)";
  }

  @override
  Datum addOperator(Datum other) {
    int otherX;
    int otherY;

    if (other is VarRefDatum && other.value is IntPoint) {
      otherX = (other.value as IntPoint).locH;
      otherY = (other.value as IntPoint).locV;
    } else if (other is ListDatum) {
      otherX = other.value[0].toInt();
      otherY = other.value[1].toInt();
    } else {
      throw Exception("Cannot add $other to $this");
    }

    return Datum.ofVarRef(IntPoint(locH + otherX, locV + otherY));
  }

  @override
  Datum subtractOperator(Datum other) {
    int otherX;
    int otherY;

    if (other is VarRefDatum && other.value is IntPoint) {
      otherX = (other.value as IntPoint).locH;
      otherY = (other.value as IntPoint).locV;
    } else if (other is ListDatum) {
      otherX = other.value[0].toInt();
      otherY = other.value[1].toInt();
    } else {
      throw Exception("Cannot add $other to $this");
    }

    return Datum.ofVarRef(IntPoint(locH - otherX, locV - otherY));
  }
  
  @override
  Future<Datum> callHandler(PlayerVM vm, String handlerName, List<Datum> argList) async {
    switch (handlerName) {
    case "getAt":
      int pos = argList[0].toInt();
      var listValue = [locH, locV];
      return Datum.ofInt(listValue[pos - 1]);
    default:
      throw UnknownHandlerException(handlerName, this);
    }
  }
}

class IntRect extends PropInterface implements HandlerInterface, Addable, Subtractable {
  List<int> listValue;

  int get left => listValue[0];
  int get top => listValue[1];
  int get right => listValue[2];
  int get bottom => listValue[3];
  int get width => right - left;
  int get height => bottom - top;

  IntRect(int left, int top, int right, int bottom)
    : listValue = [left, top, right, bottom];

  static IntRect fromQuad(IntPoint topLeft, IntPoint topRight, IntPoint bottomRight, IntPoint bottomLeft) {
    assert(topLeft.locV == topRight.locV);
    assert(topRight.locH == bottomRight.locH);
    assert(bottomLeft.locV == bottomRight.locV);
    assert(bottomLeft.locH == topLeft.locH);

    return IntRect(topLeft.locH, topLeft.locV, bottomRight.locH, bottomRight.locV);
  }

  List<int> toList() {
    return listValue;
  }

  @override
  Ref<Datum>? getPropRef(String propName) {
    switch (propName) {
    case "width":
      return CallbackRef(get: () => Datum.ofInt(right - left));
    case "height":
      return CallbackRef(get: () => Datum.ofInt(bottom - top));
    default:
      return null;
    }
  }

  
  @override
  Future<Datum> callHandler(PlayerVM vm, String handlerName, List<Datum> argList) async {
    switch (handlerName) {
    case "getAt":
      var listValue = toList();
      return Datum.ofInt(listValue[argList.first.toInt() - 1]);
    case "setAt":
      var pos = argList[0].toInt();
      var value = argList[1].toInt();
      listValue[pos - 1] = value;
      return Datum.ofVoid();
    default:
      return Future.error(UnknownHandlerException(handlerName, this));
    }
  }

  @override
  Datum addOperator(Datum other) {
    if (other is ListDatum && other.value.length == 4) {
      return Datum.ofVarRef(
        IntRect(
          left + other.value[0].toInt(),
          top + other.value[1].toInt(), 
          right + other.value[2].toInt(), 
          bottom + other.value[3].toInt(),
        )
      );
    } else if (other is VarRefDatum && other.value is IntRect) {
      var otherRect = other.toRef<IntRect>();
      return Datum.ofVarRef(
        IntRect(
          left + otherRect.left,
          top + otherRect.top, 
          right + otherRect.right, 
          bottom + otherRect.bottom,
        )
      );
    } else {
      throw Exception("Cannot add $other to rect");
    }
  }

  @override
  Datum subtractOperator(Datum other) {
    if (other is ListDatum && other.value.length == 4) {
      return Datum.ofVarRef(
        IntRect(
          left - other.value[0].toInt(),
          top - other.value[1].toInt(), 
          right - other.value[2].toInt(), 
          bottom - other.value[3].toInt(),
        )
      );
    } else if (other is VarRefDatum && other.value is IntRect) {
      var otherRect = other.value as IntRect;
      return Datum.ofVarRef(
        IntRect(
          left - otherRect.left,
          top - otherRect.top, 
          right - otherRect.right, 
          bottom - otherRect.bottom,
        )
      );
    } else {
      throw Exception("Cannot subtract $other from rect");
    }
  }

  @override
  String toString() {
    return "rect($left, $top, $right, $bottom)";
  }

  IntRect constrain(IntRect toRect) {
    return IntRect(max(left, toRect.left), max(top, toRect.top), min(right, toRect.right), min(bottom, toRect.bottom));
  }

  IntRect intersect(IntRect other) {
    int newLeft = max(left, other.left);
    int newTop = max(top, other.top);
    int newRight = min(right, other.right);
    int newBottom = min(bottom, other.bottom);

    // If there's no intersection, return an empty rectangle
    if (newRight <= newLeft || newBottom <= newTop) {
      return IntRect(0, 0, 0, 0);
    }

    return IntRect(newLeft, newTop, newRight, newBottom);
  }
}
