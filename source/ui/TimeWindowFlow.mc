import Toybox.Lang;
import Toybox.WatchUi;

// Menu flow: "Fra kl." (Hele dagen | 00-23) -> "Til kl." (next 23 hours, shown 01-24) -> save.
class TimeWindowFlow {
    const ALL_DAY = -1;

    hidden var _index as Number;
    hidden var _onDone as Method;
    hidden var _from = 0;

    function initialize(index as Number, onDone as Method) {
        _index = index;
        _onDone = onDone;
    }

    function start() as Void {
        var menu = new WatchUi.Menu2({:title => Fmt.str(Rez.Strings.StartHour)});
        menu.addItem(new WatchUi.MenuItem(Fmt.str(Rez.Strings.AllDay), null, ALL_DAY, null));
        for (var h = 0; h < 24; h++) {
            menu.addItem(new WatchUi.MenuItem(h.format("%02d"), null, h, null));
        }
        WatchUi.pushView(menu, new IndexMenuDelegate(method(:onStart), null), WatchUi.SLIDE_LEFT);
    }

    function onStart(h as Number) as Void {
        if (h == ALL_DAY) {
            finish(null, null);
            return;
        }
        _from = h;
        var menu = new WatchUi.Menu2({:title => Fmt.str(Rez.Strings.EndHour)});
        for (var k = 1; k < 24; k++) {
            var end = h + k;
            if (end > 24) {
                end -= 24;
            }
            menu.addItem(new WatchUi.MenuItem(end.format("%02d"), null, end, null));
        }
        WatchUi.switchToView(menu, new IndexMenuDelegate(method(:onEnd), null), WatchUi.SLIDE_LEFT);
    }

    function onEnd(end as Number) as Void {
        finish(_from, end);
    }

    hidden function finish(fromH as Number or Null, toH as Number or Null) as Void {
        FavoritesStore.setWindow(_index, fromH, toH);
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        _onDone.invoke(_index);
    }
}
