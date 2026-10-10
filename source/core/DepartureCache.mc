import Toybox.Application;
import Toybox.Lang;

// Last successful departures per favorite: {"t" => fetchedEpoch, "d" => Array of Departure}.
(:glance)
module DepartureCache {
    function key(fav as Dictionary) as String {
        return "dep|" + fav["quayId"] + "|" + fav["lineId"];
    }

    function put(fav as Dictionary, deps as Array, now as Number) as Void {
        Application.Storage.setValue(key(fav), {"t" => now, "d" => deps});
    }

    function get(fav as Dictionary) as Dictionary or Null {
        return Application.Storage.getValue(key(fav)) as Dictionary or Null;
    }
}
