part of typr_dart;

class Typr_U {
  static codeToGlyph(Font font, code) {
    Map<String, dynamic> cmap = font.cmap;

    var tind = -1;
    if (cmap["p0e4"] != null)
      tind = cmap["p0e4"];
    else if (cmap["p3e1"] != null)
      tind = cmap["p3e1"];
    else if (cmap["p1e0"] != null)
      tind = cmap["p1e0"];
    else if (cmap["p0e3"] != null) tind = cmap["p0e3"];

    if (tind == -1) throw "no familiar platform and encoding!";

    Map<String, dynamic> tab = cmap["tables"][tind];

    if (tab["format"] == 0) {
      if (code >= tab["map"].length) return 0;
      return tab["map"][code];
    } else if (tab["format"] == 4) {
      var sind = -1;
      for (var i = 0; i < tab["endCount"].length; i++)
        if (code <= tab["endCount"][i]) {
          sind = i;
          break;
        }
      if (sind == -1) return 0;
      if (tab["startCount"][sind] > code) return 0;

      var gli = 0;
      if (tab["idRangeOffset"][sind] != 0)
        gli = tab["glyphIdArray"][(code - tab["startCount"][sind]) +
            (tab["idRangeOffset"][sind] >> 1) -
            (tab["idRangeOffset"].length - sind)];
      else
        gli = code + tab["idDelta"][sind];
      return gli & 0xFFFF;
    } else if (tab["format"] == 12) {
      if (code > tab["groups"][tab["groups"].length - 1][1]) return 0;
      for (var i = 0; i < tab["groups"].length; i++) {
        var grp = tab["groups"][i];
        if (grp[0] <= code && code <= grp[1]) return grp[2] + (code - grp[0]);
      }
      return 0;
    } else
      throw "unknown cmap table format " + tab["format"];
  }

  static Map<String, dynamic> glyphToPath(Font font, gid) {
    Map<String, dynamic> path = {"cmds": [], "crds": []};
    if (font.SVG != null && font.SVG["entries"][gid] != null) {
      var p = font.SVG["entries"][gid];
      if (p == null) return path;
      if (p is String) {
        p = Typr_SVG.toPath(p);
        font.SVG["entries"][gid] = p;
      }
      return p;
    } else if (font.CFF != null) {
      var state = {
        "x": 0,
        "y": 0,
        "stack": [],
        "nStems": 0,
        "haveWidth": false,
        "width":
            font.CFF["Private"] != null ? font.CFF["Private"].defaultWidthX : 0,
        "open": false
      };
      var cff = font.CFF, pdct = font.CFF["Private"];
      if (cff["ROS"] != null) {
        var gi = 0;
        while (cff["FDSelect"][gi + 2] <= gid) gi += 2;
        pdct = cff["FDArray"][cff["FDSelect"][gi + 1]]["Private"];
      }
      _drawCFF(font.CFF["CharStrings"][gid], state, cff, pdct, path);
    } else if (font.glyf != null) {
      _drawGlyf(gid, font, path);
    }
    return path;
  }

  static _drawGlyf(gid, font, path) {
    var gl = font.glyf[gid];
    if (gl == null) gl = font.glyf[gid] = Typr_GLYF._parseGlyf(font, gid);
    if (gl != null) {
      if (gl["noc"] > -1)
        _simpleGlyph(gl, path);
      else
        _compoGlyph(gl, font, path);
    }
  }

