import 'dart:ui';

import 'package:dirplayer/director/lingo/datum.dart';
import 'package:dirplayer/director/lingo/datum/list.dart';
import 'package:dirplayer/director/lingo/datum/var_ref.dart';
import 'package:dirplayer/player/runtime/cast_member.dart';
import 'package:dirplayer/player/runtime/color_ref.dart';
import 'package:dirplayer/player/runtime/data_reference.dart';
import 'package:dirplayer/player/runtime/prop_interface.dart';
import 'package:dirplayer/player/runtime/rect.dart';
import 'package:dirplayer/player/runtime/score.dart';
import 'package:dirplayer/player/runtime/script.dart';
import 'package:dirplayer/player/runtime/vm.dart';

class SpriteChannel {
  final int number;
  String name = "";
  bool scripted = false;
  Sprite sprite;

  SpriteChannel(this.number) : sprite = Sprite(number);
}

abstract class CursorRef {
  Datum toDatum();
}

class SystemCursorRef extends CursorRef {
  int cursorId;
  SystemCursorRef(this.cursorId);

  @override
  Datum toDatum() {
    return Datum.ofInt(cursorId);
  }
}
class MemberCursorRef extends CursorRef {
  List<int> members;
  MemberCursorRef(this.members);

  @override
  Datum toDatum() {
    return ListDatum(members.map((e) => Datum.ofInt(e)).toList());
  }
}

// locH and locV are anchored to regPoint
class Sprite extends VMPropInterface implements HandlerInterface {
  int number;
  String name = "";
  bool puppet = false;
  bool visible = false;
  int stretch = 0;
  int locH = 0;
  int locV = 0;
  int locZ;
  int width = 0;
  int height = 0;
  int ink = 0;
  int blend = 100;
  double rotation = 0;
  double skew = 0;
  bool flipH = false;
  bool flipV = false;
  int backColor = 0;
  ColorRef color = ColorRef.fromRgb(0, 0, 0);
  ColorRef bgColor = ColorRef.fromRgb(0, 0, 0);
  CastMemberReference? member;
  List<ScriptInstance> scriptInstanceList = [];
  CursorRef? cursorRef;

  Sprite(this.number) : locZ = number;

  Member? getMember(PlayerVM vm) {
    var memberRef = member;
    return memberRef != null ? vm.movie.castManager.findMemberByRef(memberRef) : null;
  }

  IntRect getRect(PlayerVM vm) {
    Member? member = getMember(vm);
    IntPoint regPoint = getRegPoint(vm);
    int width = 0, height = 0;

    if (member is BitmapMember) {
      width = member.imageRef.image.width;
      height = member.imageRef.image.height;
    } else if (member is TextMember) {
      width = member.width;
      height = member.height;
    } else if (member is FieldMember) {
      width = member.width;
      height = member.height;
    }

    var left = locH - regPoint.locH;
    var top = locV - regPoint.locV;
    return IntRect(left, top, left + width, top + height);
  }

  IntPoint getRegPoint(PlayerVM vm) {
    Member? member = getMember(vm);
    if (member is BitmapMember) {
      return member.regPoint;
    } else {
      return IntPoint(0, 0);
    }
  }

  void setRect(IntRect rect, PlayerVM vm) {
    IntPoint regPoint = getRegPoint(vm);
    locH = rect.left + regPoint.locH;
    locV = rect.top + regPoint.locV;
    width = rect.right - rect.left;
    height = rect.bottom - rect.top;
  }

