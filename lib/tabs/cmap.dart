part of typr_dart;


class Typr_CMAP {

	static Map<String, dynamic> parse(Uint8List buffer, offset, length) {
		Uint8List data = buffer.sublist(offset, offset + length);
		offset = 0;

		var offset0 = offset;

		Map<String, dynamic> obj = {};
		var version   = TyprBin.readUshort(data, offset);  offset += 2;
		var numTables = TyprBin.readUshort(data, offset);  offset += 2;
		
		//console.warn(version, numTables);
		
		var offs = [];
		obj["tables"] = [];
		
		
		for(var i=0; i<numTables; i++)
		{
			var platformID = TyprBin.readUshort(data, offset);  offset += 2;
			var encodingID = TyprBin.readUshort(data, offset);  offset += 2;
			var noffset = TyprBin.readUint(data, offset);       offset += 4;
			
			var id = "p${platformID}e${encodingID}";
			
			//console.warn("cmap subtable", platformID, encodingID, noffset);
			
			
			var tind = offs.indexOf(noffset);
			
			if(tind==-1)
			{
				tind = obj["tables"].length;
				var subt;
				offs.add(noffset);
				var format = TyprBin.readUshort(data, noffset);
				if     (format== 0) subt = parse0(data, noffset);
				else if(format== 4) subt =  parse4(data, noffset);
				else if(format== 6) subt =  parse6(data, noffset);
				else if(format==12) subt =  parse12(data,noffset);
				else print("unknown format: ${format} platformID: ${platformID} encodingID: ${encodingID} noffset: ${noffset}");
				obj["tables"].add(subt);
			}
			
			if(obj[id]!=null) throw "multiple tables for one platform+encoding";
			obj[id] = tind;
		}
		return obj;
	}

  static Map<String, dynamic> parse0(data, offset)
  {

    Map<String, dynamic> obj = {};
    obj["format"] = TyprBin.readUshort(data, offset);  offset += 2;
    var len    = TyprBin.readUshort(data, offset);  offset += 2;
    var lang   = TyprBin.readUshort(data, offset);  offset += 2;
    obj["map"] = [];
    for(var i=0; i<len-6; i++) obj["map"].add(data[offset+i]);
    return obj;
  }

  static Map<String, dynamic> parse4(data, offset)
  {
    var offset0 = offset;
    Map<String, dynamic> obj = {};
    
    obj["format"] = TyprBin.readUshort(data, offset);  offset+=2;
    var length = TyprBin.readUshort(data, offset);  offset+=2;
    var language = TyprBin.readUshort(data, offset);  offset+=2;
    var segCountX2 = TyprBin.readUshort(data, offset);  offset+=2;
    var segCount = (segCountX2/2).toInt();
    obj["searchRange"] = TyprBin.readUshort(data, offset);  offset+=2;
    obj["entrySelector"] = TyprBin.readUshort(data, offset);  offset+=2;
    obj["rangeShift"] = TyprBin.readUshort(data, offset);  offset+=2;
    obj["endCount"]   = TyprBin.readUshorts(data, offset, segCount);  offset += segCount*2;
    offset+=2;
    obj["startCount"] = TyprBin.readUshorts(data, offset, segCount);  offset += segCount*2;
    obj["idDelta"] = [];
    for(var i=0; i<segCount; i++) {obj["idDelta"].add(TyprBin.readShort(data, offset));  offset+=2;}
    obj["idRangeOffset"] = TyprBin.readUshorts(data, offset, segCount);  offset += segCount*2;
    obj["glyphIdArray"] = [];
    while(offset< offset0+length) {obj["glyphIdArray"].add(TyprBin.readUshort(data, offset));  offset+=2;}
    return obj;
  }

  static Map<String, dynamic> parse6(data, offset) {
  
    var offset0 = offset;
    Map<String, dynamic> obj = {};
    
    obj["format"] = TyprBin.readUshort(data, offset);  offset+=2;
    var length = TyprBin.readUshort(data, offset);  offset+=2;
    var language = TyprBin.readUshort(data, offset);  offset+=2;
    obj["firstCode"] = TyprBin.readUshort(data, offset);  offset+=2;
    var entryCount = TyprBin.readUshort(data, offset);  offset+=2;
    obj["glyphIdArray"] = [];
    for(var i=0; i<entryCount; i++) {obj["glyphIdArray"].add(TyprBin.readUshort(data, offset));  offset+=2;}
    
    return obj;
  }

  static Map<String, dynamic> parse12(data, offset) {
    var offset0 = offset;
    Map<String, dynamic> obj = {};
    
    obj["format"] = TyprBin.readUshort(data, offset);  offset+=2;
    offset += 2;
    var length = TyprBin.readUint(data, offset);  offset+=4;
    var lang   = TyprBin.readUint(data, offset);  offset+=4;
    var nGroups= TyprBin.readUint(data, offset);  offset+=4;
    obj["groups"] = [];
    
    for(var i=0; i<nGroups; i++)  
    {
      var off = offset + i * 12;
      var startCharCode = TyprBin.readUint(data, off+0);
      var endCharCode   = TyprBin.readUint(data, off+4);
      var startGlyphID  = TyprBin.readUint(data, off+8);
      obj["groups"].add([  startCharCode, endCharCode, startGlyphID  ]);
    }
    return obj;
  }


}
