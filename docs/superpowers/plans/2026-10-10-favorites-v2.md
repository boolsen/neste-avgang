# Favorites v2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add per-favorite hour windows, a 2-row glance, an overview page with one row per favorite, and up/down ranking.

**Architecture:**
- Window logic and ordering are pure functions in `Model` and `FavoritesStore`, unit-tested.
- A glance-safe `FavoriteRow` + `RowFetcher` pair holds and sequentially fetches one-row-per-favorite data. The glance and the new `OverviewView` both use it.
- `Pages` switches between the overview and the existing favorite page (`DeparturesView`).

**Tech Stack:** Monkey C / Connect IQ SDK 9.2.0, `make test` / `make build`.

**Spec:** `docs/superpowers/specs/2026-10-10-favorites-v2-design.md`

## Global Constraints

- Devices: `venu445mm` (primary), `venu441mm`, `vivoactive6`. Every task builds all three.
- All user-facing text comes from `resources/strings/strings.xml`. Strings used by glance code need `scope="glance"`. No literal UI text in `.mc`, except separators such as `": "`, `"  "` and `"-"`.
- Every class/module reachable from the glance is `(:glance)`.
- `Fmt.str(id as ResourceId) as String` takes a ResourceId (not a Symbol).
- `make test` needs the simulator: if one is running, reuse it and don't kill it. Otherwise run `make sim`, wait ~8 s, run the tests, then `pkill -f "ConnectIQ.app"`. Its exit status reflects pass/fail.
- Live fetches for multi-row screens run one at a time (never in parallel).
- Favorite window keys: `"fromH"` (0–23), `"toH"` (1–24, never equal to fromH). A missing key means active all day.
- Every commit message ends with a blank line, then `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## File Structure

```
source/core/Model.mc            + isActive, windowText
source/core/TimeUtil.mc         + currentHour
source/core/FavoritesStore.mc   + moveUp, moveDown, setWindow, displayOrder
source/core/FavoriteRow.mc      NEW (glance) one favorite's row state + text
source/core/RowFetcher.mc       NEW (glance) sequential fetch of FavoriteRows
source/ui/BusGlanceView.mc      rewritten: up to 2 rows
source/ui/OverviewLayout.mc     NEW pure row geometry (rowY, rowAt, rowWidth)
source/ui/OverviewView.mc       NEW overview page
source/ui/OverviewDelegate.mc   NEW swipe/tap/menu for overview
source/ui/Pages.mc              NEW switchToView helpers
source/ui/TimeWindowFlow.mc     NEW Fra kl./Til kl. menus
source/ui/DeparturesView.mc     index via constructor, window text under stop name
source/ui/DeparturesDelegate.mc swipe to overview at ends, extended menu
source/ui/FavoritesMenuDelegate.mc  handle :up, :down, :window
source/GarminBusApp.mc          initial view: overview (or empty favorite page)
resources/strings/strings.xml   + MoveUp, MoveDown, TimeWindow, AllDay, StartHour, EndHour, Overview
test/ModelTest.mc, test/FavoritesStoreTest.mc   extended
test/FavoriteRowTest.mc, test/OverviewLayoutTest.mc   NEW
```

---

### Task 1: Window model, ranking and ordering (pure logic)

**Files:**
- Modify: `source/core/Model.mc`, `source/core/TimeUtil.mc`, `source/core/FavoritesStore.mc`
- Modify: `test/ModelTest.mc`, `test/FavoritesStoreTest.mc`

**Interfaces:**
- Produces:
  - `Model.isActive(fav as Dictionary, hour as Number) as Boolean`
  - `Model.windowText(fav as Dictionary) as String or Null`: e.g. `"05-12"`, `"22-02"`, `"12-24"`; null when there is no window
  - `TimeUtil.currentHour() as Number`
  - `FavoritesStore.moveUp(i)`, `moveDown(i)`: swap with the neighbour; no-op at the edges or out of range
  - `FavoritesStore.setWindow(i as Number, fromH as Number or Null, toH as Number or Null) as Void`: nulls remove both keys
  - `FavoritesStore.displayOrder(hour as Number) as Array<Number>`: all indexes, active ones first (rank order), then inactive (rank order)

- [ ] **Step 1: Append failing tests to `test/ModelTest.mc`**

```monkeyc
function windowFav(fromH, toH) as Dictionary {
    var f = Model.favorite("entur", "S", "Stop", "Q", "L", "1", "1 > X");
    if (fromH != null) {
        f["fromH"] = fromH;
        f["toH"] = toH;
    }
    return f;
}

