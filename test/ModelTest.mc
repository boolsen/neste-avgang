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

function windowFav(fromH, toH) as Dictionary {
    var f = Model.favorite("entur", "S", "Stop", "Q", "L", "1", "1 > X");
    if (fromH != null) {
        f["fromH"] = fromH;
        f["toH"] = toH;
    }
    return f;
}

(:test)
function testIsActiveNoWindow(logger as Logger) as Boolean {
    var f = windowFav(null, null);
    return Check.eq(logger, "0", Model.isActive(f, 0), true)
        && Check.eq(logger, "23", Model.isActive(f, 23), true);
}

(:test)
function testIsActiveNormalWindow(logger as Logger) as Boolean {
    var f = windowFav(5, 12);
    return Check.eq(logger, "4", Model.isActive(f, 4), false)
        && Check.eq(logger, "5", Model.isActive(f, 5), true)
        && Check.eq(logger, "11", Model.isActive(f, 11), true)
        && Check.eq(logger, "12", Model.isActive(f, 12), false);
}

(:test)
function testIsActiveOvernightWindow(logger as Logger) as Boolean {
    var f = windowFav(22, 2);
    return Check.eq(logger, "21", Model.isActive(f, 21), false)
        && Check.eq(logger, "22", Model.isActive(f, 22), true)
        && Check.eq(logger, "1", Model.isActive(f, 1), true)
        && Check.eq(logger, "2", Model.isActive(f, 2), false);
}

(:test)
function testIsActiveUntilMidnight(logger as Logger) as Boolean {
    var f = windowFav(12, 24);
    return Check.eq(logger, "23", Model.isActive(f, 23), true)
        && Check.eq(logger, "0", Model.isActive(f, 0), false)
        && Check.eq(logger, "11", Model.isActive(f, 11), false);
}

(:test)
function testWindowText(logger as Logger) as Boolean {
    return Check.eq(logger, "none", Model.windowText(windowFav(null, null)), null)
        && Check.eq(logger, "5-12", Model.windowText(windowFav(5, 12)), "05-12")
        && Check.eq(logger, "22-2", Model.windowText(windowFav(22, 2)), "22-02")
        && Check.eq(logger, "12-24", Model.windowText(windowFav(12, 24)), "12-24");
}
