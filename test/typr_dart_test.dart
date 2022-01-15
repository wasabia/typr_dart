import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:typr_dart/typr_dart.dart';

class BinT {
  static ByteData buff = ByteData(8);

  static Int8List int8 = Int8List.view(buff.buffer);
  static Uint8List uint8 = Uint8List.view(buff.buffer);
  static Int16List int16 = Int16List.view(buff.buffer);
  static Uint16List uint16 = Uint16List.view(buff.buffer);
  static Int32List int32 = Int32List.view(buff.buffer);
  static Uint32List uint32 = Uint32List.view(buff.buffer);
}

void main() {
  test('adds one to input values', () {
    var a = BinT.int8;

    var b = BinT.int32;

    print("1 b: ${b[0]} ");

    a[0] = 1;
    a[1] = 3;
    a[2] = 2;
    a[3] = 1;

    print("2 b: ${b[0]} ");
  });
}
