import Toybox.Application;
import Toybox.Lang;
import Toybox.Test;

function rowFav() as Dictionary {
    return Model.favorite("entur", "NSR:StopPlace:1", "Gyldenprisveien", "ROWTEST:Quay:1", "ROWTEST:Line:10", "10", "10 > Mulen");
}

(:test)
function testFavoriteRowTitleAndLoading(logger as Logger) as Boolean {
    Application.Storage.deleteValue(DepartureCache.key(rowFav()));
    var row = new FavoriteRow(rowFav());
    return Check.eq(logger, "title", row.title(), "10 Gyldenprisveien")
        && Check.eq(logger, "loading", row.text(1000), "10 Gyldenprisveien: Henter…");
}

(:test)
function testFavoriteRowStatusMinutesAndPast(logger as Logger) as Boolean {
    Application.Storage.deleteValue(DepartureCache.key(rowFav()));
    var row = new FavoriteRow(rowFav());
    row.apply([Model.departure("10", "Mulen", 900, true), Model.departure("10", "Mulen", 1200, false)], null, 200);
    return Check.eq(logger, "next is scheduled 3 min", row.status(1000), "ca. 3 min");
}

(:test)
function testFavoriteRowErrorKeepsDeps(logger as Logger) as Boolean {
    Application.Storage.deleteValue(DepartureCache.key(rowFav()));
    var row = new FavoriteRow(rowFav());
    row.apply(null, ServiceError.NO_PHONE, -104);
    var errorOnly = row.status(1000);
    row.apply([Model.departure("10", "Mulen", 1060, true)], null, 200);
    row.apply(null, ServiceError.NO_PHONE, -104);
    return Check.eq(logger, "error", errorOnly, "Ingen telefon")
        && Check.eq(logger, "cached deps win", row.status(1000), "1 min");
}
