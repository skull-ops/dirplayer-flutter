import 'dart:math';

import 'package:dirplayer/common/exceptions.dart';
import 'package:dirplayer/director/file.dart';
import 'package:dirplayer/director/lingo/datum.dart';
import 'package:dirplayer/player/runtime/cast_member.dart';
import 'package:dirplayer/player/runtime/data_reference.dart';
import 'package:dirplayer/player/runtime/sprite.dart';
import 'package:equatable/equatable.dart';

import 'prop_interface.dart';
import 'vm.dart';

CastMemberReference castSlotNumberToMemberRef(int slotNumber) {
  int castLib = slotNumber >> 16;
  int castMember = slotNumber & 0xFFFF;

  return CastMemberReference(castLib, castMember);
}

int getCastSlotNumber(int castLib, int castMember) {
  return (castLib << 16) | (castMember & 0xFFFF);
}

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
      var destSlotNumber = argList.elementAtOrNull(0)?.toInt();
      CastMemberReference? destMemberRef;
      if (destSlotNumber != null) {
        destMemberRef = castSlotNumberToMemberRef(destSlotNumber);
      } else {
        // TODO if slot number is not specified, which cast should be used?
        return Future.error(Exception("Duplicating a member without a destination number is not supported"));
      }
      var member = vm.movie.castManager.findMemberByRef(this);
      var destCast = vm.movie.castManager.getCastByNumber(destMemberRef.castLib);
      if (destCast == null) {
        return Future.error(Exception("Duplicating member into non-existent cast"));
      }
      if (member != null) {
        var newMember = destCast.addMemberAt(destMemberRef.castMember, memberTypeToSymbol(member.type));
        newMember.restoreFrom(member);
      } else {
        return Future.error("Duplicating non-existent member");
      }
      return Datum.ofInt(destSlotNumber);
    default:
      var member = vm.movie.castManager.findMemberByRef(this);
      if (member != null && member is HandlerInterface) {
        return (member as HandlerInterface).callHandler(vm, handlerName, argList);
      } else {
        return Future.error(UnknownHandlerException(handlerName, argList, this));
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

  void reset() {
    for (var channel in channels) {
      if (channel.sprite.puppet) {
        channel.sprite.reset();
      }
    }
  }
}
