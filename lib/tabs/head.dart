part of typr_dart;

class Typr_HEAD {
  
  static Map<String, dynamic> parse(data, offset, length) {
    Map<String, dynamic> obj = {};
    var tableVersion = TyprBin.readFixed(data, offset);  offset += 4;
    obj["fontRevision"] = TyprBin.readFixed(data, offset);  offset += 4;
    var checkSumAdjustment = TyprBin.readUint(data, offset);  offset += 4;
    var magicNumber = TyprBin.readUint(data, offset);  offset += 4;
    obj["flags"] = TyprBin.readUshort(data, offset);  offset += 2;
    obj["unitsPerEm"] = TyprBin.readUshort(data, offset);  offset += 2;
    obj["created"]  = TyprBin.readUint64(data, offset);  offset += 8;
    obj["modified"] = TyprBin.readUint64(data, offset);  offset += 8;
    obj["xMin"] = TyprBin.readShort(data, offset);  offset += 2;
    obj["yMin"] = TyprBin.readShort(data, offset);  offset += 2;
    obj["xMax"] = TyprBin.readShort(data, offset);  offset += 2;
    obj["yMax"] = TyprBin.readShort(data, offset);  offset += 2;
    obj["macStyle"] = TyprBin.readUshort(data, offset);  offset += 2;
    obj["lowestRecPPEM"] = TyprBin.readUshort(data, offset);  offset += 2;
    obj["fontDirectionHint"] = TyprBin.readShort(data, offset);  offset += 2;
    obj["indexToLocFormat"]  = TyprBin.readShort(data, offset);  offset += 2;
    obj["glyphDataFormat"]   = TyprBin.readShort(data, offset);  offset += 2;
    return obj;
  }

}

