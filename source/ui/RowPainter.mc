import Toybox.Graphics;
import Toybox.Lang;

// Draws one row: time/status (white, left, never cut) + info text (grey) clipped to the rest,
// scrolled by Ticker when it doesn't fit. Returns true when the info text overflows.
(:glance)
module RowPainter {
    const GAP_PX = 8;

    function draw(dc as Graphics.Dc, x as Number, y as Number, width as Number, font as Graphics.FontType,
            row as FavoriteRow, now as Number, elapsedMs as Number) as Boolean {
        var vcenter = Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER;
        var status = row.status(now);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, status, vcenter);

        var infoX = x + dc.getTextWidthInPixels(status, font) + GAP_PX;
        var infoW = x + width - infoX;
        if (infoW <= 0) {
            return false;
        }
        var info = row.info();
        var overflow = dc.getTextWidthInPixels(info, font) - infoW;
        var fh = dc.getFontHeight(font);
        dc.setClip(infoX, y - fh / 2, infoW, fh);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(infoX - Ticker.offset(elapsedMs, overflow), y, font, info, vcenter);
        dc.clearClip();
        return overflow > 0;
    }
}
