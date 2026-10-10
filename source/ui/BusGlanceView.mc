import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

// Glance: up to two favorites (active-now first, then by rank). Cached data first, then live, one fetch at a time.
(:glance)
class BusGlanceView extends WatchUi.GlanceView {
    const MAX_ROWS = 2;
    const FETCH = 2;

    hidden var _rows as Array = [];
    hidden var _fetcher = null;

    function initialize() {
        GlanceView.initialize();
    }

    function onShow() as Void {
        if (_fetcher != null) {
            _fetcher.cancel();
        }
        var order = FavoritesStore.displayOrder(TimeUtil.currentHour());
        _rows = [];
        for (var i = 0; i < order.size() && i < MAX_ROWS; i++) {
            _rows.add(new FavoriteRow(FavoritesStore.get(order[i]) as Dictionary));
        }
        _fetcher = new RowFetcher(_rows, FETCH, method(:onRowsChanged));
        _fetcher.start();
    }

    function onHide() as Void {
        if (_fetcher != null) {
            _fetcher.cancel();
        }
    }

    function onRowsChanged() as Void {
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var left = Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER;
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        if (_rows.size() == 0) {
            dc.drawText(0, h / 2, Graphics.FONT_TINY, Fmt.str(Rez.Strings.AddFavorite), left);
            return;
        }
        var now = Time.now().value();
        var first = _rows[0] as FavoriteRow;
        if (_rows.size() == 1) {
            dc.drawText(0, h * 0.3, Graphics.FONT_TINY, first.fav["label"] as String, left);
            drawFitted(dc, h * 0.72, (first.fav["stopName"] as String) + ": " + first.status(now), w);
            return;
        }
        drawFitted(dc, h * 0.3, first.text(now), w);
        drawFitted(dc, h * 0.72, (_rows[1] as FavoriteRow).text(now), w);
    }

    hidden function drawFitted(dc as Graphics.Dc, y as Numeric, text as String, w as Number) as Void {
        var font = Graphics.FONT_XTINY;
        var fitted = Graphics.fitTextToArea(text, font, w, dc.getFontHeight(font), true);
        dc.drawText(0, y, font, fitted, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
