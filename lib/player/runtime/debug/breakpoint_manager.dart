
import 'package:dirplayer/director/lingo/handler.dart';
import 'package:dirplayer/player/runtime/script.dart';
import 'package:flutter/material.dart';

class Breakpoint {
  String scriptName;
  String handlerName;
  int bytecodePos;

  Breakpoint(this.scriptName, this.handlerName, this.bytecodePos);
}

class BreakpointManager with ChangeNotifier {
  List<Breakpoint> breakpoints = [];

  void addBreakpoint(Breakpoint breakpoint) {
    breakpoints.add(breakpoint);
    notifyListeners();
  }

  Breakpoint? findBreakpoint(bool Function(Breakpoint breakpoint) predicate) {
    return breakpoints.where(predicate).firstOrNull;
  }

  Breakpoint? findBreakpointForBytecode(Script script, Handler handler, int bytecodePos) {
    return findBreakpoint(
      (it) => it.scriptName == script.name && it.handlerName == handler.name && it.bytecodePos == bytecodePos
    );
  }

  void removeBreakpoint(Breakpoint breakpoint) {
    breakpoints.remove(breakpoint);
    notifyListeners();
  }
}
