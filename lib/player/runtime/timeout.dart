import 'dart:async';

import 'package:dirplayer/director/lingo/datum.dart';
import 'package:dirplayer/player/runtime/data_reference.dart';
import 'package:dirplayer/player/runtime/prop_interface.dart';
import 'package:dirplayer/player/runtime/vm.dart';
import 'package:logging/logging.dart';

class TimeoutRef implements HandlerInterface, PropInterface {
  static final log = Logger("TimeoutRef");
  String name;
  TimeoutManager timeoutManager;

  TimeoutRef(this.name, this.timeoutManager);

  @override
  Future<Datum> callHandler(PlayerVM vm, String handlerName, List<Datum> argList) async {
    switch (handlerName) {
    case "new":
      var timeoutPeriod = argList[0].toInt();
      var timeoutHandler = argList[1].stringValue();
      var targetObject = argList.elementAtOrNull(2);
      assert(argList.length == 3);

      log.fine("[!!] info: setting up timeout $name for $timeoutHandler and target $targetObject");
      var timeout = Timeout(vm, name, timeoutPeriod, timeoutHandler, targetObject, this);
      timeoutManager.timeouts.add(timeout);
      timeout.schedule();
      return Datum.ofVarRef(this);
    case "forget":
      timeoutManager.forgetTimeout(name);
      return Datum.ofVoid();
    default:
      throw Exception("Unknown handler $handlerName on $this");
    }
  }

  @override
  Ref<Datum>? getPropRef(String propName) {
    switch (propName) {
    case "name":
      return CallbackRef(get: () => Datum.ofString(name));
    default:
      return null;
    }
  }

  @override
  String toString() {
    return "timeout(\"$name\")";
  }
}

class Timeout {
  PlayerVM vm;
  String name;
  int period;
  String handler;
  Datum? targetObject;
  Timer? timer;
  TimeoutRef timeoutRef;

  Timeout(this.vm, this.name, this.period, this.handler, this.targetObject, this.timeoutRef);

  void schedule() {
    timer?.cancel();
    timer = Timer.periodic(
      Duration(milliseconds: period), 
      (timer) {
        onError(Exception ex) {
          print("Timeout $name trigger failed with $ex");
          timer.cancel();
        }
        try {
          trigger().catchError((e) => onError(e as Exception));
        } on Exception catch (e) {
          onError(e);
        }
      }
    );
  }

  Future trigger() async {
    var targetObject = this.targetObject;
    await vm.reserve(() async {
      if (targetObject != null) {
        return await vm.callObjectHandler(targetObject, handler, [Datum.ofVarRef(timeoutRef)]);
      } else {
        return await vm.callGlobalHandler(handler, [Datum.ofVarRef(timeoutRef)]);
      }
    });
  }

  void cancel() {
    timer?.cancel();
    timer = null;
  }
}

class TimeoutManager {
  List<Timeout> timeouts = [];

  void clear() {
    for (var timeout in timeouts) {
      timeout.cancel();
    }
    timeouts.clear();
  }

  Timeout? getTimeout(String name) {
    return timeouts
      .where((element) => element.name.toLowerCase() == name.toLowerCase())
      .firstOrNull;
  }

  void forgetTimeout(String name) {
    var timeout = getTimeout(name);
    if (timeout != null) {
      timeout.cancel();
      timeouts.remove(timeout);
    }
  }
}
