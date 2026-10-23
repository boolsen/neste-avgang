import Toybox.Graphics;
import Toybox.Lang;

// Draws one row: time/status (white, left, never cut) + info text (grey) clipped to the rest,
// scrolled by Ticker when it doesn't fit. Returns true when the info text overflows.
(:glance)
module RowPainter {
    const GAP_PX = 8;

    function draw(dc as Graphics.Dc, x as Number, y as Number, width as Number, font as Graphics.FontType,
            row as FavoriteRow, now as Number, elapsedMs as Number) as Boolean {
        return drawParts(dc, x, y, width, font, row.status(now), row.info(), elapsedMs, false);
    }

    // As draw(), but with plain texts; `centred` centres the row in `width` when it fits.
    function drawParts(dc as Graphics.Dc, x as Number, y as Number, width as Number, font as Graphics.FontType,
            status as String, info as String, elapsedMs as Number, centred as Boolean) as Boolean {
        var statusW = dc.getTextWidthInPixels(status, font);
        var gap = (info.length() > 0) ? GAP_PX : 0;
        var free = width - statusW - gap - dc.getTextWidthInPixels(info, font);
        if (centred && free > 0) {
            x += free / 2;
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, status, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        var infoX = x + statusW + gap;
        var infoW = x + width - infoX;
        if (infoW <= 0 || info.length() == 0) {
            return false;
        }
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        return scroll(dc, infoX, y, infoW, font, info, elapsedMs);
    }

    // One line in the current colour: centred in `width` when it fits, otherwise scrolled by Ticker.
    function drawLine(dc as Graphics.Dc, x as Number, y as Number, width as Number, font as Graphics.FontType,
            text as String, elapsedMs as Number) as Boolean {
        if (dc.getTextWidthInPixels(text, font) <= width) {
            dc.drawText(x + width / 2, y, font, text, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return false;
        }
        return scroll(dc, x, y, width, font, text, elapsedMs);
    }

    function scroll(dc as Graphics.Dc, x as Number, y as Number, width as Number, font as Graphics.FontType,
            text as String, elapsedMs as Number) as Boolean {
        var overflow = dc.getTextWidthInPixels(text, font) - width;
        var fh = dc.getFontHeight(font);
        dc.setClip(x, y - fh / 2, width, fh);
        dc.drawText(x - Ticker.offset(elapsedMs, overflow), y, font, text,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.clearClip();
        return overflow > 0;
    }
}
