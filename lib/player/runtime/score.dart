import 'dart:math';

import 'package:dirplayer/director/file.dart';
import 'package:dirplayer/director/lingo/datum.dart';
import 'package:dirplayer/player/runtime/cast_manager.dart';
import 'package:dirplayer/player/runtime/cast_member.dart';
import 'package:dirplayer/player/runtime/data_reference.dart';
import 'package:dirplayer/player/runtime/sprite.dart';
import 'package:equatable/equatable.dart';

import 'prop_interface.dart';
import 'vm.dart';

class CastMemberReference with EquatableMixin implements VMPropInterface, HandlerInterface {
  int castLib;
  int castMember;

  CastMemberReference(this.castLib, this.castMember);
  
  @override
  List<Object?> get props => [castLib, castMember];

  @override
  String toString() {
    return "(member ref $castMember of castLib $castLib)";
  }

  @override
  Ref<Datum>? getVMPropRef(String propName, PlayerVM vm) {
    var member = vm.movie.castManager.findMemberByRef(this);// ?? InvalidMember();
    Ref<Datum>? propRef;
    if (member is VMPropInterface) {
      propRef = (member as VMPropInterface).getVMPropRef(propName, vm);
      if (propRef != null) {
        return propRef;
      }
    }
    return member?.getPropRef(propName);
  }

  @override
  Future<Datum> callHandler(PlayerVM vm, String handlerName, List<Datum> argList) async {
    switch (handlerName) {
    case "erase":
      vm.movie.castManager.removeMemberWithRef(this);
      return Datum.ofVoid();
    case "duplicate":
      var member = vm.movie.castManager.findMemberByRef(this);
      int newNumber = -1;
      if (member != null) {
        var newNumber = member.cast.firstFreeMemberNumber;
        var newMember = member.duplicate(newNumber);
        member.restoreFrom(newMember);
        member.cast.insertMemberAt(newNumber, newMember);
      }
      return Datum.ofInt(newNumber);
    default:
      var member = vm.movie.castManager.findMemberByRef(this);
      if (member != null && member is HandlerInterface) {
        return (member as HandlerInterface).callHandler(vm, handlerName, argList);
      } else {
        throw Exception("Unknown handler $handlerName for $this");
      }
    }
  }
}

class ScoreFrameScriptReference {
  int startFrame;
  int endFrame;
  int castLib;
  int castMember;

  ScoreFrameScriptReference({ required this.startFrame, required this.endFrame, required this.castLib, required this.castMember });
}

class Score {
  List<SpriteChannel> channels = List.generate(10, (index) => SpriteChannel(index + 1)); // TODO: should this be a map instead?
  List<ScoreFrameScriptReference> scriptReferences = [];

  ScoreFrameScriptReference? getScriptInFrame(int frame) {
    return scriptReferences
      .where((element) => frame >= element.startFrame && frame <= element.endFrame)
      .firstOrNull;
  }

  int get channelCount => channels.length;
  void setChannelCount(int newCount) {
    if (newCount > channels.length) {
      var baseNumber = channels.length + 1;
      var addCount = max(0, newCount - channels.length);
      channels.addAll(List.generate(addCount, (index) => SpriteChannel(baseNumber + index)));
    } else if (newCount < channels.length) {
      var removeCount = channels.length - newCount;
      channels.removeRange(channels.length - removeCount, channels.length);
    }
  }

  Sprite getSprite(int number) {
    var channel = channels[number - 1];
    return channel.sprite;
  }

  void loadFromFile(DirectorFile dir) {
    var scoreChunk = dir.getScoreChunk()!;
    setChannelCount(scoreChunk.frameData!.numChannels);

    for (var i = 0; i < scoreChunk.frameIntervalPrimaries.length; i++) {
      var primary = scoreChunk.frameIntervalPrimaries[i];
      var secondary = scoreChunk.frameIntervalSecondaries[i];

      scriptReferences.add(
        ScoreFrameScriptReference(
          startFrame: primary.startFrame, 
          endFrame: primary.endFrame, 
          castLib: secondary.castLib, 
          castMember: secondary.castMember,
        )
      );
    }
  }
}
