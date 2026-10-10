import Toybox.Application;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.Test;

class ResultCapture {
    var fav = null;
    var deps = null;
    var error = null;
    var code = null;
    var called = false;

    function initialize() {
    }

    function onResult(f as Dictionary, d as Array or Null, e as Number or Null, c as Number) as Void {
        fav = f; deps = d; error = e; code = c; called = true;
    }
}

function svcFav() as Dictionary {
    return Model.favorite("entur", "NSR:StopPlace:29169", "Gyldenprisveien", "NSR:Quay:50122", "SKY:Line:10", "10", "10 > Mulen");
}

(:test)
function testServiceErrorMapping(logger as Logger) as Boolean {
    return Check.eq(logger, "200", ServiceError.fromResponseCode(200), null)
        && Check.eq(logger, "ble", ServiceError.fromResponseCode(Communications.BLE_CONNECTION_UNAVAILABLE), ServiceError.NO_PHONE)
        && Check.eq(logger, "ble timeout", ServiceError.fromResponseCode(Communications.BLE_HOST_TIMEOUT), ServiceError.NO_PHONE)
        && Check.eq(logger, "500", ServiceError.fromResponseCode(500), ServiceError.HTTP_ERROR)
        && Check.eq(logger, "msg http", ServiceError.message(ServiceError.HTTP_ERROR, 500), "Feil (500)")
        && Check.eq(logger, "msg phone", ServiceError.message(ServiceError.NO_PHONE, -104), "Ingen telefon");
}

(:test)
function testServiceSuccessCaches(logger as Logger) as Boolean {
    var fav = svcFav();
    Application.Storage.deleteValue("dep|NSR:Quay:50122|SKY:Line:10");
    var cap = new ResultCapture();
    new DepartureService(fav, cap.method(:onResult)).onResponse(200, Fixtures.departures());
    var cached = DepartureCache.get(fav);
    var ok = Check.eq(logger, "called", cap.called, true)
        && Check.eq(logger, "error", cap.error, null)
        && Check.eq(logger, "deps", cap.deps.size(), 3)
        && Check.eq(logger, "fav", Model.sameFavorite(cap.fav, fav), true)
        && Check.eq(logger, "cached", (cached["d"] as Array).size(), 3);
    Application.Storage.deleteValue("dep|NSR:Quay:50122|SKY:Line:10");
    return ok;
}

(:test)
function testServiceNoPhone(logger as Logger) as Boolean {
    var cap = new ResultCapture();
    new DepartureService(svcFav(), cap.method(:onResult)).onResponse(Communications.BLE_CONNECTION_UNAVAILABLE, null);
    return Check.eq(logger, "error", cap.error, ServiceError.NO_PHONE)
        && Check.eq(logger, "deps", cap.deps, null);
}

(:test)
function testServiceEmptyAndParseError(logger as Logger) as Boolean {
    var empty = new ResultCapture();
    new DepartureService(svcFav(), empty.method(:onResult)).onResponse(200, Fixtures.departuresEmpty());
    var bad = new ResultCapture();
    new DepartureService(svcFav(), bad.method(:onResult)).onResponse(200, Fixtures.departuresError());
    return Check.eq(logger, "empty error", empty.error, ServiceError.NO_DEPARTURES)
        && Check.eq(logger, "empty deps", empty.deps.size(), 0)
        && Check.eq(logger, "bad error", bad.error, ServiceError.PARSE_ERROR)
        && Check.eq(logger, "bad deps", bad.deps, null);
}
