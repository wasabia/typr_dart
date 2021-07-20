part of typr_dart;


class Typr_NAME {

    
  static parse(data, offset, length)
  {

    Map<String, dynamic> obj = {};
    var format = TyprBin.readUshort(data, offset);  offset += 2;
    var count  = TyprBin.readUshort(data, offset);  offset += 2;
    var stringOffset = TyprBin.readUshort(data, offset);  offset += 2;
    
    //console.warn(format,count);
    
    var names = [
      "copyright",
      "fontFamily",
      "fontSubfamily",
      "ID",
      "fullName",
      "version",
      "postScriptName",
      "trademark",
      "manufacturer",
      "designer",
      "description",
      "urlVendor",
      "urlDesigner",
      "licence",
      "licenceURL",
      "---",
      "typoFamilyName",
      "typoSubfamilyName",
      "compatibleFull",
      "sampleText",
      "postScriptCID",
      "wwsFamilyName",
      "wwsSubfamilyName",
      "lightPalette",
      "darkPalette"
    ];
    
    var offset0 = offset;
    
    for(var i=0; i<count; i++)
    {
      var platformID = TyprBin.readUshort(data, offset);  offset += 2;
      var encodingID = TyprBin.readUshort(data, offset);  offset += 2;
      var languageID = TyprBin.readUshort(data, offset);  offset += 2;
      var nameID     = TyprBin.readUshort(data, offset);  offset += 2;
      var slen       = TyprBin.readUshort(data, offset);  offset += 2;
      var noffset    = TyprBin.readUshort(data, offset);  offset += 2;
      //console.warn(platformID, encodingID, languageID.toString(16), nameID, length, noffset);
      
      String? cname;
      if(nameID < names.length) {
        cname = names[nameID];
      }
    
      var soff = offset0 + count*12 + noffset;
      var str;
      if(false){}
      else if(platformID == 0) str = TyprBin.readUnicode(data, soff, slen/2);
      else if(platformID == 3 && encodingID == 0) str = TyprBin.readUnicode(data, soff, slen/2);
      else if(encodingID == 0) str = TyprBin.readASCII  (data, soff, slen);
      else if(encodingID == 1) str = TyprBin.readUnicode(data, soff, slen/2);
      else if(encodingID == 3) str = TyprBin.readUnicode(data, soff, slen/2);
      
      else if(platformID == 1) { 
        str = TyprBin.readASCII(data, soff, slen);  
        print("reading unknown MAC encoding ${encodingID} as ASCII"); 
      } else {
        throw "unknown encoding ${encodingID}, platformID: ${platformID}";
      }
      
      var tid = "p${platformID},${languageID.toRadixString(16)}";//Typr._platforms[platformID];
      if(obj[tid]==null) obj[tid] = {};
      obj[tid][cname != null ? cname : nameID] = str;
      obj[tid]["_lang"] = languageID;
      //console.warn(tid, obj[tid]);
    }
    /*
    if(format == 1)
    {
      var langTagCount = TyprBin.readUshort(data, offset);  offset += 2;
      for(var i=0; i<langTagCount; i++)
      {
        var length  = TyprBin.readUshort(data, offset);  offset += 2;
        var noffset = TyprBin.readUshort(data, offset);  offset += 2;
      }
    }
    */
    
    //console.warn(obj);
    
    for(var p in obj.keys) {
      if(obj[p]["postScriptName"] !=null && obj[p]["_lang"]==0x0409) {
        return obj[p];
      }
      // United States
    }
    for(var p in obj.keys) if(obj[p]["postScriptName"] !=null && obj[p]["_lang"]==0x0000) {
      return obj[p];		
      // Universal
    }
    for(var p in obj.keys) if(obj[p]["postScriptName"] !=null && obj[p]["_lang"]==0x0c0c) {
      return obj[p];		// Canada
    }
    for(var p in obj.keys) {
      if(obj[p]["postScriptName"] !=null) {
        return obj[p];
      }
    }
    
    var tname;
    for(var p in obj.keys) { tname=p; break; }
    
    print("returning name table with languageID "+ obj[tname]._lang);

    return obj[tname];
  }



}


