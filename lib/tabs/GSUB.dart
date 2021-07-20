part of typr_dart;


class Typr_GSUB {

    
  static parse(data, offset, length, font) {  
    return Typr_LCTF.parse(data, offset, length, font, subt);  
  }


  static subt(data, ltype, offset, ltable)	// lookup type
  {
    var offset0 = offset;
    var tab = {};
    
    tab["fmt"]  = TyprBin.readUshort(data, offset);  offset+=2;
    
    if(ltype!=1 && ltype!=4 && ltype!=5 && ltype!=6) return null;
    
    if(ltype==1 || ltype==4 || (ltype==5 && tab["fmt"]<=2) || (ltype==6 && tab["fmt"]<=2)) {
      var covOff  = TyprBin.readUshort(data, offset);  offset+=2;
      tab["coverage"] = Typr_LCTF.readCoverage(data, offset0+covOff);	// not always is coverage here
    }
    
    if(false) {}
    //  Single Substitution Subtable
    else if(ltype==1 && tab["fmt"]>=1 && tab["fmt"]<=2) {	
      if(tab["fmt"]==1) {
        tab["delta"] = TyprBin.readShort(data, offset);  offset+=2;
      }
      else if(tab["fmt"]==2) {
        var cnt = TyprBin.readUshort(data, offset);  offset+=2;
        tab["newg"] = TyprBin.readUshorts(data, offset, cnt);  offset+=tab["newg"].length*2;
      }
    }
    //  Ligature Substitution Subtable
    else if(ltype==4) {
      tab["vals"] = [];
      var cnt = TyprBin.readUshort(data, offset);  offset+=2;
      for(var i=0; i<cnt; i++) {
        var loff = TyprBin.readUshort(data, offset);  offset+=2;
        tab["vals"].add(readLigatureSet(data, offset0+loff));
      }
      //console.warn(tab.coverage);
      //console.warn(tab.vals);
    } 
    //  Contextual Substitution Subtable
    else if(ltype==5 && tab["fmt"]==2) {
      if(tab["fmt"]==2) {
        var cDefOffset = TyprBin.readUshort(data, offset);  offset+=2;
        tab["cDef"] = Typr_LCTF.readClassDef(data, offset0 + cDefOffset);
        tab["scset"] = [];
        var subClassSetCount = TyprBin.readUshort(data, offset);  offset+=2;
        for(var i=0; i<subClassSetCount; i++)
        {
          var scsOff = TyprBin.readUshort(data, offset);  offset+=2;
          tab["scset"].add(  scsOff==0 ? null : readSubClassSet(data, offset0 + scsOff)  );
        }
      }
      //else console.warn("unknown table format", tab.fmt);
    }
    //*
    else if(ltype==6 && tab["fmt"]==3) {
      /*
      if(tab.fmt==2) {
        var btDef = TyprBin.readUshort(data, offset);  offset+=2;
        var inDef = TyprBin.readUshort(data, offset);  offset+=2;
        var laDef = TyprBin.readUshort(data, offset);  offset+=2;
        
        tab.btDef = Typr._lctf.readClassDef(data, offset0 + btDef);
        tab.inDef = Typr._lctf.readClassDef(data, offset0 + inDef);
        tab.laDef = Typr._lctf.readClassDef(data, offset0 + laDef);
        
        tab.scset = [];
        var cnt = TyprBin.readUshort(data, offset);  offset+=2;
        for(var i=0; i<cnt; i++) {
          var loff = TyprBin.readUshort(data, offset);  offset+=2;
          tab.scset.push(Typr.GSUB.readChainSubClassSet(data, offset0+loff));
        }
      }
      */
      if(tab["fmt"]==3) {
        for(var i=0; i<3; i++) {
          var cnt = TyprBin.readUshort(data, offset);  offset+=2;
          var cvgs = [];
          for(var j=0; j<cnt; j++) cvgs.add( Typr_LCTF.readCoverage(data, offset0 + TyprBin.readUshort(data, offset+j*2))   );
          offset+=cnt*2;
          if(i==0) tab["backCvg"] = cvgs;
          if(i==1) tab["inptCvg"] = cvgs;
          if(i==2) tab["ahedCvg"] = cvgs;
        }
        var cnt = TyprBin.readUshort(data, offset);  offset+=2;
        tab["lookupRec"] = readSubstLookupRecords(data, offset, cnt);
      }
      //console.warn(tab);
    } //*/
    else if(ltype==7 && tab["fmt"]==1) {
      var extType = TyprBin.readUshort(data, offset);  offset+=2;
      var extOffset = TyprBin.readUint(data, offset);  offset+=4;
      if (ltable.ltype==9) {
        ltable.ltype = extType;
      } else if (ltable.ltype!=extType) {
        throw "invalid extension substitution"; // all subtables must be the same type
      }
      return subt(data, ltable.ltype, offset0+extOffset, null);
    } else {
      print("unsupported GSUB table LookupType: ${ltype} format ${tab["fmt"]} ");
    }
    //if(tab.coverage.indexOf(3)!=-1) console.warn(ltype, fmt, tab);
    
    return tab;
  }

