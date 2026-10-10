import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

// Glance: first favorite + next departure. Shows cached data immediately, then live.
(:glance)
class BusGlanceView extends WatchUi.GlanceView {
    hidden var _fav = null;
    hidden var _deps = null;
    hidden var _error = null;
    hidden var _code = 0;

    function initialize() {
        GlanceView.initialize();
    }

    function onShow() as Void {
        _fav = FavoritesStore.get(0);
        _deps = null;
        _error = null;
        _code = 0;
        if (_fav == null) {
            return;
        }
        var cached = DepartureCache.get(_fav);
        if (cached != null) {
            _deps = cached["d"];
        }
        new DepartureService(_fav, method(:onResult)).send(2);
    }

    function onResult(fav as Dictionary, deps as Array or Null, error as Number or Null, code as Number) as Void {
        if (_fav == null || !Model.sameFavorite(fav, _fav)) {
            return;
        }
        _error = error;
        _code = code;
        if (deps != null) {
            _deps = deps;
        }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var left = Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER;
        var h = dc.getHeight();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        if (_fav == null) {
            dc.drawText(0, h / 2, Graphics.FONT_TINY, Fmt.str(Rez.Strings.AddFavorite), left);
            return;
        }
        dc.drawText(0, h * 0.3, Graphics.FONT_TINY, _fav["label"] as String, left);
        dc.drawText(0, h * 0.72, Graphics.FONT_XTINY, _fav["stopName"] + ": " + status(), left);
    }

    hidden function status() as String {
        var now = Time.now().value();
        var next = ((_deps == null) ? [] : Model.upcoming(_deps, now, 1)) as Array;
        if (next.size() > 0) {
            return Fmt.minutes(TimeUtil.minutesUntil(next[0]["epoch"] as Number, now), next[0]["rt"] as Boolean);
        }
        if (_error != null) {
            return ServiceError.message(_error, _code);
        }
        return Fmt.str(Rez.Strings.Loading);
    }
}