(:test)
function testIsActiveNoWindow(logger as Logger) as Boolean {
    var f = windowFav(null, null);
    return Check.eq(logger, "0", Model.isActive(f, 0), true)
        && Check.eq(logger, "23", Model.isActive(f, 23), true);
}

(:test)
function testIsActiveNormalWindow(logger as Logger) as Boolean {
    var f = windowFav(5, 12);
    return Check.eq(logger, "4", Model.isActive(f, 4), false)
        && Check.eq(logger, "5", Model.isActive(f, 5), true)
        && Check.eq(logger, "11", Model.isActive(f, 11), true)
        && Check.eq(logger, "12", Model.isActive(f, 12), false);
}

(:test)
function testIsActiveOvernightWindow(logger as Logger) as Boolean {
    var f = windowFav(22, 2);
    return Check.eq(logger, "21", Model.isActive(f, 21), false)
        && Check.eq(logger, "22", Model.isActive(f, 22), true)
        && Check.eq(logger, "1", Model.isActive(f, 1), true)
        && Check.eq(logger, "2", Model.isActive(f, 2), false);
}

(:test)
function testIsActiveUntilMidnight(logger as Logger) as Boolean {
    var f = windowFav(12, 24);
    return Check.eq(logger, "23", Model.isActive(f, 23), true)
        && Check.eq(logger, "0", Model.isActive(f, 0), false)
        && Check.eq(logger, "11", Model.isActive(f, 11), false);
}

(:test)
function testWindowText(logger as Logger) as Boolean {
    return Check.eq(logger, "none", Model.windowText(windowFav(null, null)), null)
        && Check.eq(logger, "5-12", Model.windowText(windowFav(5, 12)), "05-12")
        && Check.eq(logger, "22-2", Model.windowText(windowFav(22, 2)), "22-02")
        && Check.eq(logger, "12-24", Model.windowText(windowFav(12, 24)), "12-24");
}
```

- [ ] **Step 2: Append failing tests to `test/FavoritesStoreTest.mc`**

(`favN(n)` already exists in this file.)

```monkeyc
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
```

- [ ] **Step 3: Run `make test`. It should fail** (compile errors: `isActive`, `windowText`, `moveUp`, `setWindow`, `displayOrder` are undefined).

- [ ] **Step 4: Add to `source/core/Model.mc`** (inside the module, after `upcoming`)

```monkeyc
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
```

- [ ] **Step 5: Add to `source/core/TimeUtil.mc`** (add `import Toybox.System;` at the top and this function inside the module)

```monkeyc
    function currentHour() as Number {
        return System.getClockTime().hour;
    }
