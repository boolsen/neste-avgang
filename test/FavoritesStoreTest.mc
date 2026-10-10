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

(:test)
function testFavoritesMoveUpDown(logger as Logger) as Boolean {
    FavoritesStore.clear();
    FavoritesStore.add(favN(1));
    FavoritesStore.add(favN(2));
    FavoritesStore.add(favN(3));
    FavoritesStore.moveUp(2);      // 1,3,2
    FavoritesStore.moveUp(0);      // no-op
    FavoritesStore.moveDown(0);    // 3,1,2
    FavoritesStore.moveDown(2);    // no-op
    FavoritesStore.moveDown(9);    // no-op
    var ok = Check.eq(logger, "0", FavoritesStore.get(0)["quayId"], "Q3")
        && Check.eq(logger, "1", FavoritesStore.get(1)["quayId"], "Q1")
        && Check.eq(logger, "2", FavoritesStore.get(2)["quayId"], "Q2");
    FavoritesStore.clear();
    return ok;
}

(:test)
function testFavoritesSetWindow(logger as Logger) as Boolean {
    FavoritesStore.clear();
    FavoritesStore.add(favN(1));
    FavoritesStore.setWindow(0, 5, 12);
    var set = FavoritesStore.get(0);
    FavoritesStore.setWindow(0, null, null);
    var cleared = FavoritesStore.get(0);
    var ok = Check.eq(logger, "from", set["fromH"], 5)
        && Check.eq(logger, "to", set["toH"], 12)
        && Check.eq(logger, "cleared from", cleared["fromH"], null)
        && Check.eq(logger, "cleared to", cleared["toH"], null)
        && Check.eq(logger, "still same fav", cleared["quayId"], "Q1");
    FavoritesStore.clear();
    return ok;
}

(:test)
function testFavoritesDisplayOrder(logger as Logger) as Boolean {
    FavoritesStore.clear();
    FavoritesStore.add(favN(1));   // 0: home, morning
    FavoritesStore.add(favN(2));   // 1: centre, afternoon
    FavoritesStore.add(favN(3));   // 2: no window (always active)
    FavoritesStore.setWindow(0, 5, 12);
    FavoritesStore.setWindow(1, 12, 24);
    var morning = FavoritesStore.displayOrder(8);
    var afternoon = FavoritesStore.displayOrder(16);
    var night = FavoritesStore.displayOrder(2);
    var ok = Check.eq(logger, "m0", morning[0], 0) && Check.eq(logger, "m1", morning[1], 2) && Check.eq(logger, "m2", morning[2], 1)
        && Check.eq(logger, "a0", afternoon[0], 1) && Check.eq(logger, "a1", afternoon[1], 2) && Check.eq(logger, "a2", afternoon[2], 0)
        && Check.eq(logger, "n0", night[0], 2) && Check.eq(logger, "n1", night[1], 0) && Check.eq(logger, "n2", night[2], 1)
        && Check.eq(logger, "size", night.size(), 3);
    FavoritesStore.clear();
    return ok;
}
