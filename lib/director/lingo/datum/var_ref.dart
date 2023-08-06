
import 'package:dirplayer/common/exceptions.dart';
import 'package:dirplayer/player/runtime/cast_member.dart';
import 'package:dirplayer/player/runtime/data_reference.dart';
import 'package:dirplayer/player/runtime/prop_interface.dart';
import 'package:dirplayer/player/runtime/score.dart';
import 'package:dirplayer/player/runtime/sprite.dart';
import 'package:dirplayer/player/runtime/vm.dart';

import '../../../common/codewriter.dart';
import '../../../player/runtime/script.dart';
import '../datum.dart';

class VarRefDatum extends Datum implements HandlerInterface, VMPropInterface, PropInterface {
  dynamic value;
  @override final type = DatumType.kDatumVarRef;

  VarRefDatum(this.value);
  
  @override
  T toRef<T>() => value as T;

  //@override
  //String ilk() => "void";

  @override
  bool isIlk(String ilk) {
    var possibleIlks = [
      "object",
      if (toRef() is Script) "script",
      if (toRef() is ScriptInstance) "instance",
      if (toRef() is Member || toRef() is CastMemberReference) "member",
      if (toRef() is Sprite) "sprite",
    ];
    return possibleIlks.contains(ilk); 
  }

  @override
  String toDebugString() => value.toString();

  @override 
  void writeScriptText(CodeWriter code, bool dot, bool sum) {
    code.write(toDebugString());
  }

  @override
  Future<Datum> callHandler(PlayerVM vm, String handlerName, List<Datum> argList) async {
    var value = this.value;
    if (value is HandlerInterface) {
      return await value.callHandler(vm, handlerName, argList);
    } else {
      return Future.error(UnknownHandlerException(handlerName, argList, value));
    }
  }

  @override
  Ref<Datum>? getVMPropRef(String propName, PlayerVM vm) {
    if (value is VMPropInterface) {
      return (value as VMPropInterface).getVMPropRef(propName, vm);
    } else {
      return null;
    }
  }

  @override
  Ref<Datum>? getPropRef(String propName) {
    if (value is PropInterface) {
      return (value as PropInterface).getPropRef(propName);
    } else {
      return null;
    }
  }
}