  static _simpleGlyph(Map<String, dynamic> gl, p) {
    for (var c = 0; c < gl["noc"]; c++) {
      var i0 = (c == 0) ? 0 : (gl["endPts"][c - 1] + 1);
      var il = gl["endPts"][c];

      for (var i = i0; i <= il; i++) {
        var pr = (i == i0) ? il : (i - 1);
        var nx = (i == il) ? i0 : (i + 1);
        var onCurve = gl["flags"][i] & 1;
        var prOnCurve = gl["flags"][pr] & 1;
        var nxOnCurve = gl["flags"][nx] & 1;

        var x = gl["xs"][i], y = gl["ys"][i];

        if (i == i0) {
          if (onCurve == 1) {
            if (prOnCurve == 1)
              Typr_U_P.moveTo(p, gl["xs"][pr], gl["ys"][pr]);
            else {
              Typr_U_P.moveTo(p, x, y);
              continue;
              /*  will do curveTo at il  */
            }
          } else {
            if (prOnCurve == 1)
              Typr_U_P.moveTo(p, gl["xs"][pr], gl["ys"][pr]);
            else
              Typr_U_P.moveTo(
                  p, (gl["xs"][pr] + x) / 2, (gl["ys"][pr] + y) / 2);
          }
        }
        if (onCurve == 1) {
          if (prOnCurve == 1) Typr_U_P.lineTo(p, x, y);
        } else {
          if (nxOnCurve == 1)
            Typr_U_P.qcurveTo(p, x, y, gl["xs"][nx], gl["ys"][nx]);
          else
            Typr_U_P.qcurveTo(
                p, x, y, (x + gl["xs"][nx]) / 2, (y + gl["ys"][nx]) / 2);
        }
      }
      Typr_U_P.closePath(p);
    }
  }

  static _compoGlyph(gl, font, p) {
    for (var j = 0; j < gl.parts.length; j++) {
      Map<String, dynamic> path = {"cmds": [], "crds": []};
      var prt = gl.parts[j];
      _drawGlyf(prt.glyphIndex, font, path);

      var m = prt.m;
      for (var i = 0; i < path["crds"].length; i += 2) {
        var x = path["crds"][i], y = path["crds"][i + 1];
        p.crds.push(x * m.a + y * m.b + m.tx);
        p.crds.push(x * m.c + y * m.d + m.ty);
      }
      for (var i = 0; i < path["cmds"].length; i++)
        p.cmds.push(path["cmds"][i]);
    }
  }

  static _getGlyphClass(g, cd) {
    var intr = Typr_LCTF.getInterval(cd, g);
    return intr == -1 ? 0 : cd[intr + 2];
    //for(var i=0; i<cd.start.length; i++)
    //	if(cd.start[i]<=g && cd.end[i]>=g) return cd.class[i];
    //return 0;
  }

  static num getPairAdjustment(font, g1, g2) {
    num offset = 0;
    if (font.GPOS != null) {
      var gpos = font.GPOS;
      var llist = gpos["lookupList"], flist = gpos["featureList"];
      Map<int, bool> tused = {};
      for (var i = 0; i < flist.length; i++) {
        var fl = flist[i];
        //console.warn(fl);
        if (fl["tag"] != "kern") continue;

        var _fl_tab = fl["tab"];

        for (var ti = 0; ti < _fl_tab.length; ti++) {
          var _ftti = _fl_tab[ti];

          if (tused[_ftti] == true) continue;
          tused[_ftti] = true;
          var tab = llist[_ftti];
          //console.warn(tab);

          for (var j = 0; j < tab["tabs"].length; j++) {
            if (tab["tabs"][j] == null) continue;
            var ltab = tab["tabs"][j], ind;
            if (ltab["coverage"] != null) {
              ind = Typr_LCTF.coverageIndex(ltab["coverage"], g1);
              if (ind == -1) continue;
            }

            if (tab["ltype"] == 1) {
              //console.warn(ltab);
            } else if (tab["ltype"] == 2) {
              var adj;
              if (ltab["fmt"] == 1) {
                var right = ltab["pairsets"][ind];
                for (var i = 0; i < right.length; i++)
                  if (right[i].gid2 == g2) adj = right[i];
              } else if (ltab["fmt"] == 2) {
                var c1 = _getGlyphClass(g1, ltab["classDef1"]);
                var c2 = _getGlyphClass(g2, ltab["classDef2"]);
                adj = ltab["matrix"][c1][c2];
              }
              if (adj != null &&
                  adj["val1"] != null &&
                  adj["val1"][2] != null) {
                offset += adj.val1[2]; // xAdvance adjustment of first glyph
              }
              if (adj != null &&
                  adj["val2"] != null &&
                  adj["val2"][0] != null) {
                offset += adj.val2[0]; // xPlacement adjustment of second glyph
              }
            }
          }
        }
      }
    }
    if (font.kern != null) {
      var ind1 = font.kern.glyph1.indexOf(g1);
      if (ind1 != -1) {
        var ind2 = font.kern.rval[ind1].glyph2.indexOf(g2);
        if (ind2 != -1) offset += font.kern.rval[ind1].vals[ind2];
      }
    }

    return offset;
  }

