import Toybox.Lang;
import Toybox.WatchUi;

// Menu2 delegate for lists whose item ids are array indexes.
class IndexMenuDelegate extends WatchUi.Menu2InputDelegate {
    hidden var _onChosen as Method;
    hidden var _onBack;

    function initialize(onChosen as Method, onBack) {
        Menu2InputDelegate.initialize();
        _onChosen = onChosen;
        _onBack = onBack;
    }

    function onBack() as Void {
        if (_onBack != null) {
            _onBack.invoke();
        }
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        _onChosen.invoke(item.getId() as Number);
    }
}
