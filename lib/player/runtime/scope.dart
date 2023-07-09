import 'package:dirplayer/director/lingo/handler.dart';
import 'package:dirplayer/player/runtime/script.dart';

import '../../director/lingo/datum.dart';

class Scope {
  Script script;
  ScriptInstance? receiver;
  Handler handler;
  List<Datum> arguments;
  int handlerPosition = 0;
  Map<String, Datum> locals = {};
  List<int> loopPositions = [];
  Datum returnValue = Datum.ofVoid();
  List<Datum> stack = [];
  
  Scope(this.script, this.receiver, this.handler, this.arguments);
}