  static stringToGlyphs(font, str) {
    var gls = [];
    for (var i = 0; i < str.length; i++) {
      var cc = str.codeUnitAt(i);
      if (cc > 0xffff) i++;
      gls.add(codeToGlyph(font, cc));
    }
    for (var i = 0; i < str.length; i++) {
      var cc = str.codeUnitAt(i); //
      if (cc == 2367) {
        var t = gls[i - 1];
        gls[i - 1] = gls[i];
        gls[i] = t;
      }
      //if(cc==2381) {  var t=gls[i+1];  gls[i+1]=gls[i];  gls[i]=t;  }
      if (cc > 0xffff) i++;
    }
    //console.warn(gls.slice(0));

    //console.warn(gls);  return gls;

    Map<String, dynamic>? gsub = font.GSUB;
    if (gsub == null) return gls;
    var llist = gsub["lookupList"], flist = gsub["featureList"];

    var cligs = [
      "rlig",
      "liga",
      "mset",
      "isol",
      "init",
      "fina",
      "medi",
      "half",
      "pres",
      "blws" /* Tibetan fonts like Himalaya.ttf */
    ];

    //console.warn(gls.slice(0));
    Map<int, bool> tused = {};

    for (var fi = 0; fi < flist.length; fi++) {
      Map<String, dynamic> fl = flist[fi];

      if (cligs.indexOf(fl["tag"]) == -1) continue;
      //if(fl.tag=="blwf") continue;
      //console.warn(fl);
      //console.warn(fl.tag);
      for (var ti = 0; ti < fl["tab"].length; ti++) {
        if (fl["tab"][ti] == true) continue;

        tused[fl["tab"][ti]] = true;
        var tab = llist[fl["tab"][ti]];
        //console.warn(fl.tab[ti], tab.ltype);
        //console.warn(fl.tag, tab);
        for (var ci = 0; ci < gls.length; ci++) {
          var feat = _getWPfeature(str, ci);
          if ("isol,init,fina,medi".indexOf(fl["tag"]) != -1 &&
              fl["tag"] != feat) continue;

          applySubs(gls, ci, tab, llist);
        }
      }
    }

    return gls;
  }

  static _getWPfeature(str, ci) {
    // get Word Position feature
    var wsep = "\n\t\" ,.:;!?()  ،";
    var R =
        "آأؤإاةدذرزوٱٲٳٵٶٷڈډڊڋڌڍڎڏڐڑڒړڔڕږڗژڙۀۃۄۅۆۇۈۉۊۋۍۏےۓەۮۯܐܕܖܗܘܙܞܨܪܬܯݍݙݚݛݫݬݱݳݴݸݹࡀࡆࡇࡉࡔࡧࡩࡪࢪࢫࢬࢮࢱࢲࢹૅેૉ૊૎૏ૐ૑૒૝ૡ૤૯஁ஃ஄அஉ஌எஏ஑னப஫஬";
    var L = "ꡲ્૗";

    var slft = ci == 0 || wsep.indexOf(str[ci - 1]) != -1;
    var srgt = ci == str.length - 1 || wsep.indexOf(str[ci + 1]) != -1;

    if (!slft && R.indexOf(str[ci - 1]) != -1) slft = true;
    if (!srgt && R.indexOf(str[ci]) != -1) srgt = true;

    if (!srgt && L.indexOf(str[ci + 1]) != -1) srgt = true;
    if (!slft && L.indexOf(str[ci]) != -1) slft = true;

    var feat = null;
    if (slft)
      feat = srgt ? "isol" : "init";
    else
      feat = srgt ? "fina" : "medi";

    return feat;
  }

