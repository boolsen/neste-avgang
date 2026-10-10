import Toybox.Lang;

// One favorite's one-line state for multi-row screens (glance, overview).
(:glance)
class FavoriteRow {
    var fav as Dictionary;
    hidden var _deps = null;
    hidden var _error = null;
    hidden var _code = 0;

    function initialize(f as Dictionary) {
        fav = f;
        var cached = DepartureCache.get(f);
        if (cached != null) {
            _deps = cached["d"];
        }
    }

    function apply(deps as Array or Null, error as Number or Null, code as Number) as Void {
        _error = error;
        _code = code;
        if (deps != null) {
            _deps = deps;
        }
    }

    function title() as String {
        return (fav["lineCode"] as String) + " " + (fav["stopName"] as String);
    }

    function status(now as Number) as String {
        var next = ((_deps == null) ? [] : Model.upcoming(_deps as Array, now, 1)) as Array;
        if (next.size() > 0) {
            var d = next[0] as Dictionary;
            return Fmt.minutes(TimeUtil.minutesUntil(d["epoch"] as Number, now), d["rt"] as Boolean);
        }
        if (_error != null) {
            return ServiceError.message(_error as Number, _code);
        }
        return Fmt.str(Rez.Strings.Loading);
    }

    function text(now as Number) as String {
        return title() + ": " + status(now);
    }
}
