import Toybox.Lang;

// Common models shared by providers and UI. Plain Dictionaries so they can be stored directly.
(:glance)
module Model {
    function departure(line as String, dest as String, epoch as Number, rt as Boolean) as Dictionary {
        return {"line" => line, "dest" => dest, "epoch" => epoch, "rt" => rt};
    }

    function favorite(provider as String, stopId as String, stopName as String, quayId as String,
            lineId as String, lineCode as String, label as String) as Dictionary {
        return {
            "provider" => provider, "stopId" => stopId, "stopName" => stopName,
            "quayId" => quayId, "lineId" => lineId, "lineCode" => lineCode, "label" => label
        };
    }

    function nearbyStop(stopId as String, name as String, dist as Number) as Dictionary {
        return {"stopId" => stopId, "name" => name, "dist" => dist};
    }

    function lineOption(quayId as String, lineId as String, lineCode as String, label as String) as Dictionary {
        return {"quayId" => quayId, "lineId" => lineId, "lineCode" => lineCode, "label" => label};
    }

    function sameFavorite(a as Dictionary, b as Dictionary) as Boolean {
        return (a["provider"] as String).equals(b["provider"])
            && (a["quayId"] as String).equals(b["quayId"])
            && (a["lineId"] as String).equals(b["lineId"]);
    }

    function upcoming(deps as Array, now as Number, max as Number) as Array {
        var result = [];
        for (var i = 0; i < deps.size() && result.size() < max; i++) {
            if (TimeUtil.minutesUntil(deps[i]["epoch"] as Number, now) >= 0) {
                result.add(deps[i]);
            }
        }
        return result;
    }

    // Optional hour window: "fromH" (0-23) .. "toH" (1-24, exclusive). Missing = always active.
    function isActive(fav as Dictionary, hour as Number) as Boolean {
        var from = fav["fromH"];
        var to = fav["toH"];
        if (from == null || to == null) {
            return true;
        }
        if ((from as Number) < (to as Number)) {
            return hour >= from && hour < to;
        }
        return hour >= from || hour < to; // window crosses midnight
    }

    function windowText(fav as Dictionary) as String or Null {
        var from = fav["fromH"];
        var to = fav["toH"];
        if (from == null || to == null) {
            return null;
        }
        return (from as Number).format("%02d") + "-" + (to as Number).format("%02d");
    }
}