  static applySubs(gls, ci, Map<String, dynamic> tab, llist) {
    //if(ci==0) console.warn("++++ ", tab.ltype);
    var rlim = gls.length - ci - 1;
    for (var j = 0; j < tab["tabs"].length; j++) {
      if (tab["tabs"][j] == null) continue;
      Map<String, dynamic> ltab = Map<String, dynamic>.from(tab["tabs"][j]);
      var ind;
      if (ltab["coverage"] != null) {
        ind = Typr_LCTF.coverageIndex(ltab["coverage"], gls[ci]);
        if (ind == -1) continue;
      }
      //if(ci==0) console.warn(ind, ltab);
      //*

      var _ltype = tab["ltype"];
      var _fmt = ltab["fmt"];

      if (_ltype == 1) {
        var gl = gls[ci];
        if (_fmt == 1)
          gls[ci] = gls[ci] + ltab["delta"];
        else
          gls[ci] = ltab["newg"][ind];
        //console.warn("applying ... 1", ci, gl, gls[ci]);
      } //*
      else if (_ltype == 4) {
        var vals = ltab["vals"][ind];

        for (var k = 0; k < vals.length; k++) {
          Map<String, dynamic> lig = vals[k];
          var rl = lig["chain"].length;
          if (rl > rlim) continue;
          var good = true, em1 = 0;
          for (var l = 0; l < rl; l++) {
            while (gls[ci + em1 + (1 + l)] == -1) em1++;
            if (lig["chain"][l] != gls[ci + em1 + (1 + l)]) good = false;
          }
          if (!good) continue;
          gls[ci] = lig["nglyph"];
          for (var l = 0; l < rl + em1; l++) gls[ci + l + 1] = -1;
          break; // first character changed, other ligatures do not apply anymore
          //console.warn("lig", ci, lig.chain, lig.nglyph);
          //console.warn("applying ...");
        }
      } else if (_ltype == 5 && _fmt == 2) {
        var cind = Typr_LCTF.getInterval(ltab["cDef"], gls[ci]);
        var cls = ltab["cDef"][cind + 2], scs = ltab["scset"][cls];
        for (var i = 0; i < scs.length; i++) {
          var sc = scs[i], inp = sc.input;
          if (inp.length > rlim) continue;
          var good = true;
          for (var l = 0; l < inp.length; l++) {
            var cind2 = Typr_LCTF.getInterval(ltab["cDef"], gls[ci + 1 + l]);
            if (cind == -1 && ltab["cDef"][cind2 + 2] != inp[l]) {
              good = false;
              break;
            }
          }
          if (!good) continue;
          //console.warn(ci, gl);
          var lrs = sc.substLookupRecords;
          for (var k = 0; k < lrs.length; k += 2) {
            var gi = lrs[k], tabi = lrs[k + 1];
            //Typr.U._applyType1(gls, ci+gi, llist[tabi]);
            //console.warn(tabi, gls[ci+gi], llist[tabi]);
          }
        }
      } else if (_ltype == 6 && _fmt == 3) {
        //if(ltab.backCvg.length==0) return;
        if (!_glsCovered(gls, ltab["backCvg"], ci - ltab["backCvg"].length))
          continue;
        if (!_glsCovered(gls, ltab["inptCvg"], ci)) continue;
        if (!_glsCovered(gls, ltab["ahedCvg"], ci + ltab["inptCvg"].length))
          continue;
        //console.warn(ci, ltab);
        var lr = ltab["lookupRec"]; //console.warn(ci, gl, lr);
        for (var i = 0; i < lr.length; i += 2) {
          var cind = lr[i], tab2 = llist[lr[i + 1]];
          //console.warn("-", lr[i+1], tab2);
          applySubs(gls, ci + cind, tab2, llist);
        }
      }
      //else console.warn("Unknown table", tab.ltype, ltab.fmt);
      //*/
    }
  }

  static _glsCovered(gls, cvgs, ci) {
    for (var i = 0; i < cvgs.length; i++) {
      var ind = Typr_LCTF.coverageIndex(cvgs[i], gls[ci + i]);
      if (ind == -1) return false;
    }
    return true;
  }

  static Map<String, dynamic> glyphsToPath(font, gls, clr) {
    //gls = gls.reverse();//gls.slice(0,12).concat(gls.slice(12).reverse());

    Map<String, dynamic> tpath = {"cmds": [], "crds": []};
    num x = 0;

    for (var i = 0; i < gls.length; i++) {
      var gid = gls[i];
      if (gid == -1) continue;
      var gid2 = (i < gls.length - 1 && gls[i + 1] != -1) ? gls[i + 1] : 0;
      var path = glyphToPath(font, gid);
      for (var j = 0; j < path["crds"].length; j += 2) {
        tpath["crds"].add(path["crds"][j] + x);
        tpath["crds"].add(path["crds"][j + 1]);
      }
      if (clr != null) tpath["cmds"].add(clr);
      for (var j = 0; j < path["cmds"].length; j++)
        tpath["cmds"].add(path["cmds"][j]);
      if (clr != null) tpath["cmds"].add("X");
      x += font.hmtx["aWidth"][gid]; // - font.hmtx.lsBearing[gid];
      if (i < gls.length - 1) x += getPairAdjustment(font, gid, gid2);
    }
    return tpath;
  }

