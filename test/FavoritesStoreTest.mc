import Toybox.Lang;
import Toybox.Test;

function favN(n as Number) as Dictionary {
    return Model.favorite("entur", "S" + n, "Stop " + n, "Q" + n, "L" + n, "" + n, n + " > X");
}

(:test)
function testFavoritesAddGetCount(logger as Logger) as Boolean {
    FavoritesStore.clear();
    var i0 = FavoritesStore.add(favN(1));
    var i1 = FavoritesStore.add(favN(2));
    var dup = FavoritesStore.add(favN(1));
    var ok = Check.eq(logger, "i0", i0, 0)
        && Check.eq(logger, "i1", i1, 1)
        && Check.eq(logger, "dup", dup, 0)
        && Check.eq(logger, "count", FavoritesStore.count(), 2)
        && Check.eq(logger, "get1", FavoritesStore.get(1)["quayId"], "Q2")
        && Check.eq(logger, "oob", FavoritesStore.get(5), null)
        && Check.eq(logger, "neg", FavoritesStore.get(-1), null);
    FavoritesStore.clear();
    return ok;
}

(:test)
function testFavoritesRemove(logger as Logger) as Boolean {
    FavoritesStore.clear();
    FavoritesStore.add(favN(1));
    FavoritesStore.add(favN(2));
    FavoritesStore.add(favN(3));
    FavoritesStore.remove(1);
    FavoritesStore.remove(9);
    var ok = Check.eq(logger, "count", FavoritesStore.count(), 2)
        && Check.eq(logger, "0", FavoritesStore.get(0)["quayId"], "Q1")
        && Check.eq(logger, "1", FavoritesStore.get(1)["quayId"], "Q3");
    FavoritesStore.clear();
    return ok;
}

(:test)
function testFavoritesMoveToTop(logger as Logger) as Boolean {
    FavoritesStore.clear();
    FavoritesStore.add(favN(1));
    FavoritesStore.add(favN(2));
    FavoritesStore.add(favN(3));
    FavoritesStore.moveToTop(2);
    var ok = Check.eq(logger, "0", FavoritesStore.get(0)["quayId"], "Q3")
        && Check.eq(logger, "1", FavoritesStore.get(1)["quayId"], "Q1")
        && Check.eq(logger, "2", FavoritesStore.get(2)["quayId"], "Q2");
    FavoritesStore.clear();
    return ok;
}
