import Toybox.Lang;
import Toybox.Test;

(:test)
function testOverviewRowAt(logger as Logger) as Boolean {
    var h = 454;
    // row i is centred at h*(0.34 + 0.14*i) and spans +/- 0.07*h
    return Check.eq(logger, "above first", OverviewLayout.rowAt(100, h, 4), null)       // 0.22h
        && Check.eq(logger, "row0", OverviewLayout.rowAt(OverviewLayout.rowY(0, h), h, 4), 0)
        && Check.eq(logger, "row1", OverviewLayout.rowAt(OverviewLayout.rowY(1, h), h, 4), 1)
        && Check.eq(logger, "row3", OverviewLayout.rowAt(OverviewLayout.rowY(3, h), h, 4), 3)
        && Check.eq(logger, "beyond rows", OverviewLayout.rowAt(OverviewLayout.rowY(2, h), h, 2), null)
        && Check.eq(logger, "below", OverviewLayout.rowAt(h - 1, h, 4), null);
}

(:test)
function testOverviewRowWidthFitsCircle(logger as Logger) as Boolean {
    var w = 454;
    var h = 454;
    var mid = OverviewLayout.rowWidth(1, w, h);   // y = 0.48h, near the centre
    var top = OverviewLayout.rowWidth(0, w, h);   // y = 0.34h
    return Check.eq(logger, "mid wider than top", mid > top, true)
        && Check.eq(logger, "mid below 90% width", mid <= (w * 0.9).toNumber(), true);
}

(:test)
function testChordWidthAtY(logger as Logger) as Boolean {
    var w = 454;
    var h = 454;
    return Check.eq(logger, "centre = 90% width", OverviewLayout.chordWidth(227, w, h), (w * 0.9).toNumber())
        && Check.eq(logger, "near top narrower", OverviewLayout.chordWidth(77, w, h) < OverviewLayout.chordWidth(190, w, h), true)
        && Check.eq(logger, "same as row", OverviewLayout.chordWidth(OverviewLayout.rowY(0, h), w, h), OverviewLayout.rowWidth(0, w, h));
}
