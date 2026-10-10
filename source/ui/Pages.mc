import Toybox.Lang;
import Toybox.WatchUi;

// Page switching: overview (page 0) <-> favorite pages (rank order).
module Pages {
    function showOverview(transition as WatchUi.SlideType) as Void {
        var view = new OverviewView();
        WatchUi.switchToView(view, new OverviewDelegate(view), transition);
    }

    function showFavorite(i as Number, transition as WatchUi.SlideType) as Void {
        var view = new DeparturesView(i);
        WatchUi.switchToView(view, new DeparturesDelegate(view), transition);
    }
}
