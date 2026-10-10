import Toybox.Communications;
import Toybox.Lang;

(:glance)
class EnturProvider extends Provider {
    const URL = "https://api.entur.io/journey-planner/v3/graphql";
    const CLIENT_NAME = "boolsen-nesteavgang";

    const DEPARTURES_QUERY = "query($q:String!,$l:[ID!],$n:Int!){quay(id:$q){estimatedCalls(numberOfDepartures:$n,whiteListed:{lines:$l}){expectedDepartureTime realtime destinationDisplay{frontText} serviceJourney{line{publicCode}}}}}";
    const NEARBY_QUERY = "query($lat:Float!,$lon:Float!){nearest(latitude:$lat,longitude:$lon,maximumDistance:500,filterByPlaceTypes:[stopPlace],multiModalMode:child,first:10){edges{node{distance place{... on StopPlace{id name}}}}}}";
    const LINE_OPTIONS_QUERY = "query($id:String!){stopPlace(id:$id){quays{id lines{id publicCode} estimatedCalls(numberOfDepartures:10,timeRange:86400){destinationDisplay{frontText} serviceJourney{line{id}}}}}}";
    const MAX_DESTS = 2;

    function initialize() {
        Provider.initialize();
    }

    function id() as String {
        return "entur";
    }

    function buildDeparturesRequest(fav as Dictionary, count as Number) as Dictionary or Null {
        return request(DEPARTURES_QUERY, {"q" => fav["quayId"], "l" => [fav["lineId"]], "n" => count});
    }

    function parseDepartures(data) as Array or Null {
        var calls = dig(data, ["data", "quay", "estimatedCalls"]);
        if (!(calls instanceof Array)) {
            return null;
        }
        var result = [];
        for (var i = 0; i < calls.size(); i++) {
            var c = calls[i];
            var time = dig(c, ["expectedDepartureTime"]);
            var line = dig(c, ["serviceJourney", "line", "publicCode"]);
            var dest = dig(c, ["destinationDisplay", "frontText"]);
            if (time == null || line == null || dest == null) {
                continue;
            }
            var epoch = TimeUtil.parseIso8601(time as String);
            if (epoch == null) {
                continue;
            }
            result.add(Model.departure(line as String, dest as String, epoch, c["realtime"] == true));
        }
        return result;
    }

    function buildNearbyStopsRequest(lat as Double, lon as Double) as Dictionary or Null {
        return request(NEARBY_QUERY, {"lat" => lat, "lon" => lon});
    }

    function parseNearbyStops(data) as Array or Null {
        var edges = dig(data, ["data", "nearest", "edges"]);
        if (!(edges instanceof Array)) {
            return null;
        }
        var result = [];
        for (var i = 0; i < edges.size(); i++) {
            var id = dig(edges[i], ["node", "place", "id"]);
            var name = dig(edges[i], ["node", "place", "name"]);
            var dist = dig(edges[i], ["node", "distance"]);
            if (id == null || name == null || dist == null) {
                continue;
            }
            result.add(Model.nearbyStop(id as String, name as String, (dist as Float).toNumber()));
        }
        return result;
    }

    function buildLineOptionsRequest(stopId as String) as Dictionary or Null {
        return request(LINE_OPTIONS_QUERY, {"id" => stopId});
    }

    function parseLineOptions(data) as Array or Null {
        var quays = dig(data, ["data", "stopPlace", "quays"]);
        if (!(quays instanceof Array)) {
            return null;
        }
        var result = [];
        for (var q = 0; q < quays.size(); q++) {
            var quayId = dig(quays[q], ["id"]);
            var lines = dig(quays[q], ["lines"]);
            var calls = dig(quays[q], ["estimatedCalls"]);
            if (quayId == null || !(lines instanceof Array)) {
                continue;
            }
            for (var l = 0; l < lines.size(); l++) {
                var lineId = dig(lines[l], ["id"]);
                var code = dig(lines[l], ["publicCode"]);
                if (lineId == null || code == null) {
                    continue;
                }
                var dests = [];
                if (calls instanceof Array) {
                    for (var c = 0; c < calls.size() && dests.size() < MAX_DESTS; c++) {
                        var callLine = dig(calls[c], ["serviceJourney", "line", "id"]);
                        var dest = dig(calls[c], ["destinationDisplay", "frontText"]);
                        if (callLine != null && dest != null && (callLine as String).equals(lineId) && !contains(dests, dest as String)) {
                            dests.add(dest);
                        }
                    }
                }
                var label = code as String;
                for (var d = 0; d < dests.size(); d++) {
                    label += (d == 0 ? " > " : " / ") + dests[d];
                }
                result.add(Model.lineOption(quayId as String, lineId as String, code as String, label));
            }
        }
        return result;
    }

    hidden function contains(arr as Array, s as String) as Boolean {
        for (var i = 0; i < arr.size(); i++) {
            if (s.equals(arr[i])) {
                return true;
            }
        }
        return false;
    }

    hidden function request(query as String, variables as Dictionary) as Dictionary {
        return {
            "url" => URL,
            "params" => {"query" => query, "variables" => variables},
            "options" => {
                :method => Communications.HTTP_REQUEST_METHOD_POST,
                :headers => {
                    "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON,
                    "ET-Client-Name" => CLIENT_NAME
                },
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
            }
        };
    }
}
