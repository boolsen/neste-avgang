import Toybox.Application;
import Toybox.Lang;

// Ordered list of Favorite dictionaries. Index 0 is shown in the glance.
(:glance)
module FavoritesStore {
    const KEY = "favorites";

    function all() as Array {
        var v = Application.Storage.getValue(KEY);
        return (v == null) ? [] : v as Array;
    }

    function count() as Number {
        return all().size();
    }

    function get(i as Number) as Dictionary or Null {
        var a = all();
        return (i >= 0 && i < a.size()) ? a[i] as Dictionary : null;
    }

    function add(fav as Dictionary) as Number {
        var a = all();
        for (var i = 0; i < a.size(); i++) {
            if (Model.sameFavorite(a[i] as Dictionary, fav)) {
                return i;
            }
        }
        a.add(fav);
        Application.Storage.setValue(KEY, a);
        return a.size() - 1;
    }

    function remove(i as Number) as Void {
        var a = all();
        if (i < 0 || i >= a.size()) {
            return;
        }
        Application.Storage.setValue(KEY, without(a, i));
    }

    function moveToTop(i as Number) as Void {
        var a = all();
        if (i <= 0 || i >= a.size()) {
            return;
        }
        Application.Storage.setValue(KEY, [a[i]].addAll(without(a, i)));
    }

    function clear() as Void {
        Application.Storage.deleteValue(KEY);
    }

    function without(a as Array, i as Number) as Array {
        return a.slice(0, i).addAll(a.slice(i + 1, null));
    }
}
