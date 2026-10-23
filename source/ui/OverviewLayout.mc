import Toybox.Lang;
import Toybox.Math;

// Row geometry for the overview page; shared by drawing and tap handling.
module OverviewLayout {
    const ROW_Y0 = 0.34;   // centre of row 0, as a fraction of height
    const ROW_DY = 0.14;   // row pitch, as a fraction of height

    function rowY(i as Number, h as Number) as Number {
        return (h * (ROW_Y0 + ROW_DY * i)).toNumber();
    }

    // Row index under y, or null when outside the first `rows` rows.
    function rowAt(y as Number, h as Number, rows as Number) as Number or Null {
        var f = (y.toFloat() / h - (ROW_Y0 - ROW_DY / 2)) / ROW_DY;
        if (f < 0) {
            return null;
        }
        var r = f.toNumber();
        return (r < rows) ? r : null;
    }

    // Usable text width for row i on a round screen (90% of the chord at that height).
    function rowWidth(i as Number, w as Number, h as Number) as Number {
        return chordWidth(rowY(i, h), w, h);
    }

    // Usable text width at height y on a round screen (90% of the chord there).
    function chordWidth(y as Number, w as Number, h as Number) as Number {
        var r = h / 2.0;
        var dy = y - r;
        var half = Math.sqrt(r * r - dy * dy);
        var chord = 2 * half * 0.9;
        return (chord < w * 0.9 ? chord : w * 0.9).toNumber();
    }
}
