import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

(:glance)
module Fmt {
    function str(id as ResourceId) as String {
        return WatchUi.loadResource(id) as String;
    }

    function minutes(min as Number, realtime as Boolean) as String {
        var s = (min == 0) ? str(Rez.Strings.Now) : Lang.format(str(Rez.Strings.MinutesFmt), [min]);
        return realtime ? s : Lang.format(str(Rez.Strings.ApproxFmt), [s]);
    }

    function clock(epoch as Number) as String {
        var info = Gregorian.info(new Time.Moment(epoch), Time.FORMAT_SHORT);
        return Lang.format("$1$:$2$", [(info.hour as Number).format("%02d"), (info.min as Number).format("%02d")]);
    }
}
