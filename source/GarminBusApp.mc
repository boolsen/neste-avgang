import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

(:glance)
class GarminBusApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        if (FavoritesStore.count() == 0) {
            var empty = new DeparturesView(0);   // empty state auto-starts the Add flow
            return [empty, new DeparturesDelegate(empty)];
        }
        var view = new OverviewView();
        return [view, new OverviewDelegate(view)];
    }

    (:glance)
    function getGlanceView() {
        return [new BusGlanceView()];
    }
}
