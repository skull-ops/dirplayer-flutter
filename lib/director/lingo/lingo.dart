import '../../common/util.dart';
import 'constants.dart';
import 'opcode.dart';

class Lingo {
  static String getOpcodeName(int id) {
    if (id >= 0x40) {
      id = 0x40 + id % 0x40;
    }
    var it = opcodeNames[OpCode.fromValue(id)];
    if (it == null) {
      return "unk${byteToString(id)}";
    }
    return it;
  }

  static String getName<K>(Map<K, String> nameMap, K id) {
    var it = nameMap[id];
    if (it == null) {
      return "ERROR";
    }
    return it;
  }
}