  static pathToSVG(path, prec) {
    if (prec == null) prec = 5;
    num co = 0;
    var out = [];
    Map<String, int> lmap = {"M": 2, "L": 2, "Q": 4, "C": 6};
    for (var i = 0; i < path.cmds.length; i++) {
      var cmd = path.cmds[i];
      var cn = co + (lmap[cmd] != null ? lmap[cmd]! : 0);
      out.add(cmd);
      while (co < cn) {
        var c = path.crds[co++];
        out.add(num.parse(c.toFixed(prec)).toString() + (co == cn ? "" : " "));
      }
    }
    return out.join("");
  }

  static pathToContext(path, ctx) {
    var c = 0, crds = path.crds;

    for (var j = 0; j < path.cmds.length; j++) {
      var cmd = path.cmds[j];
      if (cmd == "M") {
        ctx.moveTo(crds[c], crds[c + 1]);
        c += 2;
      } else if (cmd == "L") {
        ctx.lineTo(crds[c], crds[c + 1]);
        c += 2;
      } else if (cmd == "C") {
        ctx.bezierCurveTo(crds[c], crds[c + 1], crds[c + 2], crds[c + 3],
            crds[c + 4], crds[c + 5]);
        c += 6;
      } else if (cmd == "Q") {
        ctx.quadraticCurveTo(crds[c], crds[c + 1], crds[c + 2], crds[c + 3]);
        c += 4;
      } else if (cmd.charAt(0) == "#") {
        ctx.beginPath();
        ctx.fillStyle = cmd;
      } else if (cmd == "Z") {
        ctx.closePath();
      } else if (cmd == "X") {
        ctx.fill();
      }
    }
  }

