
import 'dart:io';

import 'package:dirplayer/common/util.dart';
import 'package:dirplayer/director/chunks/config.dart';
import 'package:dirplayer/director/lingo/datum.dart';
import 'package:dirplayer/player/runtime/cast_manager.dart';
import 'package:dirplayer/player/runtime/net_manager.dart';
import 'package:dirplayer/player/runtime/prop_interface.dart';
import 'package:dirplayer/player/runtime/stage.dart';
import 'package:intl/intl.dart';

import '../../director/chunks/score.dart';
import '../../director/file.dart';
import 'data_reference.dart';
import 'score.dart';

class Movie extends PropInterface {
  DirectorFile? file;

  int movieLeft = 0;
  int movieRight = 100;
  int movieTop = 0;
  int movieBottom = 100;

  bool dotSyntax = true;
  int exitLock = 0;
  int puppetTempo = 0;
  int currentFrame = 1;
  int dirVersion = 0;

  CastManager castManager = CastManager();
  var score = Score();

  Future loadFromFile(DirectorFile file, NetManager netManager) async {
    this.file = file;

    dirVersion = file.version;
    movieLeft = file.config!.movieLeft;
    movieTop = file.config!.movieTop;
    movieRight = file.config!.movieRight;
    movieBottom = file.config!.movieBottom;

    await castManager.initFromFile(file, netManager);
    score.loadFromFile(file);
  }

  @override
  Ref<Datum>? getPropRef(String propName) {
    switch(propName) {
      case "frame":
        return CallbackRef(get: () => Datum.ofInt(currentFrame));
      case "runMode":
        return CallbackRef(get: () => Datum.ofString("Plugin")); // Plugin / Author
      case "date":
        // TODO localize formatting
        var formatter = DateFormat("M/d/yyyy");
        var result = formatter.format(DateTime.now());
        return CallbackRef(get: () => Datum.ofString(result));
      case "lastChannel":
        return CallbackRef(
          get: () => Datum.ofInt(score.channelCount)
        );
      case "long time":
        var formatter = DateFormat("h:mm:ss a");
        var result = formatter.format(DateTime.now());
        return CallbackRef(get: () => Datum.ofString(result));
      case "moviePath":
        var result = file?.basePath.toString() ?? "";
        if (result.isNotEmpty && !result.endsWith(getPathSeparator())) {
          result += getPathSeparator();
        }
        return CallbackRef(get: () => Datum.ofString(result));
      case "platform":
        return CallbackRef(get: () => Datum.ofString("Windows,32"));
      case "exitLock":
        return MutableCallbackRef(
          get: () => Datum.ofInt(exitLock),
          set: (value) => exitLock = value.toInt()
        );
      default:
        return null;
    }
  }
}

