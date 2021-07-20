part of typr_dart;


var friendlyTags = { "aalt": "Access All Alternates", "abvf": "Above-base Forms", "abvm": "Above - base Mark Positioning", "abvs": "Above - base Substitutions", "afrc": "Alternative Fractions", "akhn": "Akhands", "blwf": "Below - base Forms", "blwm": "Below - base Mark Positioning", "blws": "Below - base Substitutions", "calt": "Contextual Alternates", "case": "Case - Sensitive Forms", "ccmp": "Glyph Composition / Decomposition", "cfar": "Conjunct Form After Ro", "cjct": "Conjunct Forms", "clig": "Contextual Ligatures", "cpct": "Centered CJK Punctuation", "cpsp": "Capital Spacing", "cswh": "Contextual Swash", "curs": "Cursive Positioning", "c2pc": "Petite Capitals From Capitals", "c2sc": "Small Capitals From Capitals", "dist": "Distances", "dlig": "Discretionary Ligatures", "dnom": "Denominators", "dtls": "Dotless Forms", "expt": "Expert Forms", "falt": "Final Glyph on Line Alternates", "fin2": "Terminal Forms #2", "fin3": "Terminal Forms #3", "fina": "Terminal Forms", "flac": "Flattened accent forms", "frac": "Fractions", "fwid": "Full Widths", "half": "Half Forms", "haln": "Halant Forms", "halt": "Alternate Half Widths", "hist": "Historical Forms", "hkna": "Horizontal Kana Alternates", "hlig": "Historical Ligatures", "hngl": "Hangul", "hojo": "Hojo Kanji Forms(JIS X 0212 - 1990 Kanji Forms)", "hwid": "Half Widths", "init": "Initial Forms", "isol": "Isolated Forms", "ital": "Italics", "jalt": "Justification Alternates", "jp78": "JIS78 Forms", "jp83": "JIS83 Forms", "jp90": "JIS90 Forms", "jp04": "JIS2004 Forms", "kern": "Kerning", "lfbd": "Left Bounds", "liga": "Standard Ligatures", "ljmo": "Leading Jamo Forms", "lnum": "Lining Figures", "locl": "Localized Forms", "ltra": "Left - to - right alternates", "ltrm": "Left - to - right mirrored forms", "mark": "Mark Positioning", "med2": "Medial Forms #2", "medi": "Medial Forms", "mgrk": "Mathematical Greek", "mkmk": "Mark to Mark Positioning", "mset": "Mark Positioning via Substitution", "nalt": "Alternate Annotation Forms", "nlck": "NLC Kanji Forms", "nukt": "Nukta Forms", "numr": "Numerators", "onum": "Oldstyle Figures", "opbd": "Optical Bounds", "ordn": "Ordinals", "ornm": "Ornaments", "palt": "Proportional Alternate Widths", "pcap": "Petite Capitals", "pkna": "Proportional Kana", "pnum": "Proportional Figures", "pref": "Pre - Base Forms", "pres": "Pre - base Substitutions", "pstf": "Post - base Forms", "psts": "Post - base Substitutions", "pwid": "Proportional Widths", "qwid": "Quarter Widths", "rand": "Randomize", "rclt": "Required Contextual Alternates", "rkrf": "Rakar Forms", "rlig": "Required Ligatures", "rphf": "Reph Forms", "rtbd": "Right Bounds", "rtla": "Right - to - left alternates", "rtlm": "Right - to - left mirrored forms", "ruby": "Ruby Notation Forms", "rvrn": "Required Variation Alternates", "salt": "Stylistic Alternates", "sinf": "Scientific Inferiors", "size": "Optical size", "smcp": "Small Capitals", "smpl": "Simplified Forms", "ssty": "Math script style alternates", "stch": "Stretching Glyph Decomposition", "subs": "Subscript", "sups": "Superscript", "swsh": "Swash", "titl": "Titling", "tjmo": "Trailing Jamo Forms", "tnam": "Traditional Name Forms", "tnum": "Tabular Figures", "trad": "Traditional Forms", "twid": "Third Widths", "unic": "Unicase", "valt": "Alternate Vertical Metrics", "vatu": "Vattu Variants", "vert": "Vertical Writing", "vhal": "Alternate Vertical Half Metrics", "vjmo": "Vowel Jamo Forms", "vkna": "Vertical Kana Alternates", "vkrn": "Vertical Kerning", "vpal": "Proportional Alternate Vertical Metrics", "vrt2": "Vertical Alternates and Rotation", "vrtr": "Vertical Alternates for Rotation", "zero": "Slashed Zero" };


class Font {
  late Map<String, dynamic> enabledGSUB;
  late dynamic fontObj;

