import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:typr_dart/typr_dart.dart';

void main() {
  test('adds one to input values', () async {
    Uint8List data = await loadFile();
    print(" data.... ${data.length} ");

    int t1 = DateTime.now().millisecondsSinceEpoch;

    var font = Typr.parse(data);

    int t2 = DateTime.now().millisecondsSinceEpoch;

    print(" parse buffer cost ${t2 - t1} ");

    print(font.runtimeType);
    print("font.length : ${font.length}");
    // print(font.tables);
    // print(font.glyphs.glyphs);

    var _f = font[0];

    print(_f.keys);
  });
}

loadFile() async {
  String filePath = "ttf/pingfang.ttf";
  final _result = await File(filePath).readAsBytes();
  return _result;
}