  static _drawCFF(cmds, Map<String, dynamic> state, font, pdct, p) {
    List stack = state["stack"];

    var nStems = state["nStems"],
        haveWidth = state["haveWidth"],
        width = state["width"],
        open = state["open"];
    num i = 0;
    var x = state["x"], y = state["y"];
    num c1x = 0,
        c1y = 0,
        c2x = 0,
        c2y = 0,
        c3x = 0,
        c3y = 0,
        c4x = 0,
        c4y = 0,
        jpx = 0,
        jpy = 0;

    var nominalWidthX = pdct["nominalWidthX"];
    Map<String, dynamic> o = {"val": 0, "size": 0};
    //console.warn(cmds);

    while (i < cmds.length) {
      Typr_CFF.getCharString(cmds, i, o);

      var v = o["val"];

      int _size = o["size"];
      i += _size;

      if (false) {
      } else if (v == "o1" || v == "o18") {
        //  hstem || hstemhm
        var hasWidthArg;

        // The number of stem operators on the stack is always even.
        // If the value is uneven, that means a width is specified.
        hasWidthArg = stack.length % 2 != 0;
        if (hasWidthArg && !haveWidth) {
          // width = stack.removeAt(0) + nominalWidthX;
          if (nominalWidthX == null) {
            width = null;
            stack.removeAt(0);
          } else {
            width = stack.removeAt(0) + nominalWidthX;
          }
        }

        nStems += stack.length >> 1;
        stack.length = 0;
        haveWidth = true;
      } else if (v == "o3" || v == "o23") {
        // vstem || vstemhm
        var hasWidthArg;

        // The number of stem operators on the stack is always even.
        // If the value is uneven, that means a width is specified.
        hasWidthArg = stack.length % 2 != 0;
        if (hasWidthArg && !haveWidth) {
          // width = stack.removeAt(0) + nominalWidthX;
          if (nominalWidthX == null) {
            width = null;
            stack.removeAt(0);
          } else {
            width = stack.removeAt(0) + nominalWidthX;
          }
        }

        nStems += stack.length >> 1;
        stack.length = 0;
        haveWidth = true;
      } else if (v == "o4") {
        if (stack.length > 1 && !haveWidth) {
          if (nominalWidthX == null) {
            width = null;
            stack.removeAt(0);
          } else {
            width = stack.removeAt(0) + nominalWidthX;
          }

          haveWidth = true;
        }
        if (open) Typr_U_P.closePath(p);

        y += stack.removeLast();
        Typr_U_P.moveTo(p, x, y);
        open = true;
      } else if (v == "o5") {
        while (stack.length > 0) {
          x += stack.removeAt(0);
          y += stack.removeAt(0);
          Typr_U_P.lineTo(p, x, y);
        }
      } else if (v == "o6" || v == "o7") {
        // hlineto || vlineto
        var count = stack.length;
        var isX = (v == "o6");

        for (var j = 0; j < count; j++) {
          var sval = stack.removeAt(0);

          if (isX)
            x += sval;
          else
            y += sval;
          isX = !isX;
          Typr_U_P.lineTo(p, x, y);
        }
      } else if (v == "o8" || v == "o24") {
        // rrcurveto || rcurveline
        var count = stack.length;
        var index = 0;
        while (index + 6 <= count) {
          c1x = x + stack.removeAt(0);
          c1y = y + stack.removeAt(0);
          c2x = c1x + stack.removeAt(0);
          c2y = c1y + stack.removeAt(0);
          x = c2x + stack.removeAt(0);
          y = c2y + stack.removeAt(0);
          Typr_U_P.curveTo(p, c1x, c1y, c2x, c2y, x, y);
          index += 6;
        }
        if (v == "o24") {
          x += stack.removeAt(0);
          y += stack.removeAt(0);
          Typr_U_P.lineTo(p, x, y);
        }
      } else if (v == "o11") {
        break;
      } else if (v == "o1234" ||
          v == "o1235" ||
          v == "o1236" ||
          v == "o1237") //if((v+"").slice(0,3)=="o12")
      {
        if (v == "o1234") {
          c1x = x + stack.removeAt(0); // dx1
          c1y = y; // dy1
          c2x = c1x + stack.removeAt(0); // dx2
          c2y = c1y + stack.removeAt(0); // dy2
          jpx = c2x + stack.removeAt(0); // dx3
          jpy = c2y; // dy3
          c3x = jpx + stack.removeAt(0); // dx4
          c3y = c2y; // dy4
          c4x = c3x + stack.removeAt(0); // dx5
          c4y = y; // dy5
          x = c4x + stack.removeAt(0); // dx6
          Typr_U_P.curveTo(p, c1x, c1y, c2x, c2y, jpx, jpy);
          Typr_U_P.curveTo(p, c3x, c3y, c4x, c4y, x, y);
        }
        if (v == "o1235") {
          c1x = x + stack.removeAt(0); // dx1
          c1y = y + stack.removeAt(0); // dy1
          c2x = c1x + stack.removeAt(0); // dx2
          c2y = c1y + stack.removeAt(0); // dy2
          jpx = c2x + stack.removeAt(0); // dx3
          jpy = c2y + stack.removeAt(0); // dy3
          c3x = jpx + stack.removeAt(0); // dx4
          c3y = jpy + stack.removeAt(0); // dy4
          c4x = c3x + stack.removeAt(0); // dx5
          c4y = c3y + stack.removeAt(0); // dy5
          x = c4x + stack.removeAt(0); // dx6
          y = c4y + stack.removeAt(0); // dy6
          stack.removeAt(0); // flex depth
          Typr_U_P.curveTo(p, c1x, c1y, c2x, c2y, jpx, jpy);
          Typr_U_P.curveTo(p, c3x, c3y, c4x, c4y, x, y);
        }
        if (v == "o1236") {
          c1x = x + stack.removeAt(0); // dx1
          c1y = y + stack.removeAt(0); // dy1
          c2x = c1x + stack.removeAt(0); // dx2
          c2y = c1y + stack.removeAt(0); // dy2
          jpx = c2x + stack.removeAt(0); // dx3
          jpy = c2y; // dy3
          c3x = jpx + stack.removeAt(0); // dx4
          c3y = c2y; // dy4
          c4x = c3x + stack.removeAt(0); // dx5
          c4y = c3y + stack.removeAt(0); // dy5
          x = c4x + stack.removeAt(0); // dx6
          Typr_U_P.curveTo(p, c1x, c1y, c2x, c2y, jpx, jpy);
          Typr_U_P.curveTo(p, c3x, c3y, c4x, c4y, x, y);
        }
        if (v == "o1237") {
          c1x = x + stack.removeAt(0); // dx1
          c1y = y + stack.removeAt(0); // dy1
          c2x = c1x + stack.removeAt(0); // dx2
          c2y = c1y + stack.removeAt(0); // dy2
          jpx = c2x + stack.removeAt(0); // dx3
          jpy = c2y + stack.removeAt(0); // dy3
          c3x = jpx + stack.removeAt(0); // dx4
          c3y = jpy + stack.removeAt(0); // dy4
          c4x = c3x + stack.removeAt(0); // dx5
          c4y = c3y + stack.removeAt(0); // dy5
          if ((c4x - x).abs() > (c4y - y).abs()) {
            x = c4x + stack.removeAt(0);
          } else {
            y = c4y + stack.removeAt(0);
          }
          Typr_U_P.curveTo(p, c1x, c1y, c2x, c2y, jpx, jpy);
          Typr_U_P.curveTo(p, c3x, c3y, c4x, c4y, x, y);
        }
      } else if (v == "o14") {
        if (stack.length > 0 && !haveWidth) {
          if (font["nominalWidthX"] == null) {
            stack.removeAt(0);
            width = null;
          } else {
            width = stack.removeAt(0) + font["nominalWidthX"];
          }

          haveWidth = true;
        }
        if (stack.length == 4) // seac = standard encoding accented character
        {
          var asb = 0;
          var adx = stack.removeAt(0);
          var ady = stack.removeAt(0);
          var bchar = stack.removeAt(0);
          var achar = stack.removeAt(0);

          var bind = Typr_CFF.glyphBySE(font, bchar);
          var aind = Typr_CFF.glyphBySE(font, achar);

          //console.warn(bchar, bind);
          //console.warn(achar, aind);
          //state.x=x; state.y=y; state.nStems=nStems; state.haveWidth=haveWidth; state.width=width;  state.open=open;

          _drawCFF(font.CharStrings[bind], state, font, pdct, p);
          state["x"] = adx;
          state["y"] = ady;
          _drawCFF(font.CharStrings[aind], state, font, pdct, p);

          //x=state.x; y=state.y; nStems=state.nStems; haveWidth=state.haveWidth; width=state.width;  open=state.open;
        }
        if (open) {
          Typr_U_P.closePath(p);
          open = false;
        }
      } else if (v == "o19" || v == "o20") {
        var hasWidthArg;

        // The number of stem operators on the stack is always even.
        // If the value is uneven, that means a width is specified.
        hasWidthArg = stack.length % 2 != 0;
        if (hasWidthArg && !haveWidth) {
          // width = stack.removeAt(0) + nominalWidthX;
          if (nominalWidthX == null) {
            width = null;
            stack.removeAt(0);
          } else {
            width = stack.removeAt(0) + nominalWidthX;
          }
        }

        nStems += stack.length >> 1;
        stack.length = 0;
        haveWidth = true;

        i += (nStems + 7) >> 3;
      } else if (v == "o21") {
        if (stack.length > 2 && !haveWidth) {
          if (nominalWidthX == null) {
            width = null;
            stack.removeAt(0);
          } else {
            width = stack.removeAt(0) + nominalWidthX;
          }

          haveWidth = true;
        }

        y += stack.removeLast();
        x += stack.removeLast();

        if (open) Typr_U_P.closePath(p);
        Typr_U_P.moveTo(p, x, y);
        open = true;
      } else if (v == "o22") {
        if (stack.length > 1 && !haveWidth) {
          // width = stack.removeAt(0) + nominalWidthX;
          if (nominalWidthX == null) {
            width = null;
            stack.removeAt(0);
          } else {
            width = stack.removeAt(0) + nominalWidthX;
          }

          haveWidth = true;
        }

        x += stack.removeLast();

        if (open) Typr_U_P.closePath(p);
        Typr_U_P.moveTo(p, x, y);
        open = true;
      } else if (v == "o25") {
        while (stack.length > 6) {
          x += stack.removeAt(0);
          y += stack.removeAt(0);
          Typr_U_P.lineTo(p, x, y);
        }

        c1x = x + stack.removeAt(0);
        c1y = y + stack.removeAt(0);
        c2x = c1x + stack.removeAt(0);
        c2y = c1y + stack.removeAt(0);
        x = c2x + stack.removeAt(0);
        y = c2y + stack.removeAt(0);
        Typr_U_P.curveTo(p, c1x, c1y, c2x, c2y, x, y);
      } else if (v == "o26") {
        if (stack.length % 2 == 1) {
          x += stack.removeAt(0);
        }

        while (stack.length > 0) {
          c1x = x;
          c1y = y + stack.removeAt(0);
          c2x = c1x + stack.removeAt(0);
          c2y = c1y + stack.removeAt(0);
          x = c2x;
          y = c2y + stack.removeAt(0);
          Typr_U_P.curveTo(p, c1x, c1y, c2x, c2y, x, y);
        }
      } else if (v == "o27") {
        if (stack.length % 2 == 1) {
          y += stack.removeAt(0);
        }

        while (stack.length > 0) {
          c1x = x + stack.removeAt(0);
          c1y = y;
          c2x = c1x + stack.removeAt(0);
          c2y = c1y + stack.removeAt(0);
          x = c2x + stack.removeAt(0);
          y = c2y;
          Typr_U_P.curveTo(p, c1x, c1y, c2x, c2y, x, y);
        }
      } else if (v == "o10" || v == "o29") // callsubr || callgsubr
      {
        var obj = (v == "o10" ? pdct : font);
        if (stack.length == 0) {
          print("error: empty stack");
        } else {
          var ind = stack.removeLast();
          var subr = obj["Subrs"][ind + obj["Bias"]];
          state["x"] = x;
          state["y"] = y;
          state["nStems"] = nStems;
          state["haveWidth"] = haveWidth;
          state["width"] = width;
          state["open"] = open;
          _drawCFF(subr, state, font, pdct, p);
          x = state["x"];
          y = state["y"];
          nStems = state["nStems"];
          haveWidth = state["haveWidth"];
          width = state["width"];
          open = state["open"];
        }
      } else if (v == "o30" || v == "o31") // vhcurveto || hvcurveto
      {
        var count, count1 = stack.length;
        num index = 0;
        var alternate = v == "o31";

        count = count1 & ~2;
        index += count1 - count;

        while (index < count) {
          if (alternate) {
            c1x = x + stack.removeAt(0);
            c1y = y;
            c2x = c1x + stack.removeAt(0);
            c2y = c1y + stack.removeAt(0);
            y = c2y + stack.removeAt(0);
            if (count - index == 5) {
              x = c2x + stack.removeAt(0);
              index++;
            } else
              x = c2x;
            alternate = false;
          } else {
            c1x = x;
            c1y = y + stack.removeAt(0);
            c2x = c1x + stack.removeAt(0);
            c2y = c1y + stack.removeAt(0);
            x = c2x + stack.removeAt(0);
            if (count - index == 5) {
              y = c2y + stack.removeAt(0);
              index++;
            } else
              y = c2y;
            alternate = true;
          }
          Typr_U_P.curveTo(p, c1x, c1y, c2x, c2y, x, y);
          index += 4;
        }
      } else if (v.toString().startsWith("o")) {
        throw ("Unknown operation: ${v} ${cmds}");
      } else {
        stack.add(v);
      }
    }
    //console.warn(cmds);
    state["x"] = x;
    state["y"] = y;
    state["nStems"] = nStems;
    state["haveWidth"] = haveWidth;
    state["width"] = width;
    state["open"] = open;
  }
}

class Typr_U_P {
  static moveTo(p, x, y) {
    p["cmds"].add("M");
    p["crds"].addAll([x, y]);
  }

  static lineTo(p, x, y) {
    p["cmds"].add("L");
    p["crds"].addAll([x, y]);
  }

  static curveTo(p, a, b, c, d, e, f) {
    p["cmds"].add("C");
    p["crds"].addAll([a, b, c, d, e, f]);
  }

  static qcurveTo(p, a, b, c, d) {
    p["cmds"].add("Q");
    p["crds"].addAll([a, b, c, d]);
  }

  static closePath(p) {
    p["cmds"].add("Z");
  }
}
