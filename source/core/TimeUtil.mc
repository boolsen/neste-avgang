import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

(:glance)
module TimeUtil {
    // "2026-10-10T10:23:00+02:00", "...Z" or with fractional seconds -> UTC epoch seconds.
    function parseIso8601(s as String) as Number or Null {
        var len = s.length();
        if (len < 19) {
            return null;
        }
        var year = s.substring(0, 4).toNumber();
        var month = s.substring(5, 7).toNumber();
        var day = s.substring(8, 10).toNumber();
        var hour = s.substring(11, 13).toNumber();
        var minute = s.substring(14, 16).toNumber();
        var second = s.substring(17, 19).toNumber();
        if (year == null || month == null || day == null || hour == null || minute == null || second == null) {
            return null;
        }

        // Skip fractional seconds, find zone designator.
        var i = 19;
        while (i < len) {
            var c = s.substring(i, i + 1);
            if (c.equals("Z") || c.equals("+") || c.equals("-")) {
                break;
            }
            i++;
        }
        var offset = 0;
        if (i < len && !s.substring(i, i + 1).equals("Z")) {
            if (len < i + 6) {
                return null;
            }
            var oh = s.substring(i + 1, i + 3).toNumber();
            var om = s.substring(i + 4, i + 6).toNumber();
            if (oh == null || om == null) {
                return null;
            }
            offset = oh * 3600 + om * 60;
            if (s.substring(i, i + 1).equals("-")) {
                offset = -offset;
            }
        }

        // Gregorian.moment interprets the fields as UTC.
        var m = Gregorian.moment({
            :year => year, :month => month, :day => day,
            :hour => hour, :minute => minute, :second => second
        });
        return m.value() - offset;
    }

    // Whole minutes until epoch, or -1 if it has already passed.
    function minutesUntil(epoch as Number, now as Number) as Number {
        var diff = epoch - now;
        if (diff < 0) {
            return -1;
        }
        return diff / 60;
    }
}
