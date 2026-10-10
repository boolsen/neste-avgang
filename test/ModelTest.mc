import Toybox.Lang;
import Toybox.Test;

(:test)
function testSameFavorite(logger as Logger) as Boolean {
    var a = Model.favorite("entur", "NSR:StopPlace:29169", "Gyldenprisveien", "NSR:Quay:50122", "SKY:Line:10", "10", "10 > Mulen");
    var b = Model.favorite("entur", "NSR:StopPlace:29169", "Other name", "NSR:Quay:50122", "SKY:Line:10", "10", "other label");
    var c = Model.favorite("entur", "NSR:StopPlace:29169", "Gyldenprisveien", "NSR:Quay:50123", "SKY:Line:10", "10", "10 > Wergeland");
    return Check.eq(logger, "same", Model.sameFavorite(a, b), true)
        && Check.eq(logger, "other quay", Model.sameFavorite(a, c), false);
}

(:test)
function testUpcomingDropsPastAndLimits(logger as Logger) as Boolean {
    var now = 1000;
    var deps = [
        Model.departure("10", "Mulen", 900, true),
        Model.departure("10", "Mulen", 1000, true),
        Model.departure("10", "Mulen", 1600, true),
        Model.departure("10", "Mulen", 2200, false)
    ];
    var up = Model.upcoming(deps, now, 2);
    return Check.eq(logger, "size", up.size(), 2)
        && Check.eq(logger, "first", up[0]["epoch"], 1000)
        && Check.eq(logger, "second", up[1]["epoch"], 1600);
}
