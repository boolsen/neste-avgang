import Toybox.Communications;
import Toybox.Lang;
import Toybox.Test;

function testFav() as Dictionary {
    return Model.favorite("entur", "NSR:StopPlace:29169", "Gyldenprisveien", "NSR:Quay:50122", "SKY:Line:10", "10", "10 > Mulen");
}

(:test)
function testEnturParseDepartures(logger as Logger) as Boolean {
    var deps = new EnturProvider().parseDepartures(Fixtures.departures());
    return Check.eq(logger, "size", deps.size(), 3)
        && Check.eq(logger, "line", deps[0]["line"], "10")
        && Check.eq(logger, "dest", deps[0]["dest"], "Mulen")
        && Check.eq(logger, "epoch0", deps[0]["epoch"], 1791620580)
        && Check.eq(logger, "epoch1", deps[1]["epoch"], 1791621480)
        && Check.eq(logger, "rt0", deps[0]["rt"], true)
        && Check.eq(logger, "rt1", deps[1]["rt"], false);
}

(:test)
function testEnturParseDeparturesEmpty(logger as Logger) as Boolean {
    var deps = new EnturProvider().parseDepartures(Fixtures.departuresEmpty());
    return Check.eq(logger, "size", deps.size(), 0);
}

(:test)
function testEnturParseDeparturesErrorAndGarbage(logger as Logger) as Boolean {
    var p = new EnturProvider();
    return Check.eq(logger, "graphql error", p.parseDepartures(Fixtures.departuresError()), null)
        && Check.eq(logger, "null", p.parseDepartures(null), null)
        && Check.eq(logger, "string", p.parseDepartures("oops"), null);
}

(:test)
function testEnturBuildDeparturesRequest(logger as Logger) as Boolean {
    var req = new EnturProvider().buildDeparturesRequest(testFav(), 4);
    var vars = req["params"]["variables"];
    var headers = req["options"][:headers];
    return Check.eq(logger, "url", req["url"], "https://api.entur.io/journey-planner/v3/graphql")
        && Check.eq(logger, "quay", vars["q"], "NSR:Quay:50122")
        && Check.eq(logger, "line", vars["l"][0], "SKY:Line:10")
        && Check.eq(logger, "count", vars["n"], 4)
        && Check.eq(logger, "method", req["options"][:method], Communications.HTTP_REQUEST_METHOD_POST)
        && Check.eq(logger, "client", headers["ET-Client-Name"], "boolsen-nesteavgang");
}

(:test)
function testProviderRegistry(logger as Logger) as Boolean {
    return Check.eq(logger, "entur", ProviderRegistry.get("entur").id(), "entur")
        && Check.eq(logger, "unknown", ProviderRegistry.get("nope"), null);
}

(:test)
function testEnturParseNearbyStops(logger as Logger) as Boolean {
    var stops = new EnturProvider().parseNearbyStops(Fixtures.nearby());
    return Check.eq(logger, "size", stops.size(), 4)
        && Check.eq(logger, "id0", stops[0]["stopId"], "NSR:StopPlace:29282")
        && Check.eq(logger, "name0", stops[0]["name"], "Lien nord")
        && Check.eq(logger, "dist0", stops[0]["dist"], 121)
        && Check.eq(logger, "name2", stops[2]["name"], "Gyldenprisveien")
        && Check.eq(logger, "name3", stops[3]["name"], "Strandlien")
        && Check.eq(logger, "garbage", new EnturProvider().parseNearbyStops({}), null);
}

(:test)
function testEnturBuildNearbyRequest(logger as Logger) as Boolean {
    var vars = new EnturProvider().buildNearbyStopsRequest(60.3815d, 5.3174d)["params"]["variables"];
    return Check.eq(logger, "lat", vars["lat"], 60.3815d)
        && Check.eq(logger, "lon", vars["lon"], 5.3174d);
}

(:test)
function testEnturParseLineOptions(logger as Logger) as Boolean {
    var opts = new EnturProvider().parseLineOptions(Fixtures.lineOptions());
    return Check.eq(logger, "size", opts.size(), 5)
        && Check.eq(logger, "q0", opts[0]["quayId"], "NSR:Quay:50122")
        && Check.eq(logger, "l0", opts[0]["lineId"], "SKY:Line:10")
        && Check.eq(logger, "code0", opts[0]["lineCode"], "10")
        && Check.eq(logger, "label0", opts[0]["label"], "10 > Mulen")
        && Check.eq(logger, "label1 no calls", opts[1]["label"], "85")
        && Check.eq(logger, "q2", opts[2]["quayId"], "NSR:Quay:50123")
        && Check.eq(logger, "label2 max two", opts[2]["label"], "10 > Wergeland / Søndre Skogveien")
        && Check.eq(logger, "label4", opts[4]["label"], "20 > Nesttun terminal")
        && Check.eq(logger, "garbage", new EnturProvider().parseLineOptions(null), null);
}

(:test)
function testEnturBuildLineOptionsRequest(logger as Logger) as Boolean {
    var vars = new EnturProvider().buildLineOptionsRequest("NSR:StopPlace:29169")["params"]["variables"];
    return Check.eq(logger, "id", vars["id"], "NSR:StopPlace:29169");
}
