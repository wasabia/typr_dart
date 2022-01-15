part of typr_dart;

class TyprBin {
  static readFixed(data, o) {
    return ((data[o] << 8) | data[o + 1]) +
        (((data[o + 2] << 8) | data[o + 3]) / (256 * 256 + 4));
  }

  static readF2dot14(data, o) {
    var num = readShort(data, o);
    return num / 16384;
  }

  static readInt(buff, p) {
    //if(p>=buff.length) throw "error";
    var a = BinT.uint8;
    a[0] = buff[p + 3];
    a[1] = buff[p + 2];
    a[2] = buff[p + 1];
    a[3] = buff[p];
    return BinT.int32[0];
  }

  static readInt8(buff, p) {
    //if(p>=buff.length) throw "error";
    var a = BinT.uint8;
    a[0] = buff[p];
    return BinT.int8[0];
  }

  static readShort(buff, p) {
    //if(p>=buff.length) throw "error";
    var a = BinT.uint8;
    a[1] = buff[p];
    a[0] = buff[p + 1];
    return BinT.int16[0];
  }

  static readUshort(buff, int p) {
    //if(p>=buff.length) throw "error";
    return (buff[p] << 8) | buff[p + 1];
  }

  static readUshorts(buff, p, len) {
    var arr = [];
    for (var i = 0; i < len; i++) arr.add(readUshort(buff, p + i * 2));
    return arr;
  }

  static readUint(buff, p) {
    //if(p>=buff.length) throw "error";
    var a = BinT.uint8;
    a[3] = buff[p];
    a[2] = buff[p + 1];
    a[1] = buff[p + 2];
    a[0] = buff[p + 3];
    return BinT.uint32[0];
  }

  static readUint64(buff, p) {
    //if(p>=buff.length) throw "error";
    return (readUint(buff, p) * (0xffffffff + 1)) + readUint(buff, p + 4);
  }

  static readASCII(buff, p, l) // l : length in Characters (not Bytes)
  {
    //if(p>=buff.length) throw "error";
    var s = "";
    for (var i = 0; i < l; i++) s += String.fromCharCode(buff[p + i]);
    return s;
  }

  static readUnicode(buff, p, l) {
    //if(p>=buff.length) throw "error";
    var s = "";
    for (var i = 0; i < l; i++) {
      var c = (buff[p++] << 8) | buff[p++];
      s += String.fromCharCode(c);
    }
    return s;
  }

  static readUTF8(buff, p, l) {
    // var tdec = null;
    // if(tdec != null && p==0 && l==buff.length) return tdec["decode"](buff);
    return readASCII(buff, p, l);
  }

  static readBytes(buff, p, l) {
    //if(p>=buff.length) throw "error";
    var arr = [];
    for (var i = 0; i < l; i++) arr.add(buff[p + i]);
    return arr;
  }

  static readASCIIArray(buff, p, l) // l : length in Characters (not Bytes)
  {
    //if(p>=buff.length) throw "error";
    var s = [];
    for (var i = 0; i < l; i++) s.add(String.fromCharCode(buff[p + i]));
    return s;
  }
}

class BinT {
  static ByteData buff = ByteData(8);

  static Int8List int8 = Int8List.view(buff.buffer);
  static Uint8List uint8 = Uint8List.view(buff.buffer);
  static Int16List int16 = Int16List.view(buff.buffer);
  static Uint16List uint16 = Uint16List.view(buff.buffer);
  static Int32List int32 = Int32List.view(buff.buffer);
  static Uint32List uint32 = Uint32List.view(buff.buffer);
}
