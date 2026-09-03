/* Minimal Mapbox Vector Tile reader — just enough of protobuf to pull
   polygon footprints out of OSM's shortbread tiles. No dependencies. */
(function (global) {
"use strict";

function Reader(buf) { this.b = buf; this.p = 0; this.end = buf.length; }

Reader.prototype.varint = function () {
  var r = 0, s = 0, b;
  do { b = this.b[this.p++]; r += (b & 0x7f) * Math.pow(2, s); s += 7; } while (b >= 0x80);
  return r;
};
Reader.prototype.bytes = function () {
  var n = this.varint(), s = this.p;
  this.p += n;
  return this.b.subarray(s, this.p);
};
Reader.prototype.skip = function (wire) {
  if (wire === 0) this.varint();
  else if (wire === 1) this.p += 8;
  else if (wire === 2) this.p += this.varint();
  else if (wire === 5) this.p += 4;
  else throw new Error("bad wire type " + wire);
};
Reader.prototype.str = function () {
  var b = this.bytes();
  var s = "";
  for (var i = 0; i < b.length; i++) s += String.fromCharCode(b[i]);
  return decodeURIComponent(escape(s));
};
Reader.prototype.packed = function () {
  var b = this.bytes(), r = new Reader(b), out = [];
  while (r.p < r.end) out.push(r.varint());
  return out;
};

function eachField(reader, fn) {
  while (reader.p < reader.end) {
    var key = reader.varint(), tag = key >> 3, wire = key & 7;
    var before = reader.p;
    if (!fn(tag, wire, reader)) reader.skip(wire);
    if (reader.p === before) reader.skip(wire);
  }
}

function readValue(buf) {
  var r = new Reader(buf), v = null;
  eachField(r, function (tag, wire, rr) {
    if (tag === 1) { v = rr.str(); return true; }
    if (tag === 4 || tag === 5) { v = rr.varint(); return true; }
    if (tag === 6) { var n = rr.varint(); v = (n >>> 1) ^ (-(n & 1)); return true; }
    if (tag === 7) { v = rr.varint() !== 0; return true; }
    return false;
  });
  return v;
}

// command-encoded geometry -> array of rings, each [x,y,...] in tile units
function decodeGeometry(g) {
  var rings = [], cur = null, x = 0, y = 0, i = 0;
  while (i < g.length) {
    var cmd = g[i] & 0x7, count = g[i] >> 3;
    i++;
    if (cmd === 1) {                       // MoveTo
      for (var m = 0; m < count; m++) {
        x += (g[i] >>> 1) ^ (-(g[i] & 1)); i++;
        y += (g[i] >>> 1) ^ (-(g[i] & 1)); i++;
        if (cur && cur.length >= 4) rings.push(cur);
        cur = [x, y];
      }
    } else if (cmd === 2) {                // LineTo
      for (var l = 0; l < count; l++) {
        x += (g[i] >>> 1) ^ (-(g[i] & 1)); i++;
        y += (g[i] >>> 1) ^ (-(g[i] & 1)); i++;
        if (cur) cur.push(x, y);
      }
    } else if (cmd === 7) {                // ClosePath
      if (cur && cur.length >= 4) { rings.push(cur); cur = null; }
    }
  }
  if (cur && cur.length >= 4) rings.push(cur);
  return rings;
}

function ringArea(r) {                      // shoelace, tile coords are y-down
  var a = 0;
  for (var i = 0, n = r.length / 2; i < n; i++) {
    var j = (i + 1) % n;
    a += r[i * 2] * r[j * 2 + 1] - r[j * 2] * r[i * 2 + 1];
  }
  return a / 2;
}

// returns { layerName: { extent, keys:[], features:[{props,rings,type}] } }
function readTile(buf) {
  var out = {};
  eachField(new Reader(buf), function (tag, wire, r) {
    if (tag !== 3) return false;
    var lbuf = r.bytes();
    var name = null, extent = 4096, keys = [], values = [], feats = [];
    eachField(new Reader(lbuf), function (t2, w2, r2) {
      if (t2 === 1) { name = r2.str(); return true; }
      if (t2 === 3) { keys.push(r2.str()); return true; }
      if (t2 === 4) { values.push(readValue(r2.bytes())); return true; }
      if (t2 === 5) { extent = r2.varint(); return true; }
      if (t2 === 2) { feats.push(r2.bytes()); return true; }
      return false;
    });
    var features = [];
    for (var f = 0; f < feats.length; f++) {
      var tags = [], geom = [], gtype = 0;
      eachField(new Reader(feats[f]), function (t3, w3, r3) {
        if (t3 === 2) { tags = r3.packed(); return true; }
        if (t3 === 3) { gtype = r3.varint(); return true; }
        if (t3 === 4) { geom = r3.packed(); return true; }
        return false;
      });
      var props = {};
      for (var k = 0; k + 1 < tags.length; k += 2) props[keys[tags[k]]] = values[tags[k + 1]];
      features.push({ props: props, type: gtype, rings: decodeGeometry(geom) });
    }
    out[name] = { extent: extent, keys: keys, features: features };
    return true;
  });
  return out;
}

global.MVT = { readTile: readTile, ringArea: ringArea };

})(this);
