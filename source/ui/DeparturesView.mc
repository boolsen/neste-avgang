import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Timer;
import Toybox.WatchUi;

class DeparturesView extends WatchUi.View {
    const SHOWN = 3;
    const FETCH = 4;           // one extra so a departure passing between refreshes doesn't leave a gap
    const REFRESH_MS = 30000;

    var index as Number = 0;
    hidden var _deps = null;
    hidden var _error = null;
    hidden var _code = 0;
    hidden var _updated = null;
    hidden var _loading = false;
    hidden var _refreshTimer;
    hidden var _startTimer;
    hidden var _autoAddStarted = false;

    function initialize() {
        View.initialize();
        _refreshTimer = new Timer.Timer();
        _startTimer = new Timer.Timer();
    }

    function onShow() as Void {
        if (FavoritesStore.count() == 0 && !_autoAddStarted) {
            _autoAddStarted = true;
            // Defer: pushing a view from inside onShow is not safe.
            _startTimer.start(method(:startAddFlow), 100, false);
        }
        refresh();
        _refreshTimer.start(method(:refresh), REFRESH_MS, true);
    }

    function startAddFlow() as Void {
        new AddFavoriteFlow(method(:showIndex)).start();
    }

    function onHide() as Void {
        _refreshTimer.stop();
    }

    function showIndex(i as Number) as Void {
        var n = FavoritesStore.count();
        index = (n == 0) ? 0 : ((i % n) + n) % n;
        _deps = null;
        _error = null;
        _updated = null;
        refresh();
    }

    function refresh() as Void {
        var fav = FavoritesStore.get(index);
        if (fav == null) {
            WatchUi.requestUpdate();
            return;
        }
        if (_deps == null) {
            var cached = DepartureCache.get(fav);
            if (cached != null) {
                _deps = cached["d"];
                _updated = cached["t"];
            }
        }
        _loading = true;
        new DepartureService(fav, method(:onResult)).send(FETCH);
        WatchUi.requestUpdate();
    }

    function onResult(fav as Dictionary, deps as Array or Null, error as Number or Null, code as Number) as Void {
        var current = FavoritesStore.get(index);
        if (current == null || !Model.sameFavorite(current, fav)) {
            return; // stale response for a favorite we've swiped away from
        }
        _loading = false;
        _error = error;
        _code = code;
        if (deps != null) {
            _deps = deps;
            _updated = Time.now().value();
        }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var fav = FavoritesStore.get(index);
        if (fav == null) {
            dc.drawText(cx, h / 2, Graphics.FONT_SMALL, Fmt.str(Rez.Strings.AddFavorite), center);
            return;
        }

        dc.drawText(cx, h * 0.17, Graphics.FONT_SMALL, fav["label"] as String, center);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.27, Graphics.FONT_XTINY, fav["stopName"] as String, center);

        var now = Time.now().value();
        var shown = (_deps == null) ? [] : Model.upcoming(_deps, now, SHOWN);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < shown.size(); i++) {
            var d = shown[i];
            var text = Fmt.minutes(TimeUtil.minutesUntil(d["epoch"] as Number, now), d["rt"] as Boolean)
                + "  " + d["dest"];
            dc.drawText(cx, h * (0.42 + 0.12 * i), Graphics.FONT_SMALL, text, center);
        }

        var status = null;
        if (_error != null) {
            status = ServiceError.message(_error, _code);
        } else if (_loading && shown.size() == 0) {
            status = Fmt.str(Rez.Strings.Loading);
        }
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        if (status != null) {
            dc.drawText(cx, h * 0.79, Graphics.FONT_XTINY, status, center);
        }
        if (_updated != null) {
            dc.drawText(cx, h * 0.88, Graphics.FONT_XTINY,
                Lang.format(Fmt.str(Rez.Strings.UpdatedFmt), [Fmt.clock(_updated)]), center);
        }
    }
}