  @override
  Ref<Datum>? getVMPropRef(String propName, PlayerVM vm) {
    switch (propName) {
    case "visible":
      return MutableCallbackRef(
        get: () => Datum.ofBool(visible), 
        set: (value) => visible = value.toBool(),
      );
    case "stretch":
      return MutableCallbackRef(
        get: () => Datum.ofInt(stretch), 
        set: (value) => stretch = value.toInt(),
      );
    case "locH":
      return MutableCallbackRef(
        get: () => Datum.ofInt(locH), 
        set: (value) => locH = value.toInt(),
      );
    case "locV":
      return MutableCallbackRef(
        get: () => Datum.ofInt(locV), 
        set: (value) => locV = value.toInt(),
      );
    case "width":
      return MutableCallbackRef(
        get: () => Datum.ofInt(width), 
        set: (value) => width = value.toInt(),
      );
    case "height":
      return MutableCallbackRef(
        get: () => Datum.ofInt(height), 
        set: (value) => height = value.toInt(),
      );
    case "ink":
      return MutableCallbackRef(
        get: () => Datum.ofInt(ink), 
        set: (value) => ink = value.toInt(),
      );
    case "blend":
      return MutableCallbackRef(
        get: () => Datum.ofInt(blend), 
        set: (value) => blend = value.toInt(),
      );
    case "color":
      return MutableCallbackRef(
        get: () => Datum.ofVarRef(color), 
        set: (value) => color = value.toRef(),
      );
    case "bgColor":
      return MutableCallbackRef(
        get: () => Datum.ofVarRef(bgColor), 
        set: (value) => bgColor = value.toRef(),
      );
    case "member":
      return MutableCallbackRef(
        get: () => Datum.ofVarRef(member), 
        set: (value) {
          if (value is VarRefDatum && value.value is CastMemberReference) {
            member = value.toRef();
          } else if (value.isString()) {
            member = vm.movie.castManager.findMemberByName(value.stringValue())?.reference;
          } else {
            member = null;
          }
        }
      );
    case "locZ":
      return MutableCallbackRef(
        get: () => Datum.ofInt(locZ), 
        set: (value) {
          if (value.isInt()) {
            locZ = value.toInt();
          } else {
            locZ = 0;
          }
        }
      );
    case "backColor":
      return MutableCallbackRef(
        get: () => Datum.ofInt(backColor), 
        set: (value) {
          if (value.isInt()) {
            backColor = value.toInt();
          } else {
            backColor = 0;
          }
        }
      );
    case "rotation":
      return MutableCallbackRef(
        get: () => Datum.ofFloat(rotation), 
        set: (value) {
          if (value.isNumber()) {
            rotation = value.toFloat();
          } else {
            rotation = 0;
          }
        }
      );
    case "skew":
      return MutableCallbackRef(
        get: () => Datum.ofFloat(skew), 
        set: (value) {
          if (value.isNumber()) {
            skew = value.toFloat();
          } else {
            skew = 0;
          }
        }
      );
    case "flipH":
      return MutableCallbackRef(
        get: () => Datum.ofBool(flipH), 
        set: (value) {
          if (value.isNumber()) {
            flipH = value.toBool();
          } else {
            flipH = false;
          }
        }
      );
    case "flipV":
      return MutableCallbackRef(
        get: () => Datum.ofBool(flipV), 
        set: (value) {
          if (value.isNumber()) {
            flipV = value.toBool();
          } else {
            flipV = false;
          }
        }
      );
    case "rect":
      return MutableCallbackRef(
        get: () => Datum.ofVarRef(getRect(vm)),
        set: (value) {
          setRect(value.toRef(), vm);
        }
      );
    case "left":
      return MutableCallbackRef(
        get: () => Datum.ofInt(getRect(vm).left),
        set: (value) {
          var rect = getRect(vm);
          var newRect = IntRect(value.toInt(), rect.top, rect.right, rect.bottom);
          setRect(newRect, vm);
        }
      );
    case "top":
      return MutableCallbackRef(
        get: () => Datum.ofInt(getRect(vm).top),
        set: (value) {
          var rect = getRect(vm);
          var newRect = IntRect(rect.left, value.toInt(), rect.right, rect.bottom);
          setRect(newRect, vm);
        }
      );
    case "right":
      return MutableCallbackRef(
        get: () => Datum.ofInt(getRect(vm).right),
        set: (value) {
          var rect = getRect(vm);
          var newRect = IntRect(rect.left, rect.left, value.toInt(), rect.bottom);
          setRect(newRect, vm);
        }
      );
    case "bottom":
      return MutableCallbackRef(
        get: () => Datum.ofInt(getRect(vm).bottom),
        set: (value) {
          var rect = getRect(vm);
          var newRect = IntRect(rect.left, rect.left, rect.right, value.toInt());
          setRect(newRect, vm);
        }
      );
    case "loc":
      return MutableCallbackRef(
        get: () => Datum.ofVarRef(IntPoint(locH, locV)),
        set: (value) { 
          var point = value.toRef<IntPoint>();
          locH = point.locH; 
          locV = point.locV;
        } 
      );
    case "ilk":
      return CallbackRef(
        get: () => Datum.ofSymbol("sprite"), 
      );
    case "spriteNum":
      return CallbackRef(
        get: () => Datum.ofInt(number), 
      );
    case "scriptInstanceList":
      return MutableCallbackRef(
        get: () => Datum.ofDatumList(DatumType.kDatumList, scriptInstanceList.map((e) => Datum.ofVarRef(e)).toList()),
        set: (value) { 
          scriptInstanceList = value.toList().map((e) => e.toRef<ScriptInstance>()).toList();
          for (var script in scriptInstanceList) {
            if (!script.hasProperty("spriteNum")) {
              script.setProp("spriteNum", Datum.ofInt(number));
            }
          }
        } 
      );
    case "castNum":
      return MutableCallbackRef(
        get: () => Datum.ofInt(member?.castMember ?? 0),
        set: (value) { 
          var newMemberRef = member;
          if (newMemberRef != null) {
            newMemberRef.castMember = value.toInt();
          } else {
            newMemberRef = CastMemberReference(0, value.toInt());
          }
          member = newMemberRef;
        } 
      );
    case "cursor":
      return MutableCallbackRef(
        get: () => cursorRef?.toDatum() ?? Datum.ofInt(-1),
        set: (value) { 
          if (value.isInt()) {
            cursorRef = SystemCursorRef(value.toInt());
          } else if (value.isList()) {
            cursorRef = MemberCursorRef(value.toList().map((e) => e.toInt()).toList());
          } else {
            throw Exception("Invalid value for cursor $value");
          }
        } 
      );
    default:
      return null;
    }
  }

  @override
  Future<Datum> callHandler(PlayerVM vm, String handlerName, List<Datum> argList) async {
    for (var script in scriptInstanceList) {
      if (script.getHandler(handlerName) != null) {
        return await script.callHandler(vm, handlerName, argList);
      }
    }
    throw Exception("Unknown handler $handlerName for $this");
  }
}
