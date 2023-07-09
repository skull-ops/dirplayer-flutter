import 'dart:typed_data';

import 'package:dirplayer/reader.dart';
import 'package:equatable/equatable.dart';

class MoaID with EquatableMixin {
  int data1;
  int data2;
  int data3;
  List<int> data4;
  
  MoaID(this.data1, this.data2, this.data3, this.data4); // 8 bytes

  static MoaID fromReader(Reader reader) {
    var data1 = reader.readUint32();
    var data2 = reader.readUint16();
    var data3 = reader.readUint16();

    return MoaID(data1, data2, data3, reader.readByteList(8));
  }

  @override
  String toString() {
    return "${data1.toRadixString(16)}-${data2.toRadixString(16)}-${data3.toRadixString(16)}-${data4.map((e) => e.toRadixString(16))}";
  }
  
  @override
  List<Object?> get props => [data1, data2, data3, data4];
}
