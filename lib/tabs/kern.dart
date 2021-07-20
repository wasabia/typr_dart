part of typr_dart;

class Typr_KERN {

    
  static parse(data, offset, length, font)
  {
    var version = TyprBin.readUshort(data, offset);  offset+=2;
    if(version==1) return parseV1(data, offset-2, length, font);
    var nTables = TyprBin.readUshort(data, offset);  offset+=2;
    
    var map = {"glyph1": [], "rval":[]};
    for(var i=0; i<nTables; i++)
    {
      offset+=2;	// skip version
      var length  = TyprBin.readUshort(data, offset);  offset+=2;
      int coverage = TyprBin.readUshort(data, offset);  offset+=2;
      var format = coverage >> 8;
      /* I have seen format 128 once, that's why I do */ format &= 0xf;
      if(format==0) offset = readFormat0(data, offset, map);
      else throw "unknown kern table format: ${format}";
    }
    return map;
  }

  static parseV1(data, offset, length, font)
  {

    var version = TyprBin.readFixed(data, offset);  offset+=4;
    var nTables = TyprBin.readUint(data, offset);  offset+=4;
    
    var map = {"glyph1": [], "rval":[]};
    for(var i=0; i<nTables; i++)
    {
      var length = TyprBin.readUint(data, offset);   offset+=4;
      var coverage = TyprBin.readUshort(data, offset);  offset+=2;
      var tupleIndex = TyprBin.readUshort(data, offset);  offset+=2;
      var format = coverage>>8;
      /* I have seen format 128 once, that's why I do */ format &= 0xf;
      if(format==0) offset = readFormat0(data, offset, map);
      else throw "unknown kern table format: "+format;
    }
    return map;
  }

  static readFormat0(data, offset, map)
  {
    
    var pleft = -1;
    var nPairs        = TyprBin.readUshort(data, offset);  offset+=2;
    var searchRange   = TyprBin.readUshort(data, offset);  offset+=2;
    var entrySelector = TyprBin.readUshort(data, offset);  offset+=2;
    var rangeShift    = TyprBin.readUshort(data, offset);  offset+=2;
    for(var j=0; j<nPairs; j++)
    {
      var left  = TyprBin.readUshort(data, offset);  offset+=2;
      var right = TyprBin.readUshort(data, offset);  offset+=2;
      var value = TyprBin.readShort (data, offset);  offset+=2;
      if(left!=pleft) { 
        map.glyph1.add(left);  
        map.rval.add({ "glyph2":[], "vals":[] });
      }
      var rval = map.rval[map.rval.length-1];
      rval.glyph2.push(right);   rval.vals.push(value);
      pleft = left;
    }
    return offset;
  }

}


