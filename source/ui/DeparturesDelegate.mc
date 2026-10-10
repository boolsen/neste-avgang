import Toybox.Lang;
import Toybox.WatchUi;

class DeparturesDelegate extends WatchUi.BehaviorDelegate {
    hidden var _view as DeparturesView;

    function initialize(view as DeparturesView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onNextPage() as Boolean {
        var n = FavoritesStore.count();
        if (n == 0) {
            return true;
        }
        if (_view.index + 1 >= n) {
            Pages.showOverview(WatchUi.SLIDE_UP);
        } else {
            _view.showIndex(_view.index + 1);
        }
        return true;
    }

    function onPreviousPage() as Boolean {
        var n = FavoritesStore.count();
        if (n == 0) {
            return true;
        }
        if (_view.index == 0) {
            Pages.showOverview(WatchUi.SLIDE_DOWN);
        } else {
            _view.showIndex(_view.index - 1);
        }
        return true;
    }

    function onSelect() as Boolean {
        openMenu();
        return true;
    }

    function onMenu() as Boolean {
        openMenu();
        return true;
    }

    hidden function openMenu() as Void {
        var menu = new WatchUi.Menu2({:title => Fmt.str(Rez.Strings.Menu)});
        menu.addItem(new WatchUi.MenuItem(Fmt.str(Rez.Strings.AddFavorite), null, :add, null));
        if (FavoritesStore.count() > 0) {
            menu.addItem(new WatchUi.MenuItem(Fmt.str(Rez.Strings.MoveToTop), null, :top, null));
            menu.addItem(new WatchUi.MenuItem(Fmt.str(Rez.Strings.DeleteFavorite), null, :delete, null));
        }
        WatchUi.pushView(menu, new FavoritesMenuDelegate(_view), WatchUi.SLIDE_UP);
    }
}