```

- [ ] **Step 6: Add to `source/core/FavoritesStore.mc`** (inside the module, after `moveToTop`; update the header comment as shown)

Header comment becomes:
```monkeyc
// Ordered (ranked) list of Favorite dictionaries. displayOrder() decides what the glance/overview show first.
```

```monkeyc
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
```

- [ ] **Step 7: Run `make test`. It should pass** (25 old + 8 new = 33). Then build all three devices.

- [ ] **Step 8: Commit** `feat: favorite hour windows, move up/down, display order`

---

### Task 2: FavoriteRow, RowFetcher, 2-row glance

**Files:**
- Create: `source/core/FavoriteRow.mc`, `source/core/RowFetcher.mc`, `test/FavoriteRowTest.mc`
- Modify (rewrite): `source/ui/BusGlanceView.mc`

**Interfaces:**
- Consumes: `DepartureCache.get`, `DepartureService(fav, cb).send(n)` with callback `(fav, deps, error, code)`, `Model.upcoming`, `Model.sameFavorite`, `TimeUtil.minutesUntil`, `Fmt.minutes`, `Fmt.str`, `ServiceError.message`, `FavoritesStore.displayOrder`, `TimeUtil.currentHour`
- Produces:
  - `new FavoriteRow(fav as Dictionary)`. Public `var fav`. Methods: `apply(deps as Array or Null, error as Number or Null, code as Number) as Void`, `title() as String` (`lineCode + " " + stopName`), `status(now as Number) as String`, `text(now as Number) as String` (`title() + ": " + status(now)`).
  - `new RowFetcher(rows as Array<FavoriteRow>, count as Number, onChange as Method)`. `start() as Void` is ignored while a pass is running. `onChange()` is invoked after each row's result.

- [ ] **Step 1: Write failing tests `test/FavoriteRowTest.mc`**

```monkeyc
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
```

- [ ] **Step 2: Run `make test`. It should fail** (`FavoriteRow` is undefined).

- [ ] **Step 3: Create `source/core/FavoriteRow.mc`**

```monkeyc
import Toybox.Lang;

// One favorite's one-line state for multi-row screens (glance, overview).
(:glance)
class FavoriteRow {
    var fav as Dictionary;
    hidden var _deps = null;
    hidden var _error = null;
    hidden var _code = 0;

    function initialize(f as Dictionary) {
        fav = f;
        var cached = DepartureCache.get(f);
        if (cached != null) {
            _deps = cached["d"];
        }
    }

    function apply(deps as Array or Null, error as Number or Null, code as Number) as Void {
        _error = error;
        _code = code;
        if (deps != null) {
            _deps = deps;
        }
    }

    function title() as String {
        return (fav["lineCode"] as String) + " " + (fav["stopName"] as String);
    }

    function status(now as Number) as String {
        var next = ((_deps == null) ? [] : Model.upcoming(_deps as Array, now, 1)) as Array;
        if (next.size() > 0) {
            return Fmt.minutes(TimeUtil.minutesUntil(next[0]["epoch"] as Number, now), next[0]["rt"] as Boolean);
        }
        if (_error != null) {
            return ServiceError.message(_error as Number, _code);
        }
        return Fmt.str(Rez.Strings.Loading);
    }

    function text(now as Number) as String {
        return title() + ": " + status(now);
    }
}
```

- [ ] **Step 4: Create `source/core/RowFetcher.mc`**

```monkeyc
import Toybox.Lang;

// Fetches departures for each row, one request at a time (avoids the request-queue limit).
(:glance)
class RowFetcher {
    hidden var _rows as Array;
    hidden var _count as Number;
    hidden var _onChange as Method;
    hidden var _i = 0;
    hidden var _busy = false;

    // onChange: () as Void, called after each row's result.
    function initialize(rows as Array, count as Number, onChange as Method) {
        _rows = rows;
        _count = count;
        _onChange = onChange;
    }

    function start() as Void {
        if (_busy || _rows.size() == 0) {
            return;
        }
        _busy = true;
        _i = 0;
        fetchCurrent();
    }

