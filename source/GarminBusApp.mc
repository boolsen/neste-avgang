import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

(:glance)
class GarminBusApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        var view = new DeparturesView();
        return [view, new DeparturesDelegate(view)];
    }

    (:glance)
    function getGlanceView() {
        return [new BusGlanceView()];
    }
}
