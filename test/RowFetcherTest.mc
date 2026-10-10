import Toybox.Application;
import Toybox.Lang;
import Toybox.Test;

class ChangeCounter {
    var n = 0;
    function bump() as Void {
        n++;
    }
}

(:test)
function testRowFetcherCancelledIgnoresResult(logger as Logger) as Boolean {
    Application.Storage.deleteValue(DepartureCache.key(rowFav()));
    var row = new FavoriteRow(rowFav());
    var counter = new ChangeCounter();
    var fetcher = new RowFetcher([row], 2, counter.method(:bump));
    fetcher.cancel();
    fetcher.start();   // no-op, so no network
    fetcher.onResult(rowFav(), [Model.departure("10", "Mulen", 900, true)], null, 200);
    return Check.eq(logger, "no onChange", counter.n, 0)
        && Check.eq(logger, "row untouched", row.status(1000), "Henter…");
}
