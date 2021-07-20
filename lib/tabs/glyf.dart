part of typr_dart;

class Typr_GLYF {

  static parse(data, offset, length, font)
  {
    var obj = [];
    for(var g=0; g<font["maxp"]["numGlyphs"]; g++) obj.add(null);
    return obj;
  }

  static Map<String, dynamic>? _parseGlyf(font, g)
  {
    var data = font._data;
    
    var offset = Typr._tabOffset(data, "glyf", font._offset) + font.loca[g];
      
    if(font.loca[g]==font.loca[g+1]) return null;
      
    Map<String, dynamic> gl = {};
      
    gl["noc"]  = TyprBin.readShort(data, offset);  offset+=2;		// number of contours
    gl["xMin"] = TyprBin.readShort(data, offset);  offset+=2;
    gl["yMin"] = TyprBin.readShort(data, offset);  offset+=2;
    gl["xMax"] = TyprBin.readShort(data, offset);  offset+=2;
    gl["yMax"] = TyprBin.readShort(data, offset);  offset+=2;
    
    if(gl["xMin"] >= gl["xMax"] || gl["yMin"] >= gl["yMax"]) return null;
      
    if(gl["noc"] > 0 )
    {
      gl["endPts"] = [];
      for(var i=0; i<gl["noc"]; i++) { gl["endPts"].add(TyprBin.readUshort(data,offset)); offset+=2; }
      
      var instructionLength = TyprBin.readUshort(data,offset); offset+=2;
      if((data.length-offset)<instructionLength) return null;
      gl["instructions"] = TyprBin.readBytes(data, offset, instructionLength);   offset+=instructionLength;
      
      var crdnum = gl["endPts"][gl["noc"]-1]+1;
      gl["flags"] = [];
      for(var i=0; i<crdnum; i++ ) 
      { 
        var flag = data[offset];  offset++; 
        gl["flags"].add(flag); 
        if((flag&8)!=0)
        {
          var rep = data[offset];  offset++;
          for(var j=0; j<rep; j++) { gl["flags"].add(flag); i++; }
        }
      }
      gl["xs"] = List<int>.empty(growable: true);
      for(var i=0; i<crdnum; i++) {
        var i8=((gl["flags"][i]&2)!=0), same=((gl["flags"][i]&16)!=0);  
        if(i8) { gl["xs"].add(same ? data[offset] : -data[offset]);  offset++; }
        else
        {
          if(same) gl["xs"].add(0);
          else { gl["xs"].add(TyprBin.readShort(data, offset));  offset+=2; }
        }
      }
      gl["ys"] = List<int>.empty(growable: true);
      for(var i=0; i<crdnum; i++) {
        var i8=((gl["flags"][i]&4)!=0), same=((gl["flags"][i]&32)!=0);  
        if(i8) { gl["ys"].add(same ? data[offset] : -data[offset]);  offset++; }
        else
        {
          if(same) gl["ys"].add(0);
          else { gl["ys"].add(TyprBin.readShort(data, offset));  offset+=2; }
        }
      }
      int x = 0, y = 0;
      for(var i=0; i<crdnum; i++) {
        int _xsi = gl["xs"][i];
        int _ysi = gl["ys"][i];
        x += _xsi; 
        y += _ysi;
        gl["xs"][i]=x;
        gl["ys"][i]=y; 
      }
      //console.warn(endPtsOfContours, instructionLength, instructions, flags, xCoordinates, yCoordinates);
    } else {
      var ARG_1_AND_2_ARE_WORDS	= 1<<0;
      var ARGS_ARE_XY_VALUES		= 1<<1;
      var ROUND_XY_TO_GRID		= 1<<2;
      var WE_HAVE_A_SCALE			= 1<<3;
      var RESERVED				= 1<<4;
      var MORE_COMPONENTS			= 1<<5;
      var WE_HAVE_AN_X_AND_Y_SCALE= 1<<6;
      var WE_HAVE_A_TWO_BY_TWO	= 1<<7;
      var WE_HAVE_INSTRUCTIONS	= 1<<8;
      var USE_MY_METRICS			= 1<<9;
      var OVERLAP_COMPOUND		= 1<<10;
      var SCALED_COMPONENT_OFFSET	= 1<<11;
      var UNSCALED_COMPONENT_OFFSET	= 1<<12;
      
      gl["parts"] = [];
      var flags;
      do {
        flags = TyprBin.readUshort(data, offset);  offset += 2;
        Map<String, dynamic> part = { "m":{"a":1,"b":0,"c":0,"d":1,"tx":0,"ty":0}, "p1":-1, "p2":-1 };  gl["parts"].add(part);
        part["glyphIndex"] = TyprBin.readUshort(data, offset);  offset += 2;
        
        int arg1;
        int arg2;
        
        if ( flags & ARG_1_AND_2_ARE_WORDS) {
          arg1 = TyprBin.readShort(data, offset);  offset += 2;
          arg2 = TyprBin.readShort(data, offset);  offset += 2;
        } else {
          arg1 = TyprBin.readInt8(data, offset);  offset ++;
          arg2 = TyprBin.readInt8(data, offset);  offset ++;
        }
        
        if(flags & ARGS_ARE_XY_VALUES) {
          var _pm = part["m"];
          _pm["tx"] = arg1;  
          _pm["ty"] = arg2;
        } else  {  part["p1"] = arg1;  part["p2"]=arg2;  }
        //part.m.tx = arg1;  part.m.ty = arg2;
        //else { throw "params are not XY values"; }
        
        if ( flags & WE_HAVE_A_SCALE ) {
          part["m"]["a"] = part["m"]["d"] = TyprBin.readF2dot14(data, offset);  offset += 2;    
        } else if ( flags & WE_HAVE_AN_X_AND_Y_SCALE ) {
          part["m"]["a"] = TyprBin.readF2dot14(data, offset);  offset += 2; 
          part["m"]["d"] = TyprBin.readF2dot14(data, offset);  offset += 2; 
        } else if ( flags & WE_HAVE_A_TWO_BY_TWO ) {
          part["m"]["a"] = TyprBin.readF2dot14(data, offset);  offset += 2; 
          part["m"]["b"] = TyprBin.readF2dot14(data, offset);  offset += 2; 
          part["m"]["c"] = TyprBin.readF2dot14(data, offset);  offset += 2; 
          part["m"]["d"] = TyprBin.readF2dot14(data, offset);  offset += 2; 
        }
      } while ( flags & MORE_COMPONENTS );

      if (flags & WE_HAVE_INSTRUCTIONS){
        var numInstr = TyprBin.readUshort(data, offset);  offset += 2;
        gl["instr"] = [];
        for(var i=0; i<numInstr; i++) { gl["instr"].add(data[offset]);  offset++; }
      }
    }
    return gl;
  }

}

