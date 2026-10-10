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
        var i = _view.index;
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        if (id == :add) {
            new AddFavoriteFlow(_view.method(:showIndex)).start();
        } else if (id == :up) {
            FavoritesStore.moveUp(i);
            _view.showIndex(i - 1);
        } else if (id == :down) {
            FavoritesStore.moveDown(i);
            _view.showIndex(i + 1);
        } else if (id == :top) {
            FavoritesStore.moveToTop(i);
            _view.showIndex(0);
        } else if (id == :window) {
            new TimeWindowFlow(i, _view.method(:showIndex)).start();
        } else if (id == :delete) {
            FavoritesStore.remove(i);
            _view.showIndex(0);
        }
    }
}
