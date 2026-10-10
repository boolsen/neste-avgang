import Toybox.Lang;
import Toybox.WatchUi;

class DeparturesDelegate extends WatchUi.BehaviorDelegate {
    hidden var _view as DeparturesView;

    function initialize(view as DeparturesView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onNextPage() as Boolean {
        _view.showIndex(_view.index + 1);
        return true;
    }

    function onPreviousPage() as Boolean {
        _view.showIndex(_view.index - 1);
        return true;
    }
}