  static readSubClassSet(data, offset)
  {
    var rUs = TyprBin.readUshort, offset0 = offset, lset = [];
    var cnt = rUs(data, offset);  offset+=2;
    for(var i=0; i<cnt; i++) {
      var loff = rUs(data, offset);  offset+=2;
      lset.add(readSubClassRule(data, offset0+loff));
    }
    return lset;
  }

  static readSubClassRule(data, offset)
  {
    var rUs = TyprBin.readUshort, offset0 = offset;
    var rule = {};
    var gcount = rUs(data, offset);  offset+=2;
    var scount = rUs(data, offset);  offset+=2;
    rule["input"] = [];
    for(var i=0; i<gcount-1; i++) {
      rule["input"].add(rUs(data, offset));  offset+=2;
    }
    rule["substLookupRecords"] = readSubstLookupRecords(data, offset, scount);
    return rule;
  }

  static readSubstLookupRecords(data, offset, cnt)
  {
    var rUs = TyprBin.readUshort;
    var out = [];
    for(var i=0; i<cnt; i++) {  out.addAll([ rUs(data, offset), rUs(data, offset+2) ]);  offset+=4;  }
    return out;
  }

  static readChainSubClassSet(data, offset)
  {
    var offset0 = offset, lset = [];
    var cnt = TyprBin.readUshort(data, offset);  offset+=2;
    for(var i=0; i<cnt; i++) {
      var loff = TyprBin.readUshort(data, offset);  offset+=2;
      lset.add(readChainSubClassRule(data, offset0+loff));
    }
    return lset;
  }

  static readChainSubClassRule(data, offset)
  {
    var offset0 = offset, rule = {};
    var pps = ["backtrack", "input", "lookahead"];
    for(var pi=0; pi<pps.length; pi++) {
      var cnt = TyprBin.readUshort(data, offset);  offset+=2;  if(pi==1) cnt--;
      rule[pps[pi]]=TyprBin.readUshorts(data, offset, cnt);  offset+= rule[pps[pi]].length*2;
    }
    var cnt = TyprBin.readUshort(data, offset);  offset+=2;
    rule["subst"] = TyprBin.readUshorts(data, offset, cnt*2);  offset += rule["subst"].length*2;
    return rule;
  }

  static readLigatureSet(data, offset)
  {
    var offset0 = offset, lset = [];
    var lcnt = TyprBin.readUshort(data, offset);  offset+=2;
    for(var j=0; j<lcnt; j++) {
      var loff = TyprBin.readUshort(data, offset);  offset+=2;
      lset.add(readLigature(data, offset0+loff));
    }
    return lset;
  }

  static readLigature(data, offset)
  {
    Map<String, dynamic> lig = {"chain":[]};
    lig["nglyph"] = TyprBin.readUshort(data, offset);  offset+=2;
    var ccnt = TyprBin.readUshort(data, offset);  offset+=2;
    for(var k=0; k<ccnt-1; k++) {  lig["chain"].add(TyprBin.readUshort(data, offset));  offset+=2;  }
    return lig;
  }


}


