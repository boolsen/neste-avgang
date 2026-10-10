import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Full-screen message used during the Add flow ("Finner posisjon…", errors with retry).
class StatusView extends WatchUi.View {
    hidden var _text as String;
    hidden var _retry = null;

    function initialize(text as String) {
        View.initialize();
        _text = text;
    }

    function setText(text as String) as Void {
        _text = text;
        _retry = null;
        WatchUi.requestUpdate();
    }

    function setError(text as String, retry as Method) as Void {
        _text = text + "\n" + Fmt.str(Rez.Strings.TapToRetry);
        _retry = retry;
        WatchUi.requestUpdate();
    }

    function retry() as Boolean {
        if (_retry == null) {
            return false;
        }
        var r = _retry;
        _retry = null;
        r.invoke();
        return true;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Graphics.FONT_SMALL, _text,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

class StatusDelegate extends WatchUi.BehaviorDelegate {
    hidden var _view as StatusView;
    hidden var _onBack;

    function initialize(view as StatusView, onBack) {
        BehaviorDelegate.initialize();
        _view = view;
        _onBack = onBack;
    }

    // Notify the owner, then return false so the default Back (pop) still happens.
    function onBack() as Boolean {
        if (_onBack != null) {
            _onBack.invoke();
        }
        return false;
    }

    function onSelect() as Boolean {
        return _view.retry();
    }
}
