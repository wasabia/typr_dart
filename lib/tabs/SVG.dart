part of typr_dart;


class Typr_SVG {
    
  static Map<String, dynamic> parse(Uint8List data, offset, length)
  {
    Map<String, dynamic> obj = { "entries": {}};

    var offset0 = offset;

    var tableVersion = TyprBin.readUshort(data, offset);	offset += 2;
    var svgDocIndexOffset = TyprBin.readUint(data, offset);	offset += 4;
    var reserved = TyprBin.readUint(data, offset); offset += 4;

    offset = svgDocIndexOffset + offset0;

    var numEntries = TyprBin.readUshort(data, offset);	offset += 2;

    for(var i=0; i<numEntries; i++)
    {
      var startGlyphID = TyprBin.readUshort(data, offset);  offset += 2;
      var endGlyphID   = TyprBin.readUshort(data, offset);  offset += 2;
      var svgDocOffset = TyprBin.readUint  (data, offset);  offset += 4;
      var svgDocLength = TyprBin.readUint  (data, offset);  offset += 4;

      // var sbuf = new Uint8Array(data.buffer, offset0 + svgDocOffset + svgDocIndexOffset, svgDocLength);
      int _offset = offset0 + svgDocOffset + svgDocIndexOffset;
      int _length = svgDocLength;
      var sbuf = data.sublist(_offset, _offset + _length);
      
      var svg = TyprBin.readUTF8(sbuf, 0, sbuf.length);
      
      for(var f=startGlyphID; f<=endGlyphID; f++) {
        obj["entries"][f] = svg;
      }
    }
    return obj;
  }

  static Map<String, dynamic> toPath(str) {
    Map<String, dynamic> pth = {"cmds":[], "crds":[]};
    if(str==null) return pth;
    
    // var prsr = new DomParser();
    // var doc = prsr.parseFromString(str,"image/svg+xml");

    var doc = parseXmlDocument(str);
    
    Element svg = doc.firstChild! as Element;  
    while(svg.tagName != "svg") svg = svg.nextElementSibling!;
    var vbs = svg.getAttribute("viewBox");
    var vb;
    if(vbs != null) {
      vb = vbs.trim().split(" ").map((n) => num.parse(n));
    } else {
      vb = [0,0,1000,1000];
    }
    _toPath(svg.children, pth, null);
    for(var i=0; i<pth["crds"].length; i+=2) {
      var x = pth["crds"][i], y = pth["crds"][i+1];
      x -= vb[0];
      y -= vb[1];
      y = -y;
      pth["crds"][i] = x;
      pth["crds"][i+1] = y;
    }
    return pth;
  }

  static _toPath(nds, pth, fill) {
    for(var ni=0; ni<nds.length; ni++) {
      var nd = nds[ni], tn = nd.tagName;
      var cfl = nd.getAttribute("fill");  if(cfl==null) cfl = fill;
      if(tn=="g") _toPath(nd.children, pth, cfl);
      else if(tn=="path") {
        pth["cmds"].add(cfl ?? "#000000");
        var d = nd.getAttribute("d");  //console.warn(d);
        var toks = _tokens(d);  //console.warn(toks);
        _toksToPath(toks, pth);  pth["cmds"].add("X");
      }
      else if(tn=="defs") {}
      else print(" tn, nd: ${tn}  ${nd}");
    }
  }

  static _tokens(String d) {
    var ts = [], off = 0, rn=false, cn="";  // reading number, current number
    while(off<d.length){
      var cc=d.codeUnitAt(off), ch = d[off];  off++;
      var isNum = (48<=cc && cc<=57) || ch=="." || ch=="-";
      
      if(rn) {
        if(ch=="-") {  ts.add(num.parse(cn));  cn=ch;  }
        else if(isNum) cn+=ch;
        else {  ts.add(num.parse(cn));  if(ch!="," && ch!=" ") ts.add(ch);  rn=false;  }
      }
      else {
        if(isNum) {  cn=ch;  rn=true;  }
        else if(ch!="," && ch!=" ") ts.add(ch);
      }
    }
    if(rn) ts.add(num.parse(cn));
    return ts;
  }

  static _toksToPath(ts, pth) {	
    num i = 0, x = 0, y = 0, ox = 0, oy = 0;
    var pc = {"M":2,"L":2,"H":1,"V":1,   "S":4,   "C":6};
    var cmds = pth["cmds"];
    List crds = pth["crds"];
    
    while(i<ts.length) {
      var cmd = ts[i];  i++;
      
      if(cmd=="z") {  cmds.push("Z");  x=ox;  y=oy;  }
      else {
        var cmu = cmd.toUpperCase();
        var ps = pc[cmu], reps = _reps(ts, i, ps);
      
        for(var j=0; j<reps; j++) {
          num xi = 0, yi = 0;   if(cmd!=cmu) {  xi=x;  yi=y;  }
          
          if(false) {}
          else if(cmu=="M") {  x = xi+ts[i++];  y = yi+ts[i++];  cmds.add("M");  crds.addAll([ x,y ]);  ox=x;  oy=y; }
          else if(cmu=="L") {  x = xi+ts[i++];  y = yi+ts[i++];  cmds.add("L");  crds.addAll([ x,y ]);  }
          else if(cmu=="H") {  x = xi+ts[i++];                   cmds.add("L");  crds.addAll([ x,y ]);  }
          else if(cmu=="V") {  y = yi+ts[i++];                   cmds.add("L");  crds.addAll([ x,y ]);  }
          else if(cmu=="C") {
            var x1=xi+ts[i++], y1=yi+ts[i++], x2=xi+ts[i++], y2=yi+ts[i++], x3=xi+ts[i++], y3=yi+ts[i++];
            cmds.push("C");  crds.addAll( [ x1,y1,x2,y2,x3,y3 ] );  x=x3;  y=y3;
          }
          else if(cmu=="S") {
            var co = math.max(crds.length-4, 0);
            var x1 = x+x-crds[co], y1 = y+y-crds[co+1];
            var x2=xi+ts[i++], y2=yi+ts[i++], x3=xi+ts[i++], y3=yi+ts[i++];  
            cmds.push("C");  crds.addAll([ x1,y1,x2,y2,x3,y3 ]);  x=x3;  y=y3;
          } else {
            print("Unknown SVG command "+cmd);
          }
        }
      }
    }
  }
  
  static _reps(ts, off, ps) {
    var i = off;
    while(i<ts.length) {  
      if(ts[i] is String) break;  i+=ps;  
    }
    return (i-off)/ps;
  }

}
