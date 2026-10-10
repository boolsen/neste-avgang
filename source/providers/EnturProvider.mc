import Toybox.Communications;
import Toybox.Lang;

(:glance)
class EnturProvider extends Provider {
    const URL = "https://api.entur.io/journey-planner/v3/graphql";
    const CLIENT_NAME = "boolsen-nesteavgang";

    const DEPARTURES_QUERY = "query($q:String!,$l:[ID!],$n:Int!){quay(id:$q){estimatedCalls(numberOfDepartures:$n,whiteListed:{lines:$l}){expectedDepartureTime realtime destinationDisplay{frontText} serviceJourney{line{publicCode}}}}}";

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
