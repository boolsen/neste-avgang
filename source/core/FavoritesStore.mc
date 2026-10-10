import Toybox.Application;
import Toybox.Lang;

// Ordered (ranked) list of Favorite dictionaries. displayOrder() decides what the glance/overview show first.
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

    function moveUp(i as Number) as Void {
        swap(i - 1, i);
    }

    function moveDown(i as Number) as Void {
        swap(i, i + 1);
    }

    function setWindow(i as Number, fromH as Number or Null, toH as Number or Null) as Void {
        var a = all();
        if (i < 0 || i >= a.size()) {
            return;
        }
        var fav = a[i] as Dictionary;
        if (fromH == null || toH == null) {
            fav.remove("fromH");
            fav.remove("toH");
        } else {
            fav["fromH"] = fromH;
            fav["toH"] = toH;
        }
        a[i] = fav;
        Application.Storage.setValue(KEY, a);
    }

    // All indexes: favorites active at `hour` first (rank order), then the rest (rank order).
    function displayOrder(hour as Number) as Array<Number> {
        var a = all();
        var active = [];
        var inactive = [];
        for (var i = 0; i < a.size(); i++) {
            if (Model.isActive(a[i] as Dictionary, hour)) {
                active.add(i);
            } else {
                inactive.add(i);
            }
        }
        return active.addAll(inactive);
    }

    function swap(i as Number, j as Number) as Void {
        var a = all();
        if (i < 0 || j >= a.size() || i >= j) {
            return;
        }
        var tmp = a[i];
        a[i] = a[j];
        a[j] = tmp;
        Application.Storage.setValue(KEY, a);
    }

    function clear() as Void {
        Application.Storage.deleteValue(KEY);
    }

    function without(a as Array, i as Number) as Array {
        return a.slice(0, i).addAll(a.slice(i + 1, null));
    }
}
