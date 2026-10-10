import Toybox.Lang;
import Toybox.Position;
import Toybox.Timer;
import Toybox.WatchUi;

// GPS -> nearby stops -> (quay, line) options -> save favorite.
// Occupies one view-stack slot above DeparturesView; steps replace each other with switchToView.
// Back from any step returns to DeparturesView.
class AddFavoriteFlow {
    const GPS_TIMEOUT_MS = 30000;

    hidden var _provider;
    hidden var _onSaved as Method;
    hidden var _status as StatusView or Null = null;
    hidden var _onStatus = false;   // true while a StatusView (not a menu) is the flow's current screen
    hidden var _timer;
    hidden var _stops = [];
    hidden var _options = [];
    hidden var _stop = null;
    hidden var _cancelled = false;

    // onSaved: (index as Number) as Void
    function initialize(onSaved as Method) {
        _provider = ProviderRegistry.get(ProviderRegistry.DEFAULT_ID);
        _onSaved = onSaved;
        _timer = new Timer.Timer();
    }

    function start() as Void {
        _status = new StatusView(Fmt.str(Rez.Strings.FindingPosition));
        WatchUi.pushView(_status, new StatusDelegate(_status, method(:cancel)), WatchUi.SLIDE_LEFT);
        _onStatus = true;
        requestPosition();
    }

    // Called on Back from any flow screen: stop GPS/timer and ignore late callbacks.
    function cancel() as Void {
        _cancelled = true;
        _timer.stop();
        Position.enableLocationEvents(Position.LOCATION_DISABLE, null);
    }

    function requestPosition() as Void {
        showStatus(Fmt.str(Rez.Strings.FindingPosition));
        _timer.stop();
        _timer.start(method(:onPositionTimeout), GPS_TIMEOUT_MS, false);
        Position.enableLocationEvents(Position.LOCATION_ONE_SHOT, method(:onPosition));
    }

    function onPosition(info as Position.Info) as Void {
        if (_cancelled) {
            return;
        }
        _timer.stop();
        if (info.position == null) {
            onPositionTimeout();
            return;
        }
        var deg = info.position.toDegrees();
        showStatus(Fmt.str(Rez.Strings.Loading));
        Net.send(_provider.buildNearbyStopsRequest(deg[0], deg[1]), method(:onNearby));
    }

    function onPositionTimeout() as Void {
        if (_cancelled) {
            return;
        }
        Position.enableLocationEvents(Position.LOCATION_DISABLE, null);
        _status.setError(Fmt.str(Rez.Strings.NoPosition), method(:requestPosition));
    }

    function onNearby(code as Number, data) as Void {
        if (_cancelled) {
            return;
        }
        if (failed(code, method(:requestPosition))) {
            return;
        }
        var stops = _provider.parseNearbyStops(data);
        if (stops == null) {
            _status.setError(Fmt.str(Rez.Strings.ParseError), method(:requestPosition));
            return;
        }
        if (stops.size() == 0) {
            _status.setError(Fmt.str(Rez.Strings.NoStopsNearby), method(:requestPosition));
            return;
        }
        _stops = stops;
        var menu = new WatchUi.Menu2({:title => Fmt.str(Rez.Strings.NearbyStops)});
        for (var i = 0; i < stops.size(); i++) {
            var s = (stops as Array<Dictionary>)[i];
            menu.addItem(new WatchUi.MenuItem(s["name"] as String,
                Lang.format(Fmt.str(Rez.Strings.DistanceFmt), [s["dist"]]), i, null));
        }
        WatchUi.switchToView(menu, new IndexMenuDelegate(method(:onStopChosen), method(:cancel)), WatchUi.SLIDE_LEFT);
        _onStatus = false;
    }

    function onStopChosen(index as Number) as Void {
        _stop = (_stops as Array<Dictionary>)[index];
        retryLineOptions();
    }

    function retryLineOptions() as Void {
        showStatus(Fmt.str(Rez.Strings.Loading));
        Net.send(_provider.buildLineOptionsRequest((_stop as Dictionary)["stopId"] as String), method(:onLineOptions));
    }

    function onLineOptions(code as Number, data) as Void {
        if (_cancelled) {
            return;
        }
        if (failed(code, method(:retryLineOptions))) {
            return;
        }
        var options = _provider.parseLineOptions(data);
        if (options == null || options.size() == 0) {
            _status.setError(Fmt.str(options == null ? Rez.Strings.ParseError : Rez.Strings.NoLines),
                method(:retryLineOptions));
            return;
        }
        _options = options;
        var menu = new WatchUi.Menu2({:title => Fmt.str(Rez.Strings.ChooseLine)});
        for (var i = 0; i < options.size(); i++) {
            menu.addItem(new WatchUi.MenuItem((options as Array<Dictionary>)[i]["label"] as String, null, i, null));
        }
        WatchUi.switchToView(menu, new IndexMenuDelegate(method(:onLineChosen), method(:cancel)), WatchUi.SLIDE_LEFT);
        _onStatus = false;
    }

    function onLineChosen(index as Number) as Void {
        var o = (_options as Array<Dictionary>)[index];
        var stop = _stop as Dictionary;
        var fav = Model.favorite(_provider.id(), stop["stopId"] as String, stop["name"] as String,
            o["quayId"] as String, o["lineId"] as String, o["lineCode"] as String, o["label"] as String);
        var saved = FavoritesStore.add(fav);
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        _onSaved.invoke(saved);
    }

    // Shows a network error with retry; returns true if the request failed.
    hidden function failed(code as Number, retry as Method) as Boolean {
        var err = ServiceError.fromResponseCode(code);
        if (err == null) {
            return false;
        }
        _status.setError(ServiceError.message(err, code), retry);
        return true;
    }

    // Show text on the status screen, swapping it in if a menu is currently shown.
    hidden function showStatus(text as String) as Void {
        if (_onStatus) {
            _status.setText(text);
            return;
        }
        _status = new StatusView(text);
        WatchUi.switchToView(_status, new StatusDelegate(_status, method(:cancel)), WatchUi.SLIDE_IMMEDIATE);
        _onStatus = true;
    }
}
