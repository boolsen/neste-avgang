import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Timer;
import Toybox.WatchUi;

// Page 0: next departure for up to 4 favorites (active-now first, then by rank).
class OverviewView extends WatchUi.View {
    const MAX_ROWS = 4;
    const FETCH = 2;
    const REFRESH_MS = 30000;

    hidden var _order as Array<Number> = [] as Array<Number>;
    hidden var _rows as Array<FavoriteRow> = [] as Array<FavoriteRow>;
    hidden var _fetcher = null;
    hidden var _timer;

    function initialize() {
        View.initialize();
        _timer = new Timer.Timer();
    }

    function onShow() as Void {
        var order = FavoritesStore.displayOrder(TimeUtil.currentHour());
        if (_fetcher != null) {
            _fetcher.cancel();
        }
        _order = [] as Array<Number>;
        _rows = [] as Array<FavoriteRow>;
        for (var i = 0; i < order.size() && i < MAX_ROWS; i++) {
            _order.add(order[i]);
            _rows.add(new FavoriteRow(FavoritesStore.get(order[i]) as Dictionary));
        }
        _fetcher = new RowFetcher(_rows, FETCH, method(:onRowsChanged));
        refresh();
        _timer.stop();
        _timer.start(method(:refresh), REFRESH_MS, true);
    }

    function onHide() as Void {
        if (_fetcher != null) {
            _fetcher.cancel();
        }
        _timer.stop();
    }

    function refresh() as Void {
        _fetcher.start();
        WatchUi.requestUpdate();
    }

    function onRowsChanged() as Void {
        WatchUi.requestUpdate();
    }

    function rowCount() as Number {
        return _rows.size();
    }

    function favoriteIndexAtRow(row as Number) as Number or Null {
        return (row >= 0 && row < _order.size()) ? _order[row] as Number : null;
    }

    function openFavorite(i as Number) as Void {
        Pages.showFavorite(i, WatchUi.SLIDE_IMMEDIATE);
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        if (_rows.size() == 0) {
            dc.drawText(w / 2, h / 2, Graphics.FONT_SMALL, Fmt.str(Rez.Strings.AddFavorite), center);
            return;
        }
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.18, Graphics.FONT_XTINY, Fmt.str(Rez.Strings.Overview), center);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var now = Time.now().value();
        var font = Graphics.FONT_TINY;
        for (var i = 0; i < _rows.size(); i++) {
            var text = Graphics.fitTextToArea((_rows[i] as FavoriteRow).text(now), font,
                OverviewLayout.rowWidth(i, w, h), dc.getFontHeight(font), true);
            dc.drawText(w / 2, OverviewLayout.rowY(i, h), font, text, center);
        }
    }
}
