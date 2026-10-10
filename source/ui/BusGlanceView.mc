import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Timer;
import Toybox.WatchUi;

// Glance: up to two favorites (active-now first, then by rank). Cached data first, then live, one fetch at a time.
(:glance)
class BusGlanceView extends WatchUi.GlanceView {
    const MAX_ROWS = 2;
    const FETCH = 2;
    const FRAME_MS = 150;

    hidden var _rows as Array = [];
    hidden var _fetcher = null;
    hidden var _animTimer = null;
    hidden var _animating = false;
    hidden var _overflow = false;
    hidden var _startMs = 0;

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
        _startMs = System.getTimer();
    }

    function onHide() as Void {
        if (_fetcher != null) {
            _fetcher.cancel();
        }
        stopAnimation();
    }

    function onRowsChanged() as Void {
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        if (_rows.size() == 0) {
            dc.drawText(0, h / 2, Graphics.FONT_TINY, Fmt.str(Rez.Strings.AddFavorite),
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }
        var now = Time.now().value();
        var elapsed = System.getTimer() - _startMs;
        var font = Graphics.FONT_XTINY;
        var overflow = false;
        if (_rows.size() == 1) {
            overflow = RowPainter.draw(dc, 0, h / 2, w, font, _rows[0] as FavoriteRow, now, elapsed);
        } else {
            overflow = RowPainter.draw(dc, 0, (h * 0.3).toNumber(), w, font, _rows[0] as FavoriteRow, now, elapsed);
            overflow = RowPainter.draw(dc, 0, (h * 0.72).toNumber(), w, font, _rows[1] as FavoriteRow, now, elapsed) || overflow;
        }
        _overflow = overflow;
        if (_overflow && !_animating) {
            startAnimation();
        }
    }

    function onFrame() as Void {
        if (!_overflow) {
            stopAnimation();
            return;
        }
        WatchUi.requestUpdate();
    }

    hidden function startAnimation() as Void {
        if (_animTimer == null) {
            _animTimer = new Timer.Timer();
        }
        _animTimer.start(method(:onFrame), FRAME_MS, true);
        _animating = true;
    }

    hidden function stopAnimation() as Void {
        if (_animTimer != null) {
            _animTimer.stop();
        }
        _animating = false;
    }
}
