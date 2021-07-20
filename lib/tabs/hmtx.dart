part of typr_dart;

class Typr_HMTX {
    
  static Map<String, dynamic> parse(data, offset, length, font)
  {

    Map<String, dynamic> obj = {};
    
    obj["aWidth"] = [];
    obj["lsBearing"] = [];
    
    
    var aw = 0, lsb = 0;
    
    for(var i=0; i<font["maxp"]["numGlyphs"]; i++)
    {
      if(i<font["hhea"]["numberOfHMetrics"]) {  aw=TyprBin.readUshort(data, offset);  offset += 2;  lsb=TyprBin.readShort(data, offset);  offset+=2;  }
      obj["aWidth"].add(aw);
      obj["lsBearing"].add(lsb);
    }
    
    return obj;
  }

}

