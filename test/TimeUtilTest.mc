import Toybox.Lang;
import Toybox.Test;

(:test)
function testParseIsoPositiveOffset(logger as Logger) as Boolean {
    return Check.eq(logger, "+02:00", TimeUtil.parseIso8601("2026-10-10T10:23:00+02:00"), 1791620580);
}

(:test)
function testParseIsoZulu(logger as Logger) as Boolean {
    return Check.eq(logger, "Z", TimeUtil.parseIso8601("2026-10-10T08:23:00Z"), 1791620580);
}

(:test)
function testParseIsoNegativeOffset(logger as Logger) as Boolean {
    return Check.eq(logger, "-05:30", TimeUtil.parseIso8601("2026-10-10T03:23:00-05:30"), 1791622380);
}

(:test)
function testParseIsoFractionalSeconds(logger as Logger) as Boolean {
    return Check.eq(logger, "frac", TimeUtil.parseIso8601("2026-10-10T10:23:00.123+02:00"), 1791620580);
}

(:test)
function testParseIsoMalformed(logger as Logger) as Boolean {
    return Check.eq(logger, "short", TimeUtil.parseIso8601("2026-10-10"), null)
        && Check.eq(logger, "garbage", TimeUtil.parseIso8601("xxxx-xx-xxTxx:xx:xx+02:00"), null);
}

(:test)
function testMinutesUntil(logger as Logger) as Boolean {
    var now = 1791620580;
    return Check.eq(logger, "0s", TimeUtil.minutesUntil(now, now), 0)
        && Check.eq(logger, "59s", TimeUtil.minutesUntil(now + 59, now), 0)
        && Check.eq(logger, "60s", TimeUtil.minutesUntil(now + 60, now), 1)
        && Check.eq(logger, "11m30s", TimeUtil.minutesUntil(now + 690, now), 11)
        && Check.eq(logger, "past", TimeUtil.minutesUntil(now - 1, now), -1);
}

(:test)
function testFmtMinutes(logger as Logger) as Boolean {
    return Check.eq(logger, "now", Fmt.minutes(0, true), "Nå")
        && Check.eq(logger, "rt", Fmt.minutes(3, true), "3 min")
        && Check.eq(logger, "sched", Fmt.minutes(3, false), "ca. 3 min")
        && Check.eq(logger, "sched now", Fmt.minutes(0, false), "ca. Nå");
}
