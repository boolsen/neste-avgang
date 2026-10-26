import Toybox.Lang;
import Toybox.Position;
import Toybox.Time;

module PositionFix {
    // The stop search covers 500 m, so a rough fix is enough, but an old one may be in another city.
    const RECENT_FIX_S = 120;

    // The fix's position when it is known and at most RECENT_FIX_S old, else null.
    function recent(info as Position.Info, now as Time.Moment) as Position.Location or Null {
        if (info.position == null || info.accuracy == Position.QUALITY_NOT_AVAILABLE || info.when == null) {
            return null;
        }
        return (now.subtract(info.when as Time.Moment).value() <= RECENT_FIX_S) ? info.position : null;
    }
}
