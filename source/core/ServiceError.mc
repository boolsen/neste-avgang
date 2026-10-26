import Toybox.Communications;
import Toybox.Lang;

(:glance)
module ServiceError {
    enum Kind {
        NO_PHONE = 1,
        HTTP_ERROR = 2,
        PARSE_ERROR = 3,
        NO_DEPARTURES = 4,
        TIMEOUT = 5
    }

    function fromResponseCode(code as Number) as Number or Null {
        if (code == 200) {
            return null;
        }
        if (code == Communications.BLE_CONNECTION_UNAVAILABLE || code == Communications.BLE_HOST_TIMEOUT) {
            return NO_PHONE;
        }
        if (code == Communications.NETWORK_REQUEST_TIMED_OUT) {
            return TIMEOUT;
        }
        return HTTP_ERROR;
    }

    function message(err as Number, code as Number) as String {
        if (err == NO_PHONE) {
            return Fmt.str(Rez.Strings.NoPhone);
        }
        if (err == PARSE_ERROR) {
            return Fmt.str(Rez.Strings.ParseError);
        }
        if (err == TIMEOUT) {
            return Fmt.str(Rez.Strings.NoResponse);
        }
        if (err == NO_DEPARTURES) {
            return Fmt.str(Rez.Strings.NoDepartures);
        }
        return Lang.format(Fmt.str(Rez.Strings.ErrorFmt), [code]);
    }
}
