import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class OverviewDelegate extends WatchUi.BehaviorDelegate {
    hidden var _view as OverviewView;

    function initialize(view as OverviewView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onNextPage() as Boolean {
        if (FavoritesStore.count() > 0) {
            Pages.showFavorite(0, WatchUi.SLIDE_UP);
        }
        return true;
    }

    function onPreviousPage() as Boolean {
        var n = FavoritesStore.count();
        if (n > 0) {
            Pages.showFavorite(n - 1, WatchUi.SLIDE_DOWN);
        }
        return true;
    }

    // Tap a row to open that favorite's page.
    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        var xy = evt.getCoordinates();
        var row = OverviewLayout.rowAt(xy[1], System.getDeviceSettings().screenHeight, _view.rowCount());
        var fav = (row == null) ? null : _view.favoriteIndexAtRow(row);
        if (fav != null) {
            _view.openFavorite(fav);
            return true;
        }
        return true;   // a miss does nothing; the physical button opens the menu
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
        WatchUi.pushView(menu, new OverviewMenuDelegate(_view), WatchUi.SLIDE_UP);
    }
}

class OverviewMenuDelegate extends WatchUi.Menu2InputDelegate {
    hidden var _view as OverviewView;

    function initialize(view as OverviewView) {
        Menu2InputDelegate.initialize();
        _view = view;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        if (item.getId() == :add) {
            new AddFavoriteFlow(_view.method(:openFavorite)).start();
        }
    }
}
