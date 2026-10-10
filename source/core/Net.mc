import Toybox.Communications;
import Toybox.Lang;

(:glance)
module Net {
    // Sends a provider request descriptor. callback: (code as Number, data) as Void
    function send(req as Dictionary, callback as Method) as Void {
        Communications.makeWebRequest(req["url"] as String, req["params"] as Dictionary,
            req["options"] as Dictionary, callback);
    }
}
