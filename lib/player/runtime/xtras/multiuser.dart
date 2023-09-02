import 'package:dirplayer/common/exceptions.dart';
import 'package:dirplayer/player/runtime/prop_interface.dart';
import 'package:dirplayer/player/runtime/vm.dart';
import 'package:dirplayer/player/runtime/xtras/interface.dart';

import '../../../director/lingo/datum.dart';

class MultiuserXtra implements XtraFactory<MultiuserXtraInstance> {
  @override
  Future<MultiuserXtraInstance> newInstance(List<Datum> args) {
    assert(args.isEmpty);
    return Future.value(MultiuserXtraInstance());
  }

  @override
  String toString() {
    return "<Xtra \"Multiuser\" _ _______>";
  }
}

class MultiuserXtraInstance implements HandlerInterface {
  @override
  String toString() {
    return "<Xtra child \"Multiuser\" _ _______>";
  }

  @override
  Future<Datum> callHandler(PlayerVM vm, String handlerName, List<Datum> argList) async {
    switch (handlerName) {
    case "setNetBufferLimits":
      var tcpipReadSize = argList[0].toInt();
      var maxMessageSize = argList[1].toInt();
      var maxIncomingUnreadMessages = argList[2].toInt();
      // TODO what to return?
      break;
    case "setNetMessageHandler":
      var handlerName = argList[0];
      var handlerReceiver = argList[1];
      // TODO return error code
      return Datum.ofInt(0);
    case "connectToNetServer":
      var userNameString = argList[0];
      var passwordString = argList[1];
      var serverIDString = argList[2];
      var portNumber = argList[3];
      var movieIDString = argList[4];
      var mode = argList.elementAtOrNull(5);
      var encryptionKey = argList.elementAtOrNull(6);
      // TODO
      break;
    case "sendNetMessage":
      // TODO
      break;
    default:
      return Future.error(UnknownHandlerException(handlerName, argList, this));
    }
    return Datum.ofVoid();
  }
}
