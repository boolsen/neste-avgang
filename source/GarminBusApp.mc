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
            FavoritesStore.add(DevSeed.favorite()); // temporary, removed in Task 8
        }
        var view = new DeparturesView();
        return [view, new DeparturesDelegate(view)];
    }

    (:glance)
    function getGlanceView() {
        return [new BusGlanceView()];
    }
}