    function onResult(fav as Dictionary, deps as Array or Null, error as Number or Null, code as Number) as Void {
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
```

- [ ] **Step 5: Rewrite `source/ui/BusGlanceView.mc`**

```monkeyc
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

// Glance: up to two favorites (active-now first, then by rank). Cached data first, then live, one fetch at a time.
(:glance)
class BusGlanceView extends WatchUi.GlanceView {
    const MAX_ROWS = 2;
    const FETCH = 2;

    hidden var _rows = [];
    hidden var _fetcher = null;

    function initialize() {
        GlanceView.initialize();
    }

    function onShow() as Void {
        var order = FavoritesStore.displayOrder(TimeUtil.currentHour());
        _rows = [];
        for (var i = 0; i < order.size() && i < MAX_ROWS; i++) {
            _rows.add(new FavoriteRow(FavoritesStore.get(order[i]) as Dictionary));
        }
        _fetcher = new RowFetcher(_rows, FETCH, method(:onRowsChanged));
        _fetcher.start();
    }

    function onRowsChanged() as Void {
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var left = Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER;
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        if (_rows.size() == 0) {
            dc.drawText(0, h / 2, Graphics.FONT_TINY, Fmt.str(Rez.Strings.AddFavorite), left);
            return;
        }
        var now = Time.now().value();
        var first = _rows[0] as FavoriteRow;
        if (_rows.size() == 1) {
            dc.drawText(0, h * 0.3, Graphics.FONT_TINY, first.fav["label"] as String, left);
            drawFitted(dc, h * 0.72, (first.fav["stopName"] as String) + ": " + first.status(now), w);
            return;
        }
        drawFitted(dc, h * 0.3, first.text(now), w);
        drawFitted(dc, h * 0.72, (_rows[1] as FavoriteRow).text(now), w);
    }

    hidden function drawFitted(dc as Graphics.Dc, y as Numeric, text as String, w as Number) as Void {
        var font = Graphics.FONT_XTINY;
        var fitted = Graphics.fitTextToArea(text, font, w, dc.getFontHeight(font), true);
        dc.drawText(0, y, font, fitted, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
```

- [ ] **Step 6: Run `make test`. It should pass** (36 tests). Build all three devices with no new warnings.

- [ ] **Step 7: Commit** `feat: two-row glance with sequential fetching`

---

### Task 3: Overview page, page navigation

**Files:**
- Create: `source/ui/OverviewLayout.mc`, `source/ui/OverviewView.mc`, `source/ui/OverviewDelegate.mc`, `source/ui/Pages.mc`, `test/OverviewLayoutTest.mc`
- Modify: `source/ui/DeparturesView.mc`, `source/ui/DeparturesDelegate.mc`, `source/GarminBusApp.mc`, `resources/strings/strings.xml`

**Interfaces:**
- Consumes: `FavoriteRow`, `RowFetcher`, `FavoritesStore.displayOrder/get/count`, `TimeUtil.currentHour`, `Model.windowText`, `AddFavoriteFlow(onSaved).start()`
- Produces:
  - `OverviewLayout.ROW_Y0 = 0.34`, `OverviewLayout.ROW_DY = 0.14`, `rowY(i, h) as Number`, `rowAt(y, h, rows) as Number or Null`, `rowWidth(i, w, h) as Number`
  - `Pages.showOverview(transition)` and `Pages.showFavorite(i as Number, transition)`
  - `DeparturesView(index as Number)` constructor (replaces the no-arg constructor)
  - `OverviewView.openFavorite(i as Number) as Void`, `OverviewView.favoriteIndexAtRow(row as Number) as Number or Null`, `OverviewView.rowCount() as Number`

- [ ] **Step 1: Add string** to `resources/strings/strings.xml` (before `</strings>`):

```xml
    <string id="Overview">Neste avganger</string>
```

- [ ] **Step 2: Write failing tests `test/OverviewLayoutTest.mc`**

```monkeyc
import Toybox.Lang;
import Toybox.Test;

(:test)
function testOverviewRowAt(logger as Logger) as Boolean {
    var h = 454;
    // row i is centred at h*(0.34 + 0.14*i) and spans +/- 0.07*h
    return Check.eq(logger, "above first", OverviewLayout.rowAt(100, h, 4), null)       // 0.22h
        && Check.eq(logger, "row0", OverviewLayout.rowAt(OverviewLayout.rowY(0, h), h, 4), 0)
        && Check.eq(logger, "row1", OverviewLayout.rowAt(OverviewLayout.rowY(1, h), h, 4), 1)
        && Check.eq(logger, "row3", OverviewLayout.rowAt(OverviewLayout.rowY(3, h), h, 4), 3)
        && Check.eq(logger, "beyond rows", OverviewLayout.rowAt(OverviewLayout.rowY(2, h), h, 2), null)
        && Check.eq(logger, "below", OverviewLayout.rowAt(h - 1, h, 4), null);
}

(:test)
function testOverviewRowWidthFitsCircle(logger as Logger) as Boolean {
    var w = 454;
    var h = 454;
    var mid = OverviewLayout.rowWidth(1, w, h);   // y = 0.48h, near the centre
    var top = OverviewLayout.rowWidth(0, w, h);   // y = 0.34h
    return Check.eq(logger, "mid wider than top", mid > top, true)
        && Check.eq(logger, "mid below 90% width", mid <= (w * 0.9).toNumber(), true);
}
```

- [ ] **Step 3: Run `make test`. It should fail** (`OverviewLayout` is undefined).

- [ ] **Step 4: Create `source/ui/OverviewLayout.mc`**

```monkeyc
import Toybox.Lang;
import Toybox.Math;

// Row geometry for the overview page; shared by drawing and tap handling.
module OverviewLayout {
    const ROW_Y0 = 0.34;   // centre of row 0, as a fraction of height
    const ROW_DY = 0.14;   // row pitch, as a fraction of height

    function rowY(i as Number, h as Number) as Number {
        return (h * (ROW_Y0 + ROW_DY * i)).toNumber();
    }

    // Row index under y, or null when outside the first `rows` rows.
    function rowAt(y as Number, h as Number, rows as Number) as Number or Null {
        var f = (y.toFloat() / h - (ROW_Y0 - ROW_DY / 2)) / ROW_DY;
        if (f < 0) {
            return null;
        }
        var r = f.toNumber();
        return (r < rows) ? r : null;
    }

    // Usable text width for row i on a round screen (90% of the chord at that height).
    function rowWidth(i as Number, w as Number, h as Number) as Number {
        var r = h / 2.0;
        var dy = rowY(i, h) - r;
        var half = Math.sqrt(r * r - dy * dy);
        var chord = 2 * half * 0.9;
        return (chord < w * 0.9 ? chord : w * 0.9).toNumber();
    }
}
```

- [ ] **Step 5: Create `source/ui/Pages.mc`**

```monkeyc
import Toybox.Lang;
import Toybox.WatchUi;

// Page switching: overview (page 0) <-> favorite pages (rank order).
module Pages {
    function showOverview(transition as WatchUi.SlideType) as Void {
        var view = new OverviewView();
        WatchUi.switchToView(view, new OverviewDelegate(view), transition);
    }

    function showFavorite(i as Number, transition as WatchUi.SlideType) as Void {
        var view = new DeparturesView(i);
        WatchUi.switchToView(view, new DeparturesDelegate(view), transition);
    }
}
```

- [ ] **Step 6: Create `source/ui/OverviewView.mc`**

```monkeyc
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Timer;
import Toybox.WatchUi;

// Page 0: next departure for up to 4 favorites (active-now first, then by rank).
class OverviewView extends WatchUi.View {
    const MAX_ROWS = 4;
    const FETCH = 2;
    const REFRESH_MS = 30000;

    hidden var _order = [];
    hidden var _rows = [];
    hidden var _fetcher = null;
    hidden var _timer;

    function initialize() {
        View.initialize();
        _timer = new Timer.Timer();
    }

    function onShow() as Void {
        var order = FavoritesStore.displayOrder(TimeUtil.currentHour());
        _order = [];
        _rows = [];
        for (var i = 0; i < order.size() && i < MAX_ROWS; i++) {
            _order.add(order[i]);
            _rows.add(new FavoriteRow(FavoritesStore.get(order[i]) as Dictionary));
        }
        _fetcher = new RowFetcher(_rows, FETCH, method(:onRowsChanged));
        refresh();
        _timer.stop();
        _timer.start(method(:refresh), REFRESH_MS, true);
    }

    function onHide() as Void {
        _timer.stop();
    }

    function refresh() as Void {
        _fetcher.start();
        WatchUi.requestUpdate();
    }

    function onRowsChanged() as Void {
        WatchUi.requestUpdate();
    }

    function rowCount() as Number {
        return _rows.size();
    }

    function favoriteIndexAtRow(row as Number) as Number or Null {
        return (row >= 0 && row < _order.size()) ? _order[row] as Number : null;
    }

    function openFavorite(i as Number) as Void {
        Pages.showFavorite(i, WatchUi.SLIDE_IMMEDIATE);
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        if (_rows.size() == 0) {
            dc.drawText(w / 2, h / 2, Graphics.FONT_SMALL, Fmt.str(Rez.Strings.AddFavorite), center);
            return;
        }
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.18, Graphics.FONT_XTINY, Fmt.str(Rez.Strings.Overview), center);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var now = Time.now().value();
        var font = Graphics.FONT_TINY;
        for (var i = 0; i < _rows.size(); i++) {
            var text = Graphics.fitTextToArea((_rows[i] as FavoriteRow).text(now), font,
                OverviewLayout.rowWidth(i, w, h), dc.getFontHeight(font), true);
            dc.drawText(w / 2, OverviewLayout.rowY(i, h), font, text, center);
        }
    }
}
```

- [ ] **Step 7: Create `source/ui/OverviewDelegate.mc`**

```monkeyc
import Toybox.Lang;
import Toybox.WatchUi;

class OverviewDelegate extends WatchUi.BehaviorDelegate {
    hidden var _view as OverviewView;

    function initialize(view as OverviewView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onNextPage() as Boolean {
        if (FavoritesStore.count() > 0) {
            Pages.showFavorite(0, WatchUi.SLIDE_UP);
        }
        return true;
    }

    function onPreviousPage() as Boolean {
        var n = FavoritesStore.count();
        if (n > 0) {
            Pages.showFavorite(n - 1, WatchUi.SLIDE_DOWN);
        }
        return true;
    }

    // Tap a row to open that favorite's page.
    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        var xy = evt.getCoordinates();
        var row = OverviewLayout.rowAt(xy[1], System.getDeviceSettings().screenHeight, _view.rowCount());
        var fav = (row == null) ? null : _view.favoriteIndexAtRow(row);
        if (fav != null) {
            _view.openFavorite(fav);
            return true;
        }
        return false;
    }

    function onSelect() as Boolean {
        openMenu();
        return true;
    }

    function onMenu() as Boolean {
        openMenu();
        return true;
    }

    hidden function openMenu() as Void {
        var menu = new WatchUi.Menu2({:title => Fmt.str(Rez.Strings.Menu)});
        menu.addItem(new WatchUi.MenuItem(Fmt.str(Rez.Strings.AddFavorite), null, :add, null));
        WatchUi.pushView(menu, new OverviewMenuDelegate(_view), WatchUi.SLIDE_UP);
    }
}

class OverviewMenuDelegate extends WatchUi.Menu2InputDelegate {
    hidden var _view as OverviewView;

    function initialize(view as OverviewView) {
        Menu2InputDelegate.initialize();
        _view = view;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        if (item.getId() == :add) {
            new AddFavoriteFlow(_view.method(:openFavorite)).start();
        }
    }
}
```
Add `import Toybox.System;` at the top of this file.

- [ ] **Step 8: Modify `source/ui/DeparturesView.mc`**
- Replace `function initialize() {` and its first line with:
```monkeyc
    function initialize(startIndex as Number) {
        View.initialize();
        index = startIndex;
```
- In `onUpdate`, replace the stop-name line:
```monkeyc
        dc.drawText(cx, h * 0.27, Graphics.FONT_XTINY, fav["stopName"] as String, center);
```
with:
```monkeyc
        var window = Model.windowText(fav);
        var stopLine = (window == null) ? fav["stopName"] as String : (fav["stopName"] as String) + "  " + window;
        dc.drawText(cx, h * 0.27, Graphics.FONT_XTINY, stopLine, center);
```

- [ ] **Step 9: Modify `source/ui/DeparturesDelegate.mc`**: swiping past the ends goes to the overview

Replace `onNextPage` and `onPreviousPage` with:
```monkeyc
    function onNextPage() as Boolean {
        var n = FavoritesStore.count();
        if (n == 0) {
            return true;
        }
        if (_view.index + 1 >= n) {
            Pages.showOverview(WatchUi.SLIDE_UP);
        } else {
            _view.showIndex(_view.index + 1);
        }
        return true;
    }

    function onPreviousPage() as Boolean {
        var n = FavoritesStore.count();
        if (n == 0) {
            return true;
        }
        if (_view.index == 0) {
            Pages.showOverview(WatchUi.SLIDE_DOWN);
        } else {
            _view.showIndex(_view.index - 1);
        }
        return true;
    }
```

- [ ] **Step 10: Modify `source/GarminBusApp.mc` `getInitialView()`**

```monkeyc
    function getInitialView() {
        if (FavoritesStore.count() == 0) {
            var empty = new DeparturesView(0);   // empty state auto-starts the Add flow
            return [empty, new DeparturesDelegate(empty)];
        }
        var view = new OverviewView();
        return [view, new OverviewDelegate(view)];
    }
```

- [ ] **Step 11: Run `make test`. It should pass** (38 tests). Build all three devices with no new warnings.

- [ ] **Step 12: Commit** `feat: overview page with tap-to-open and page navigation`

---

### Task 4: Menu: move up/down, time window flow

**Files:**
- Create: `source/ui/TimeWindowFlow.mc`
- Modify: `source/ui/DeparturesDelegate.mc` (`openMenu`), `source/ui/FavoritesMenuDelegate.mc`, `resources/strings/strings.xml`

**Interfaces:**
- Consumes: `FavoritesStore.moveUp/moveDown/moveToTop/remove/setWindow/count`, `IndexMenuDelegate(onChosen, onBack)` (onBack may be null; it pops the view), `DeparturesView.index/showIndex`
- Produces: `new TimeWindowFlow(index as Number, onDone as Method).start()`, where `onDone` is `(index as Number) as Void`

- [ ] **Step 1: Add strings** (before `</strings>`):

```xml
    <string id="MoveUp">Flytt opp</string>
    <string id="MoveDown">Flytt ned</string>
    <string id="TimeWindow">Tidsvindu</string>
    <string id="AllDay">Hele dagen</string>
    <string id="StartHour">Fra kl.</string>
    <string id="EndHour">Til kl.</string>
```

- [ ] **Step 2: Create `source/ui/TimeWindowFlow.mc`**

```monkeyc
import Toybox.Lang;
import Toybox.WatchUi;

// Menu flow: "Fra kl." (Hele dagen | 00-23) -> "Til kl." (next 23 hours, shown 01-24) -> save.
class TimeWindowFlow {
    const ALL_DAY = -1;

    hidden var _index as Number;
    hidden var _onDone as Method;
    hidden var _from = 0;

    function initialize(index as Number, onDone as Method) {
        _index = index;
        _onDone = onDone;
    }

    function start() as Void {
        var menu = new WatchUi.Menu2({:title => Fmt.str(Rez.Strings.StartHour)});
        menu.addItem(new WatchUi.MenuItem(Fmt.str(Rez.Strings.AllDay), null, ALL_DAY, null));
        for (var h = 0; h < 24; h++) {
            menu.addItem(new WatchUi.MenuItem(h.format("%02d"), null, h, null));
        }
        WatchUi.pushView(menu, new IndexMenuDelegate(method(:onStart), null), WatchUi.SLIDE_LEFT);
    }

    function onStart(h as Number) as Void {
        if (h == ALL_DAY) {
            finish(null, null);
            return;
        }
        _from = h;
        var menu = new WatchUi.Menu2({:title => Fmt.str(Rez.Strings.EndHour)});
        for (var k = 1; k < 24; k++) {
            var end = h + k;
            if (end > 24) {
                end -= 24;
            }
            menu.addItem(new WatchUi.MenuItem(end.format("%02d"), null, end, null));
        }
        WatchUi.switchToView(menu, new IndexMenuDelegate(method(:onEnd), null), WatchUi.SLIDE_LEFT);
    }

    function onEnd(end as Number) as Void {
        finish(_from, end);
    }

    hidden function finish(fromH as Number or Null, toH as Number or Null) as Void {
        FavoritesStore.setWindow(_index, fromH, toH);
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        _onDone.invoke(_index);
    }
}
```

- [ ] **Step 3: Replace `openMenu()` in `source/ui/DeparturesDelegate.mc`**

```monkeyc
    hidden function openMenu() as Void {
        var n = FavoritesStore.count();
        var i = _view.index;
        var menu = new WatchUi.Menu2({:title => Fmt.str(Rez.Strings.Menu)});
        menu.addItem(new WatchUi.MenuItem(Fmt.str(Rez.Strings.AddFavorite), null, :add, null));
        if (n > 0) {
            if (i > 0) {
                menu.addItem(new WatchUi.MenuItem(Fmt.str(Rez.Strings.MoveUp), null, :up, null));
            }
            if (i < n - 1) {
                menu.addItem(new WatchUi.MenuItem(Fmt.str(Rez.Strings.MoveDown), null, :down, null));
            }
            if (i > 0) {
                menu.addItem(new WatchUi.MenuItem(Fmt.str(Rez.Strings.MoveToTop), null, :top, null));
            }
            menu.addItem(new WatchUi.MenuItem(Fmt.str(Rez.Strings.TimeWindow), null, :window, null));
            menu.addItem(new WatchUi.MenuItem(Fmt.str(Rez.Strings.DeleteFavorite), null, :delete, null));
        }
        WatchUi.pushView(menu, new FavoritesMenuDelegate(_view), WatchUi.SLIDE_UP);
    }
```

- [ ] **Step 4: Replace `onSelect` in `source/ui/FavoritesMenuDelegate.mc`**

```monkeyc
    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        var i = _view.index;
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        if (id == :add) {
            new AddFavoriteFlow(_view.method(:showIndex)).start();
        } else if (id == :up) {
            FavoritesStore.moveUp(i);
            _view.showIndex(i - 1);
        } else if (id == :down) {
            FavoritesStore.moveDown(i);
            _view.showIndex(i + 1);
        } else if (id == :top) {
            FavoritesStore.moveToTop(i);
            _view.showIndex(0);
        } else if (id == :window) {
            new TimeWindowFlow(i, _view.method(:showIndex)).start();
        } else if (id == :delete) {
            FavoritesStore.remove(i);
            _view.showIndex(0);
        }
    }
```

- [ ] **Step 5: Run `make test`. It should pass** (38). Build all three devices with no new warnings.

- [ ] **Step 6: Commit** `feat: move up/down and time window menu`

---

### Task 5 (user): Manual verification on Venu 4

1. Open the menu on favorite 1 → Tidsvindu → 05 → 12. The stop line shows `05-12`.
2. Favorite 2 → Tidsvindu → 12 → 24.
3. Glance: shows 2 rows. The active favorite comes first, and the order flips at 12:00.
4. Open the app: the overview shows "Neste avganger" and rows in the same order. Tapping a row opens that favorite's page.
5. Swipe: overview → fav 1 → fav 2 → overview. Swiping the other way goes in reverse.
6. Flytt opp / Flytt ned: the page follows the moved favorite, and the items are hidden at the edges.
7. Tidsvindu → Hele dagen clears the window.
