import Toybox.Lang;
import Toybox.Time;

// One departures fetch for one favorite. Create a new instance per fetch so that
// overlapping requests (e.g. user swiped to another favorite) never share state.
(:glance)
class DepartureService {
    hidden var _fav as Dictionary;
    hidden var _callback as Method;
    hidden var _provider;

    // callback: (fav as Dictionary, deps as Array or Null, error as Number or Null, code as Number) as Void
    function initialize(fav as Dictionary, callback as Method) {
        _fav = fav;
        _callback = callback;
        _provider = ProviderRegistry.get(fav["provider"] as String);
    }

    function send(count as Number) as Void {
        Net.send(_provider.buildDeparturesRequest(_fav, count), method(:onResponse));
    }

    function onResponse(code as Number, data) as Void {
        var error = ServiceError.fromResponseCode(code);
        var deps = null;
        if (error == null) {
            deps = _provider.parseDepartures(data);
            if (deps == null) {
                error = ServiceError.PARSE_ERROR;
            } else if (deps.size() == 0) {
                error = ServiceError.NO_DEPARTURES;
            } else {
                // Storage may be read-only in glance context on some devices; cache is best-effort.
                try {
                    DepartureCache.put(_fav, deps, Time.now().value());
                } catch (e) {
                }
            }
        }
        _callback.invoke(_fav, deps, error, code);
    }
}
