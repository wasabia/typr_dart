part of typr_dart;

class Typr {
  static parse(Uint8List buff) {
    var data = buff;

    var tag = TyprBin.readASCII(data, 0, 4);
    if (tag == "ttcf") {
      var offset = 4;
      var majV = TyprBin.readUshort(data, offset);
      offset += 2;
      var minV = TyprBin.readUshort(data, offset);
      offset += 2;
      var numF = TyprBin.readUint(data, offset);
      offset += 4;
      var fnts = [];
      for (var i = 0; i < numF; i++) {
        var foff = TyprBin.readUint(data, offset);
        offset += 4;
        fnts.add(Typr._readFont(data, foff));
      }
      return fnts;
    } else {
      return [Typr._readFont(data, 0)];
    }
  }

  static _readFont(data, offset) {
    var ooff = offset;

    var sfnt_version = TyprBin.readFixed(data, offset);
    offset += 4;
    var numTables = TyprBin.readUshort(data, offset);
    offset += 2;
    var searchRange = TyprBin.readUshort(data, offset);
    offset += 2;
    var entrySelector = TyprBin.readUshort(data, offset);
    offset += 2;
    var rangeShift = TyprBin.readUshort(data, offset);
    offset += 2;

    var tags = [
      "cmap",
      "head",
      "hhea",
      "maxp",
      "hmtx",
      "name",
      "OS/2",
      "post",

      //"cvt",
      //"fpgm",
      "loca",
      "glyf",
      "kern",

      //"prep"
      //"gasp"

      "CFF ",

      "GPOS",
      "GSUB",

      "SVG "
      //"VORG",
    ];

    var obj = {"_data": data, "_offset": ooff};
    //console.warn(sfnt_version, numTables, searchRange, entrySelector, rangeShift);

    var tabs = {};

    for (var i = 0; i < numTables; i++) {
      var tag = TyprBin.readASCII(data, offset, 4);
      offset += 4;
      var checkSum = TyprBin.readUint(data, offset);
      offset += 4;
      var toffset = TyprBin.readUint(data, offset);
      offset += 4;
      var length = TyprBin.readUint(data, offset);
      offset += 4;
      tabs[tag] = {"offset": toffset, "length": length};

      //if(tags.indexOf(tag)==-1) console.warn("unknown tag", tag, length);
    }

    for (var i = 0; i < tags.length; i++) {
      var t = tags[i];
      //console.warn(t);
      //if(tabs[t]) console.warn(t, tabs[t].offset, tabs[t].length);
      if (tabs[t] != null) {
        String _t = t.trim();

        // obj[_t] = Typr[t.trim()].parse(data, tabs[t].offset, tabs[t].length, obj);
        obj[_t] =
            whichParse(_t, data, tabs[t]["offset"], tabs[t]["length"], obj);
      }
    }

    return obj;
  }

  static whichParse(String tag, data, offset, length, obj) {
    if (tag == "cmap") {
      return Typr_CMAP.parse(data, offset, length);
    } else if (tag == "head") {
      return Typr_HEAD.parse(data, offset, length);
    } else if (tag == "hhea") {
      return Typr_HHEA.parse(data, offset, length);
    } else if (tag == "maxp") {
      return Typr_MAXP.parse(data, offset, length);
    } else if (tag == "hmtx") {
      return Typr_HMTX.parse(data, offset, length, obj);
    } else if (tag == "name") {
      return Typr_NAME.parse(data, offset, length);
    } else if (tag == "OS/2") {
      return Typr_OS2.parse(data, offset, length);
    } else if (tag == "post") {
      return Typr_POST.parse(data, offset, length);
    } else if (tag == "loca") {
      return Typr_LOCA.parse(data, offset, length, obj);
    } else if (tag == "glyf") {
      return Typr_GLYF.parse(data, offset, length, obj);
    } else if (tag == "kern") {
      return Typr_KERN.parse(data, offset, length, obj);
    } else if (tag == "CFF") {
      return Typr_CFF.parse(data, offset, length);
    } else if (tag == "GPOS") {
      return Typr_GPOS.parse(data, offset, length, obj);
    } else if (tag == "GSUB") {
      return Typr_GSUB.parse(data, offset, length, obj);
    } else if (tag == "SVG") {
      return Typr_SVG.parse(data, offset, length);
    } else {
      throw ("whichParse tag is not support ${tag} ");
    }
  }

  static _tabOffset(data, tab, foff) {
    var numTables = TyprBin.readUshort(data, foff + 4);
    var offset = foff + 12;
    for (var i = 0; i < numTables; i++) {
      var tag = TyprBin.readASCII(data, offset, 4);
      offset += 4;
      var checkSum = TyprBin.readUint(data, offset);
      offset += 4;
      var toffset = TyprBin.readUint(data, offset);
      offset += 4;
      var length = TyprBin.readUint(data, offset);
      offset += 4;
      if (tag == tab) return toffset;
    }
    return 0;
  }
}
