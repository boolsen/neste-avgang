import Toybox.Lang;

// Base class for transit APIs. Subclasses build request descriptors
// ({"url", "params", "options"}) and parse responses into Model dictionaries.
// Parsers return null when the response cannot be understood.
(:glance)
class Provider {
    function initialize() {
    }

    function id() as String {
        return "";
    }

    function buildDeparturesRequest(fav as Dictionary, count as Number) as Dictionary or Null {
        return null;
    }

    function parseDepartures(data) as Array or Null {
        return null;
    }

    function buildNearbyStopsRequest(lat as Double, lon as Double) as Dictionary or Null {
        return null;
    }

    function parseNearbyStops(data) as Array or Null {
        return null;
    }

    function buildLineOptionsRequest(stopId as String) as Dictionary or Null {
        return null;
    }

    function parseLineOptions(data) as Array or Null {
        return null;
    }

    // Walk nested dictionaries; null if any step is missing or not a Dictionary.
    hidden function dig(data, path as Array<String>) {
        var cur = data;
        for (var i = 0; i < path.size(); i++) {
            if (!(cur instanceof Dictionary)) {
                return null;
            }
            cur = cur[path[i]];
        }
        return cur;
    }
}
