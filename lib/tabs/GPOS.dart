part of typr_dart;


class Typr_GPOS {

  static parse(data, offset, length, font) {  
    return Typr_LCTF.parse(data, offset, length, font, subt);  
  }


  static subt(data, ltype, offset, ltable)	// lookup type
  {
    var offset0 = offset;
    Map<String, dynamic> tab = {};
    
    tab["fmt"]  = TyprBin.readUshort(data, offset);  offset+=2;
    
    //console.warn(ltype, tab.fmt);
    
    if(ltype==1 || ltype==2 || ltype==3 || ltype==7 || (ltype==8 && tab["fmt"]<=2)) {
      var covOff  = TyprBin.readUshort(data, offset);  offset+=2;
      tab["coverage"] = Typr_LCTF.readCoverage(data, covOff+offset0);
    }
    if(ltype==1 && tab["fmt"]==1) {
      var valFmt1 = TyprBin.readUshort(data, offset);  offset+=2;
      var ones1 = Typr_LCTF.numOfOnes(valFmt1);
      if(valFmt1!=0)  tab["pos"] = readValueRecord(data, offset, valFmt1);
    }
    else if(ltype==2 && tab["fmt"]>=1 && tab["fmt"]<=2) {
      var valFmt1 = TyprBin.readUshort(data, offset);  offset+=2;
      var valFmt2 = TyprBin.readUshort(data, offset);  offset+=2;
      var ones1 = Typr_LCTF.numOfOnes(valFmt1);
      var ones2 = Typr_LCTF.numOfOnes(valFmt2);
      if(tab["fmt"]==1)
      {
        tab["pairsets"] = [];
        var psc = TyprBin.readUshort(data, offset);  offset+=2;  // PairSetCount
        
        for(var i=0; i<psc; i++)
        {
          var psoff = offset0 + TyprBin.readUshort(data, offset);  offset+=2;
          
          var pvc = TyprBin.readUshort(data, psoff);  psoff+=2;
          var arr = [];
          for(var j=0; j<pvc; j++)
          {
            var gid2 = TyprBin.readUshort(data, psoff);  psoff+=2;
            var value1, value2;
            if(valFmt1!=0) {  value1 = readValueRecord(data, psoff, valFmt1);  psoff+=ones1*2;  }
            if(valFmt2!=0) {  value2 = readValueRecord(data, psoff, valFmt2);  psoff+=ones2*2;  }
            //if(value1!=null) throw "e";
            arr.add({"gid2":gid2, "val1":value1, "val2":value2});
          }
          tab["pairsets"].add(arr);
        }
      }
      if(tab["fmt"]==2)
      {
        var classDef1 = TyprBin.readUshort(data, offset);  offset+=2;
        var classDef2 = TyprBin.readUshort(data, offset);  offset+=2;
        var class1Count = TyprBin.readUshort(data, offset);  offset+=2;
        var class2Count = TyprBin.readUshort(data, offset);  offset+=2;
        
        tab["classDef1"] = Typr_LCTF.readClassDef(data, offset0 + classDef1);
        tab["classDef2"] = Typr_LCTF.readClassDef(data, offset0 + classDef2);
        
        tab["matrix"] = [];
        for(var i=0; i<class1Count; i++)
        {
          var row = [];
          for(var j=0; j<class2Count; j++)
          {
            var value1 = null, value2 = null;
            if(valFmt1!=0) { value1 = readValueRecord(data, offset, valFmt1);  offset+=ones1*2; }
            if(valFmt2!=0) { value2 = readValueRecord(data, offset, valFmt2);  offset+=ones2*2; }
            row.add({"val1":value1, "val2":value2});
          }
          tab["matrix"].add(row);
        }
      }
    } else if(ltype==9 && tab["fmt"]==1) {
      var extType = TyprBin.readUshort(data, offset);  offset+=2;
      var extOffset = TyprBin.readUint(data, offset);  offset+=4;
      if (ltable.ltype==9) {
        ltable.ltype = extType;
      } else if (ltable.ltype!=extType) {
        throw "invalid extension substitution"; // all subtables must be the same type
      }
      return subt(data, ltable.ltype, offset0+extOffset, null);
    } else {
      print("unsupported GPOS table LookupType: ${ltype} format: ${tab["fmt"]}");
    }
    /*else if(ltype==4) {
      
    }*/
    return tab;
  }


  static readValueRecord(data, offset, valFmt)
  {

    var arr = [];
    arr.add( (valFmt&1 != 0) ? TyprBin.readShort(data, offset) : 0 );  offset += (valFmt&1 != 0) ? 2 : 0;  // X_PLACEMENT
    arr.add( (valFmt&2 != 0) ? TyprBin.readShort(data, offset) : 0 );  offset += (valFmt&2 != 0) ? 2 : 0;  // Y_PLACEMENT
    arr.add( (valFmt&4 != 0) ? TyprBin.readShort(data, offset) : 0 );  offset += (valFmt&4 != 0) ? 2 : 0;  // X_ADVANCE
    arr.add( (valFmt&8 != 0) ? TyprBin.readShort(data, offset) : 0 );  offset += (valFmt&8 != 0) ? 2 : 0;  // Y_ADVANCE
    return arr;
  }

}
