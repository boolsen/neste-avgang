import Toybox.Lang;

// Fetches departures for each row, one request at a time (avoids the request-queue limit).
(:glance)
class RowFetcher {
    hidden var _rows as Array;
    hidden var _count as Number;
    hidden var _onChange as Method;
    hidden var _i = 0;
    hidden var _busy = false;
    hidden var _cancelled = false;

    // onChange: () as Void, called after each row's result.
    function initialize(rows as Array, count as Number, onChange as Method) {
        _rows = rows;
        _count = count;
        _onChange = onChange;
    }

    function start() as Void {
        if (_cancelled || _busy || _rows.size() == 0) {
            return;
        }
        _busy = true;
        _i = 0;
        fetchCurrent();
    }

    // Stops the chain: an in-flight response is dropped and no further rows are fetched.
    function cancel() as Void {
        _cancelled = true;
    }

    function onResult(fav as Dictionary, deps as Array or Null, error as Number or Null, code as Number) as Void {
        if (_cancelled) {
            _busy = false;
            return;
        }
        var row = _rows[_i] as FavoriteRow;
        if (Model.sameFavorite(row.fav, fav)) {
            row.apply(deps, error, code);
        }
        _i++;
        _onChange.invoke();
        if (_i < _rows.size()) {
            fetchCurrent();
        } else {
            _busy = false;
        }
    }

    hidden function fetchCurrent() as Void {
        new DepartureService((_rows[_i] as FavoriteRow).fav, method(:onResult)).send(_count);
    }
}
