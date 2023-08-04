import 'package:dirplayer/director/lingo/datum/list.dart';
import 'package:dirplayer/director/lingo/datum/prop_list.dart';
import 'package:dirplayer/player/runtime/compare.dart';
import 'package:flutter/foundation.dart';

import '../../../director/lingo/datum.dart';
import '../vm.dart';

class PropListWrapper { 
  static void setAt(Datum datum, Datum key, Datum value) {
    if (key.isNumber()) {
      var entry = datum.toMap().entries.elementAt(key.toInt() - 1);
      datum.toMap()[entry.key] = value;
    } else {
      setProp(datum, key, value);
    }
  }

  static void setProp(Datum datum, Datum key, Datum value, {bool isRequired = false}) {
    var index = getKeyIndex(datum, key);
    if (isRequired && index == -1) {
      throw Exception("Prop not found $key in $datum");
    } else if (index == -1) {
      datum.toMap()[key] = value;
    } else {
      var keyAtIndex = datum.toMap().keys.elementAt(index);
      datum.toMap()[keyAtIndex] = value;
    }
  }

  static Datum getAt(Datum datum, Datum key) {
    if (key.isNumber()) {
      var entry = datum.toMap().entries.elementAt(key.toInt() - 1);
      return entry.value;
    } else {
      return getByKey(datum, key) ?? Datum.ofVoid();
    }
  }

  static Datum? getByKey(Datum datum, Datum key) {
    var index = getKeyIndex(datum, key);
    if (index != -1) {
      return datum.toMap().values.elementAt(index);
    } else {
      return null;
    }
  }

  static bool deleteProp(Datum datum, Datum key) {
    var index = getKeyIndex(datum, key);
    if (index != -1) {
      var keyAtIndex = datum.toMap().keys.elementAt(index);
      datum.toMap().remove(keyAtIndex);
      return true;
    } else {
      return false;
    }
  }

  static int getKeyIndex(Datum datum, Datum findKey) {
    return datum.toMap().keys.indexed.where((element) {
      var (_, key) = element;
      return customDatumEquals(key, findKey);
    }).firstOrNull?.$1 ?? -1;
  }

  static int getValueIndex(Datum datum, Datum findValue) {
    return datum.toMap().values.indexed.where((element) {
      var (_, value) = element;
      return customDatumEquals(value, findValue);
    }).firstOrNull?.$1 ?? -1;
  }

  static bool customDatumEquals(Datum left, Datum right) {
    // This comparison returns true for strings and symbols of the same value
    // Example: 
    // "a" = #a = true
    // "5" = 5 = true
    if (setEquals({left.type, right.type}, {DatumType.kDatumString, DatumType.kDatumSymbol})) {
      return left.stringValue() == right.stringValue();
    } else if ((left.isString() && right.isNumber()) || (left.isNumber() && right.isString())) {
      return left.stringValue() == right.stringValue();
    } else {
      return datumEquals(left, right);
    }
  }

  static Datum callHandler(PlayerVM vm, Datum datum, String handlerName, List<Datum> args) {
    switch (handlerName) {
    case "setAt":
      setAt(datum, args[0], args[1]);
      return Datum.ofVoid();
    case "addProp":
    case "setaProp":
      setProp(datum, args[0], args[1]);
      return Datum.ofVoid();
    case "setProp":
      setProp(datum, args[0], args[1], isRequired: true);
      return Datum.ofVoid();
    case "getAt":
      return getAt(datum, args[0]);
    case "getaProp":
      var keyIndex = getKeyIndex(datum, args[0]);
      if (keyIndex == -1) {
        return Datum.ofVoid();
      } else {
        return datum.toMap().values.elementAt(keyIndex);
      }
    case "getProp":
      var propKey = args[0];
      var keyIndex = getKeyIndex(datum, propKey);
      if (keyIndex == -1) {
        throw Exception("Unknown prop $propKey for prop list");
      } else {
        return datum.toMap().values.elementAt(keyIndex);
      }
    case "sort":
      if (datum.toMap().isNotEmpty) {
        throw Exception("Cannot sort non-empty map ${datum.toMap()}");
      }
      return Datum.ofVoid();
    case "getPropAt":
      var position = args[0].toInt();
      return datum.toMap().entries.elementAt(position - 1).key;
    case "deleteProp": 
      var propName = args[0];
      assert(propName.isString() || propName.isSymbol());
      return Datum.ofBool(deleteProp(datum, propName));
    case "deleteAt": 
      var position = args[0];
      assert(position.isInt());
      var entry = datum.toMap().entries.elementAt(position.toInt() - 1);
      datum.toMap().remove(entry.key);
      return Datum.ofVoid();
    case "getOne":
      var element = args.first;
      var valueIndex = getValueIndex(datum, element);
      return Datum.ofInt(valueIndex + 1);
    case "findPos":
      var element = args.first;
      var keyIndex = getKeyIndex(datum, element);
      return Datum.ofInt(keyIndex + 1);
    case "duplicate":
      return PropListDatum({...datum.toMap()});
    case "getLast":
      return datum.toMap().values.last;
    case "count":
      int count;
      if (args.isEmpty) {
        count = datum.toMap().length;
      } else {
        assert(args.length == 1);
        var propName = args.first;
        var propValue = getByKey(datum, propName);
        if (propValue is ListDatum) {
          count = propValue.toList().length;
        } else if (propValue is PropListDatum) {
          count = propValue.toMap().length;
        } else {
          throw Exception("Invalid handler count for prop in proplist $propName");
        }
      }
      return Datum.ofInt(count);
    }
    throw Exception("Undefined handler $handlerName for prop list");
  }

  static Datum getProp(Datum obj, String propName) {
    var mapProp = getByKey(obj, Datum.ofString(propName));
    if (mapProp != null) {
      return mapProp;
    }
    switch (propName) {
      case "count":
        return Datum.ofInt(obj.toMap().length);
      case "ilk":
        return Datum.ofSymbol("propList");
      default:
        throw Exception("Undefined prop $propName for prop list");
    }
  }
}
