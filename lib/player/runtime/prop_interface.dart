
import 'package:dirplayer/player/runtime/data_reference.dart';
import 'package:dirplayer/player/runtime/vm.dart';

import '../../director/lingo/datum.dart';

abstract class CustomSetPropInterface {
  void customSetProp(String name, Datum value);
}

abstract class VMPropInterface {
  Ref<Datum>? getVMPropRef(String propName, PlayerVM vm);
}

abstract class PropInterface {
  Ref<Datum>? getPropRef(String propName);
}

extension Compat on PropInterface {
  Datum getProp(String name) {
    var ref = getPropRef(name);
    if (ref != null) {
      return ref.get();
    } else {
      throw Exception("Cannot get property $name of $this");
    }
  }
  void setProp(String name, Datum value) {
    var propRef = getPropRef(name);
    if (propRef is MutableRef) {
      (propRef as MutableRef).set(value);
    } else if (this is CustomSetPropInterface) {
      (this as CustomSetPropInterface).customSetProp(name, value);
    } else {
      throw Exception("Cannot set property $name of $this to $value");
    }
  }
}

extension VMPropInterfaceCompat on VMPropInterface {
  void setVMProp(String name, Datum value, PlayerVM vm) {
    var propRef = getVMPropRef(name, vm);
    if (propRef is MutableRef) {
      (propRef as MutableRef).set(value);
    } else {
      throw Exception("Cannot set VM property $name of $this to $value");
    }
  }
}

abstract class HandlerInterface {
  Future<Datum> callHandler(PlayerVM vm, String handlerName, List<Datum> argList);
}
