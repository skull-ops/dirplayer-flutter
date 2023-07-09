
import 'dart:math';

import 'package:dirplayer/director/lingo/addable.dart';
import 'package:dirplayer/player/runtime/compare.dart';
import 'package:dirplayer/player/runtime/data_reference.dart';
import 'package:dirplayer/player/runtime/datum_operations.dart';
import 'package:dirplayer/player/runtime/prop_interface.dart';
import 'package:dirplayer/player/runtime/rect.dart';

import '../../../common/codewriter.dart';
import '../../../player/runtime/vm.dart';
import '../datum.dart';

class ListDatum extends Datum implements HandlerInterface, PropInterface, Addable, Subtractable {
  List<Datum> value;
  @override DatumType type;
  bool isSorted = false;

  ListDatum(this.value, { this.type = DatumType.kDatumList });
  
  @override
  bool isList() => true;

  @override
  List<Datum> toList() => value;

  @override
  String ilk() => "list";

  @override
  bool isIlk(String ilk) => ["list", "linearlist"].contains(ilk);

  @override
  String toDebugString() => "[${value.map((e) => e.toDebugString()).join(", ")}]";

  void sort() {
    value.sort((left, right) {
      switch (compareDatums(left, right)) {
        case ComparisonResult.lessThan: return -1;
        case ComparisonResult.same: return 0;
        case ComparisonResult.greaterThan: return 1;
      }
    });
    isSorted = true;
  }

  void append(Datum item) {
    value.add(item);
  }

  void addAt(int position, Datum item) {
    value.insert(position - 1, item);
  }

  int findIndexToAdd(Datum item) {
    var low = 0;
    var high = value.length;

    while (low < high) {
      var mid = (low + high) ~/ 2;
      if (compareDatums(value[mid], item) == ComparisonResult.lessThan) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }

    return low;
  }

  void add(Datum item) {
    if (isSorted) {
      var indexToAdd = findIndexToAdd(item);
      addAt(indexToAdd + 1, item);
    } else {
      append(item);
    }
  }

  Datum getAt(int position) {
    return value[position - 1];
  }

  void setAt(int position, Datum item) {
    var index = position - 1;
    var length = value.length;
    if (index < length) {
      value[index] = item;
    } else {
      var paddingSize = index - length;
      value.addAll(List.filled(paddingSize, Datum.ofInt(0)));
      value.add(item);
    }
  }

  bool deleteOne(Datum item) {
    var index = value.indexWhere((element) => datumEquals(element, item));
    if (index >= 0) {
      value.removeAt(index);
    }
    return index >= 0;
  }

  @override
  Future<Datum> callHandler(PlayerVM vm, String handlerName, List<Datum> args) async {
    switch (handlerName) {
    case "setAt":
      setAt(args[0].toInt(), args[1]);
      return Datum.ofVoid();
    case "getAt":
      return getAt(args[0].toInt());
    case "getOne":
      var find = args[0];
      var index = value.indexWhere((element) => datumEquals(element, find));
      return Datum.ofInt(index + 1);
    case "sort":
      sort();
      return Datum.ofVoid();
    case "append":
      var item = args.first;
      append(item);
      return Datum.ofVoid();
    case "add":
      // TODO:  adds a value to a sorted list according to the list’s order.
      var value = args.first;
      add(value);
      return Datum.ofVoid();
    case "addAt":
      addAt(args[0].toInt(), args[1]);
      return Datum.ofVoid();
    case "duplicate":
      return Datum.ofDatumList(type, [...toList()]);
    case "getLast":
      var list = toList();
      if (list.isNotEmpty) {
        return list.last;
      } else {
        return Datum.ofVoid();
      }
    case "deleteOne":
      var value = args.first;
      return Datum.ofBool(deleteOne(value));
    case "deleteAt":
      var position = args.first.toInt();
      if (position <= value.length) {
        value.removeAt(position - 1);
      } else {
        throw Exception("Index out of range");
      }
      return Datum.ofVoid();
    case "findPos":
    case "getPos":
      var element = args.first;
      return Datum.ofInt(value.indexOf(element) + 1);
    }
    throw Exception("Unknown handler $handlerName for list");
  }

  @override
  Ref<Datum>? getPropRef(String propName) {
    switch (propName) {
    case "count":
      return CallbackRef(get: () => Datum.ofInt(value.length));
    case "ilk":
      return CallbackRef(get: () => Datum.ofSymbol(ilk()));
    default:
      return null;
    }
  }

  @override 
  void writeScriptText(CodeWriter code, bool dot, bool sum) {
    var l = value;
    if (type == DatumType.kDatumList) {
      code.write("[");
    }
    for (int i = 0; i < l.length; i++) {
      if (i > 0) {
        code.write(", ");
      }
      l[i].writeScriptText(code, dot, sum);
    }
    if (type == DatumType.kDatumList) {
      code.write("]");
    }
  }

  @override
  Datum addOperator(Datum other) {
    if (other is ListDatum) {
      var intersectionCount = min(value.length, other.value.length);
      var result = List.generate(intersectionCount, (index) => addDatums(value[index], other.value[index]));
      return Datum.ofDatumList(type, result);
    } else {
      throw Exception("Cannot add $other to list");
    }
  }

  @override
  Datum subtractOperator(Datum other) {
    if (other is ListDatum) {
      var intersectionCount = min(value.length, other.value.length);
      var result = List.generate(intersectionCount, (index) => subtractDatums(value[index], other.value[index]));
      return Datum.ofDatumList(type, result);
    } else {
      throw Exception("Cannot subtract $other from list");
    }
  }

  @override
  T toRef<T>() {
    if (T == IntPoint) {
      return IntPoint(value[0].toInt(), value[1].toInt()) as T;
    } else {
      return super.toRef();
    }
  }
}
