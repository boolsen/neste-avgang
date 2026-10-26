import Toybox.Lang;
import Toybox.Position;
import Toybox.Test;
import Toybox.Time;

function fixInfo(accuracy as Position.Quality, whenS as Number or Null) as Position.Info {
    var info = new Position.Info();
    info.position = new Position.Location({:latitude => 60.39, :longitude => 5.32, :format => :degrees});
    info.accuracy = accuracy;
    info.when = (whenS == null) ? null : new Time.Moment(whenS);
    return info;
}

(:test)
function testRecentFixAcceptsFreshFix(logger as Logger) as Boolean {
    var now = new Time.Moment(100000);
    return Check.eq(logger, "fresh", PositionFix.recent(fixInfo(Position.QUALITY_LAST_KNOWN, 100000 - 60), now) != null, true);
}

(:test)
function testRecentFixRejectsStaleFix(logger as Logger) as Boolean {
    var now = new Time.Moment(100000);
    return Check.eq(logger, "stale", PositionFix.recent(fixInfo(Position.QUALITY_LAST_KNOWN, 100000 - 3600), now), null);
}

(:test)
function testRecentFixRejectsUnknownTime(logger as Logger) as Boolean {
    var now = new Time.Moment(100000);
    return Check.eq(logger, "no when", PositionFix.recent(fixInfo(Position.QUALITY_GOOD, null), now), null);
}

(:test)
function testRecentFixRejectsNotAvailable(logger as Logger) as Boolean {
    var now = new Time.Moment(100000);
    return Check.eq(logger, "n/a", PositionFix.recent(fixInfo(Position.QUALITY_NOT_AVAILABLE, 100000), now), null);
}
