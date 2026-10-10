import Toybox.Lang;
import Toybox.WatchUi;

class FavoritesMenuDelegate extends WatchUi.Menu2InputDelegate {
    hidden var _view as DeparturesView;

    function initialize(view as DeparturesView) {
        Menu2InputDelegate.initialize();
        _view = view;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        if (id == :add) {
            new AddFavoriteFlow(_view.method(:showIndex)).start();
        } else if (id == :top) {
            FavoritesStore.moveToTop(_view.index);
            _view.showIndex(0);
        } else if (id == :delete) {
            FavoritesStore.remove(_view.index);
            _view.showIndex(0);
        }
    }
}
