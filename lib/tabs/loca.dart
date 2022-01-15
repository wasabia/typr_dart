part of typr_dart;

class Typr_LOCA {
  static parse(data, offset, length, font) {
    var obj = [];

    var ver = font["head"]["indexToLocFormat"];
    //console.warn("loca", ver, length, 4*font.maxp.numGlyphs);
    var len = font["maxp"]["numGlyphs"] + 1;

    if (ver == 0)
      for (var i = 0; i < len; i++)
        obj.add(TyprBin.readUshort(data, offset + (i << 1)) << 1);
    if (ver == 1)
      for (var i = 0; i < len; i++)
        obj.add(TyprBin.readUint(data, offset + (i << 2)));

    return obj;
  }
}
