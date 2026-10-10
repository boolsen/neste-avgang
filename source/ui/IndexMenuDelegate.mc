import Toybox.Lang;
import Toybox.WatchUi;

// Menu2 delegate for lists whose item ids are array indexes.
class IndexMenuDelegate extends WatchUi.Menu2InputDelegate {
    hidden var _onChosen as Method;

    function initialize(onChosen as Method) {
        Menu2InputDelegate.initialize();
        _onChosen = onChosen;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        _onChosen.invoke(item.getId() as Number);
    }
}
