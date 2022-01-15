part of typr_dart;

// OpenType Layout Common Table Formats

class Typr_LCTF {
  static Map<String, dynamic> parse(data, offset, length, font, subt) {
    Map<String, dynamic> obj = {};
    var offset0 = offset;
    var tableVersion = TyprBin.readFixed(data, offset);
    offset += 4;

    var offScriptList = TyprBin.readUshort(data, offset);
    offset += 2;
    var offFeatureList = TyprBin.readUshort(data, offset);
    offset += 2;
    var offLookupList = TyprBin.readUshort(data, offset);
    offset += 2;

    obj["scriptList"] = readScriptList(data, offset0 + offScriptList);
    obj["featureList"] = readFeatureList(data, offset0 + offFeatureList);
    obj["lookupList"] = readLookupList(data, offset0 + offLookupList, subt);

    return obj;
  }

  static readLookupList(data, offset, subt) {
    var offset0 = offset;
    var obj = [];
    var count = TyprBin.readUshort(data, offset);
    offset += 2;
    for (var i = 0; i < count; i++) {
      var noff = TyprBin.readUshort(data, offset);
      offset += 2;
      var lut = readLookupTable(data, offset0 + noff, subt);
      obj.add(lut);
    }
    return obj;
  }

  static Map<String, dynamic> readLookupTable(data, offset, subt) {
    //console.warn("Parsing lookup table", offset);

    var offset0 = offset;
    Map<String, dynamic> obj = {"tabs": []};

    obj["ltype"] = TyprBin.readUshort(data, offset);
    offset += 2;
    obj["flag"] = TyprBin.readUshort(data, offset);
    offset += 2;
    var cnt = TyprBin.readUshort(data, offset);
    offset += 2;

    var ltype = obj["ltype"]; // extension substitution can change this value
    for (var i = 0; i < cnt; i++) {
      var noff = TyprBin.readUshort(data, offset);
      offset += 2;
      var tab = subt(data, ltype, offset0 + noff, obj);
      //console.warn(obj.type, tab);
      obj["tabs"].add(tab);
    }
    return obj;
  }

  static numOfOnes(n) {
    var num = 0;
    for (var i = 0; i < 32; i++) if (((n >> i) & 1) != 0) num++;
    return num;
  }

  static readClassDef(data, offset) {
    var obj = [];
    var format = TyprBin.readUshort(data, offset);
    offset += 2;
    if (format == 1) {
      var startGlyph = TyprBin.readUshort(data, offset);
      offset += 2;
      var glyphCount = TyprBin.readUshort(data, offset);
      offset += 2;
      for (var i = 0; i < glyphCount; i++) {
        obj.add(startGlyph + i);
        obj.add(startGlyph + i);
        obj.add(TyprBin.readUshort(data, offset));
        offset += 2;
      }
    }
    if (format == 2) {
      var count = TyprBin.readUshort(data, offset);
      offset += 2;
      for (var i = 0; i < count; i++) {
        obj.add(TyprBin.readUshort(data, offset));
        offset += 2;
        obj.add(TyprBin.readUshort(data, offset));
        offset += 2;
        obj.add(TyprBin.readUshort(data, offset));
        offset += 2;
      }
    }
    return obj;
  }

  static getInterval(tab, val) {
    for (var i = 0; i < tab.length; i += 3) {
      var start = tab[i], end = tab[i + 1], index = tab[i + 2];
      if (start <= val && val <= end) return i;
    }
    return -1;
  }

  static Map<String, dynamic> readCoverage(data, offset) {
    Map<String, dynamic> cvg = {};
    cvg["fmt"] = TyprBin.readUshort(data, offset);
    offset += 2;
    var count = TyprBin.readUshort(data, offset);
    offset += 2;
    //console.warn("parsing coverage", offset-4, format, count);
    if (cvg["fmt"] == 1) cvg["tab"] = TyprBin.readUshorts(data, offset, count);
    if (cvg["fmt"] == 2)
      cvg["tab"] = TyprBin.readUshorts(data, offset, count * 3);
    return cvg;
  }

  static coverageIndex(Map<String, dynamic> cvg, val) {
    var tab = cvg["tab"];
    if (cvg["fmt"] == 1) return tab.indexOf(val);
    if (cvg["fmt"] == 2) {
      var ind = getInterval(tab, val);
      if (ind != -1) return tab[ind + 2] + (val - tab[ind]);
    }
    return -1;
  }

  static readFeatureList(data, offset) {
    var offset0 = offset;
    var obj = [];

    var count = TyprBin.readUshort(data, offset);
    offset += 2;

    for (var i = 0; i < count; i++) {
      var tag = TyprBin.readASCII(data, offset, 4);
      offset += 4;
      var noff = TyprBin.readUshort(data, offset);
      offset += 2;
      var feat = readFeatureTable(data, offset0 + noff);
      feat["tag"] = tag.trim();
      obj.add(feat);
    }
    return obj;
  }

  static Map<String, dynamic> readFeatureTable(data, offset) {
    var offset0 = offset;
    Map<String, dynamic> feat = {};

    var featureParams = TyprBin.readUshort(data, offset);
    offset += 2;
    if (featureParams > 0) {
      feat["featureParams"] = offset0 + featureParams;
    }

    var lookupCount = TyprBin.readUshort(data, offset);
    offset += 2;
    feat["tab"] = [];
    for (var i = 0; i < lookupCount; i++)
      feat["tab"].add(TyprBin.readUshort(data, offset + 2 * i));
    return feat;
  }

  static readScriptList(data, offset) {
    var offset0 = offset;
    var obj = {};

    var count = TyprBin.readUshort(data, offset);
    offset += 2;

    for (var i = 0; i < count; i++) {
      var tag = TyprBin.readASCII(data, offset, 4);
      offset += 4;
      var noff = TyprBin.readUshort(data, offset);
      offset += 2;
      obj[tag.trim()] = readScriptTable(data, offset0 + noff);
    }
    return obj;
  }

  static Map<String, dynamic> readScriptTable(data, offset) {
    var offset0 = offset;
    Map<String, dynamic> obj = {};

    var defLangSysOff = TyprBin.readUshort(data, offset);
    offset += 2;
    obj["default"] = readLangSysTable(data, offset0 + defLangSysOff);

    var langSysCount = TyprBin.readUshort(data, offset);
    offset += 2;

    for (var i = 0; i < langSysCount; i++) {
      var tag = TyprBin.readASCII(data, offset, 4);
      offset += 4;
      var langSysOff = TyprBin.readUshort(data, offset);
      offset += 2;
      obj[tag.trim()] = readLangSysTable(data, offset0 + langSysOff);
    }
    return obj;
  }

  static Map<String, dynamic> readLangSysTable(data, offset) {
    Map<String, dynamic> obj = {};

    var lookupOrder = TyprBin.readUshort(data, offset);
    offset += 2;
    //if(lookupOrder!=0)  throw "lookupOrder not 0";
    obj["reqFeature"] = TyprBin.readUshort(data, offset);
    offset += 2;
    //if(obj.reqFeature != 0xffff) throw "reqFeatureIndex != 0xffff";

    //console.warn(lookupOrder, obj.reqFeature);

    var featureCount = TyprBin.readUshort(data, offset);
    offset += 2;
    obj["features"] = TyprBin.readUshorts(data, offset, featureCount);
    return obj;
  }
}

class GSUBTable extends Typr_LCTF {}

class GPOSTable extends Typr_LCTF {}
