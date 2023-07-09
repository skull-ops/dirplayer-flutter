import 'dart:async';

import 'package:dirplayer/director/lingo/bytecode.dart';
import 'package:dirplayer/director/lingo/handler.dart';
import 'package:dirplayer/player/runtime/debug/breakpoint_manager.dart';
import 'package:dirplayer/player/runtime/script.dart';

class BreakpointContext {
  Breakpoint breakpoint;
  Script script;
  Handler handler;
  Bytecode bytecode;
  Completer completer;

  BreakpointContext({ required this.breakpoint, required this.script, required this.handler, required this.bytecode, required this.completer });
}