  get _data => fontObj["_data"];
  get _offset => fontObj["_offset"];
  get cmap => fontObj["cmap"];
  get head => fontObj["head"];
  get hhea => fontObj["hhea"];
  get maxp => fontObj["maxp"];
  get hmtx => fontObj["hmtx"];
  get name => fontObj["name"];
  get OS2 => fontObj["OS/2"];
  get post => fontObj["post"];
  get CFF => fontObj["CFF"];
  get GSUB => fontObj["GSUB"];
  get SVG => fontObj["SVG"];
  get glyf => fontObj["glyf"];
  get loca => fontObj["loca"];
  get GPOS => fontObj["GPOS"];
  get kern => fontObj["kern"];

	Font(Uint8List data) {
		var obj = Typr.parse(data);
		// Only support for one font (obj[0])
		if (obj.length == 0) {
			throw "unable to parse font";
		}
		// for (var n in obj[0]) {
		// 	this[n] = obj[0][n];
		// }
    fontObj = obj[0];
		this.enabledGSUB = {};
	}
	getFamilyName() {
		return this.name != null ? (this.name["typoFamilyName"] ?? this.name["fontFamily"]) : "";
	}
	getSubFamilyName() {
		return this.name != null ? (this.name["typoSubfamilyName"] ?? this.name["fontSubfamily"]) : "";
	}
  getFullName() {
    return this.name["fullName"];
  }
	glyphToPath(num gid) {
		return Typr_U.glyphToPath(this, gid);
	}
	getPairAdjustment(num gid1, num gid2) {
		return Typr_U.getPairAdjustment(this, gid1, gid2);
	}
	stringToGlyphs(String str) {
		return Typr_U.stringToGlyphs(this, str);
	}
	glyphsToPath(List<int> gls) {
		return Typr_U.glyphsToPath(this, gls, null);
	}
	pathToSVG(path, num? prec) {
		return Typr_U.pathToSVG(path, prec);
	}
	pathToContext(path, ctx) {
		return Typr_U.pathToContext(path, ctx);
	}

	/*** Additional features ***/

	lookupFriendlyName(String table, num feature) {
		if (this.getTable(table) != null) {
			var tbl = this.getTable(table);
			var feat = tbl.featureList[feature];
			return this.featureFriendlyName(feat);
		}
		return "";
	}

  getTable(String table) {
    if(table == "") {

    } else {
      throw(" Font.dart getTable ${table} ");
    }
  }


	featureFriendlyName(feature) {
		if (friendlyTags[feature.tag] != null) {
			return friendlyTags[feature.tag];
		}


		if ( RegExp("ss[0-2][0-9]").hasMatch(feature.tag) ) {
			var name = "Stylistic Set " + num.parse(feature.tag.substr(2, 2)).toString();
			if (feature.featureParams) {
				var version = TyprBin.readUshort(this._data, feature.featureParams);
				if (version == 0) {
					var nameID = TyprBin.readUshort(this._data, feature.featureParams + 2);
					if (this.name && this.name[nameID] != null) {
						return name + " - " + this.name[nameID];
					}
				}
			}
			return name;
		}

    RegExp _reg = RegExp("cv[0-9][0-9]");

		if ( _reg.hasMatch(feature.tag) ) {
			return "Character Variant " + num.parse(feature.tag.substr(2, 2)).toString();
		}
		return "";
	}

	// enabledGSUB: { [key: number]: number };
	enableGSUB(featureNumber) {
		if (this.GSUB) {
			var feature = this.GSUB.featureList[featureNumber];
			if (feature) {
				for (var i = 0; i < feature.tab.length; ++i) {
					this.enabledGSUB[feature.tab[i]] = (this.enabledGSUB[feature.tab[i]] ?? 0) + 1;
				}
			}
		}
	}
	disableGSUB(featureNumber) {
		if (this.GSUB) {
			var feature = this.GSUB.featureList[featureNumber];
			if (feature) {
				for (var i = 0; i < feature.tab.length; ++i) {
					if (this.enabledGSUB[feature.tab[i]] > 1) {
						--this.enabledGSUB[feature.tab[i]];
					} else {
						this.enabledGSUB.remove(feature.tab[i]);
					}
				}
			}
		}
	}
	codeToGlyph(code) {
		var g = Typr_U.codeToGlyph(this, code);
		if (this.GSUB) {
			var gls = [g];
			for (var n in this.enabledGSUB.keys) {
				var l = this.GSUB.lookupList[n];
				Typr_U.applySubs(gls, 0, l, this.GSUB.lookupList);
			}
			if (gls.length == 1) return gls[0];
		}
		return g;
	}

}