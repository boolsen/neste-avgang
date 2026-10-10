# Ticker Rows Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** In the glance and the overview, show each row as the time first (never cut), followed by `<line> > <direction>  <stop>`, which scrolls (pause → scroll → pause) when it doesn't fit.

**Architecture:**
- `Ticker` is a pure function of elapsed ms and overflow px, unit-tested.
- `RowPainter` (glance-safe) draws one row: the time, then the info text clipped and offset.
- The glance and `OverviewView` use `RowPainter`, plus a 150 ms animation timer that runs only while a row overflows.

**Spec:** `docs/superpowers/specs/2026-10-10-favorites-v2-design.md`, section "Addendum: time-first rows with scrolling text".

## Global Constraints

- Devices: `venu445mm`, `venu441mm`, `vivoactive6`. Build all three, with no new warnings.
- Glance-reachable code must be `(:glance)`. No literal UI text in `.mc`, except separators (`"  "`).
- Ticker constants: `PAUSE_MS = 1500`, `SPEED_PX_S = 40`, `FRAME_MS = 150`, gap between time and info `GAP_PX = 8`.
- The animation timer runs only while the view is visible and at least one row overflows. Stop it in `onHide`.
- `make test`: reuse a running simulator, or start one with `make sim` (wait ~8 s) and `pkill -f "ConnectIQ.app"` afterwards. The exit status reflects pass/fail.
- End commit messages with a blank line, then `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

---

### Task 1: Ticker math + FavoriteRow info text

**Files:**
- Create: `source/core/Ticker.mc`, `test/TickerTest.mc`
- Modify: `source/core/FavoriteRow.mc` (replace `title()` and `text()` with `info()`), `test/FavoriteRowTest.mc`, `test/RowFetcherTest.mc`

**Interfaces:**
- Produces:
  - `Ticker.offset(elapsedMs as Number, overflowPx as Number) as Number`: 0 when `overflowPx <= 0`.
  - `FavoriteRow.info() as String`: `label + "  " + stopName`.
  - `FavoriteRow.status(now)`: unchanged.
  - `title()` and `text()` are removed.

- [ ] **Step 1: Write failing tests `test/TickerTest.mc`**

```monkeyc
import Toybox.Lang;
import Toybox.Test;

(:test)
function testTickerNoOverflowNeverMoves(logger as Logger) as Boolean {
    return Check.eq(logger, "0", Ticker.offset(0, 0), 0)
        && Check.eq(logger, "neg", Ticker.offset(5000, -10), 0);
}

(:test)
function testTickerPauseScrollPause(logger as Logger) as Boolean {
    // overflow 80 px at 40 px/s -> 2000 ms scroll; cycle = 1500 + 2000 + 1500 = 5000 ms
    return Check.eq(logger, "start pause", Ticker.offset(0, 80), 0)
        && Check.eq(logger, "end of start pause", Ticker.offset(1499, 80), 0)
        && Check.eq(logger, "mid scroll", Ticker.offset(2500, 80), 40)
        && Check.eq(logger, "end pause", Ticker.offset(3600, 80), 80)
        && Check.eq(logger, "end pause last", Ticker.offset(4999, 80), 80)
        && Check.eq(logger, "next cycle", Ticker.offset(5000, 80), 0)
        && Check.eq(logger, "next cycle scroll", Ticker.offset(7500, 80), 40);
}
```

- [ ] **Step 2: Update `test/FavoriteRowTest.mc`.** Replace `testFavoriteRowTitleAndLoading` with:

```monkeyc
(:test)
function testFavoriteRowInfoAndLoading(logger as Logger) as Boolean {
    Application.Storage.deleteValue(DepartureCache.key(rowFav()));
    var row = new FavoriteRow(rowFav());
    return Check.eq(logger, "info", row.info(), "10 > Mulen  Gyldenprisveien")
        && Check.eq(logger, "loading", row.status(1000), "Henter…");
}
```
In `test/RowFetcherTest.mc`, replace the assertion `row.text(1000), "10 Gyldenprisveien: Henter…"` with `row.status(1000), "Henter…"`. Keep its name `"row untouched"`.

- [ ] **Step 3: Run `make test`. It should fail** (compile errors: `Ticker`, `info` are undefined).

- [ ] **Step 4: Create `source/core/Ticker.mc`**

```monkeyc
import Toybox.Lang;

// Scroll offset for text wider than its area: pause, scroll left, pause, jump back.
(:glance)
module Ticker {
    const PAUSE_MS = 1500;
    const SPEED_PX_S = 40;

    function offset(elapsedMs as Number, overflowPx as Number) as Number {
        if (overflowPx <= 0) {
            return 0;
        }
        var scrollMs = overflowPx * 1000 / SPEED_PX_S;
        var t = elapsedMs % (PAUSE_MS + scrollMs + PAUSE_MS);
        if (t < PAUSE_MS) {
            return 0;
        }
        if (t < PAUSE_MS + scrollMs) {
            return (t - PAUSE_MS) * SPEED_PX_S / 1000;
        }
        return overflowPx;
    }
}
```

- [ ] **Step 5: In `source/core/FavoriteRow.mc`,** replace `title()` and `text()` with:

```monkeyc
    // Text shown after the time: "<line> > <direction>  <stop>".
    function info() as String {
        return (fav["label"] as String) + "  " + (fav["stopName"] as String);
    }
```
Update the class comment to: `// One favorite's row state for multi-row screens (glance, overview): time/status + info text.`

The glance and overview still call `text()` until Task 2. To keep this commit compiling, also apply this temporary bridge in both `source/ui/BusGlanceView.mc` and `source/ui/OverviewView.mc`: replace each `.text(now)` call with `.status(now) + "  " + <same row>.info()`. Task 2 rewrites these spots anyway.

- [ ] **Step 6: Run `make test`. It should pass** (39 − 1 + 1 + 2 = 41). Build all three devices.

- [ ] **Step 7: Commit** `feat: ticker offset math and row info text`

---

### Task 2: RowPainter + animated glance and overview

**Files:**
- Create: `source/ui/RowPainter.mc`
- Modify: `source/ui/BusGlanceView.mc`, `source/ui/OverviewView.mc`

**Interfaces:**
- Consumes: `Ticker.offset`, `FavoriteRow.status(now)`, `FavoriteRow.info()`, `OverviewLayout.rowY/rowWidth`
- Produces: `RowPainter.draw(dc, x as Number, y as Number, width as Number, font, row as FavoriteRow, now as Number, elapsedMs as Number) as Boolean`, which returns true if the info text overflows (the row needs animating).

- [ ] **Step 1: Create `source/ui/RowPainter.mc`**

```monkeyc
import Toybox.Graphics;
import Toybox.Lang;

// Draws one row: time/status (white, left, never cut) + info text (grey) clipped to the rest,
// scrolled by Ticker when it doesn't fit. Returns true when the info text overflows.
(:glance)
module RowPainter {
    const GAP_PX = 8;

    function draw(dc as Graphics.Dc, x as Number, y as Number, width as Number, font as Graphics.FontType,
            row as FavoriteRow, now as Number, elapsedMs as Number) as Boolean {
        var vcenter = Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER;
        var status = row.status(now);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, status, vcenter);

        var infoX = x + dc.getTextWidthInPixels(status, font) + GAP_PX;
        var infoW = x + width - infoX;
        if (infoW <= 0) {
            return false;
        }
        var info = row.info();
        var overflow = dc.getTextWidthInPixels(info, font) - infoW;
        var fh = dc.getFontHeight(font);
        dc.setClip(infoX, y - fh / 2, infoW, fh);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(infoX - Ticker.offset(elapsedMs, overflow), y, font, info, vcenter);
        dc.clearClip();
        return overflow > 0;
    }
}
```

- [ ] **Step 2: Update `source/ui/BusGlanceView.mc`**
  - Add `import Toybox.System;` and `import Toybox.Timer;`.
  - Add the constant `const FRAME_MS = 150;` and the fields:
    ```monkeyc
    hidden var _animTimer = null;
    hidden var _animating = false;
    hidden var _overflow = false;
    hidden var _startMs = 0;
    ```
  - In `onShow()`, at the end, add `_startMs = System.getTimer();`.
  - In `onHide()`, add `stopAnimation();`.
  - Replace `onUpdate` and remove `drawFitted`:

```monkeyc
    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        if (_rows.size() == 0) {
            dc.drawText(0, h / 2, Graphics.FONT_TINY, Fmt.str(Rez.Strings.AddFavorite),
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }
        var now = Time.now().value();
        var elapsed = System.getTimer() - _startMs;
        var font = Graphics.FONT_XTINY;
        var overflow = false;
        if (_rows.size() == 1) {
            overflow = RowPainter.draw(dc, 0, h / 2, w, font, _rows[0] as FavoriteRow, now, elapsed);
        } else {
            overflow = RowPainter.draw(dc, 0, (h * 0.3).toNumber(), w, font, _rows[0] as FavoriteRow, now, elapsed);
            overflow = RowPainter.draw(dc, 0, (h * 0.72).toNumber(), w, font, _rows[1] as FavoriteRow, now, elapsed) || overflow;
        }
        _overflow = overflow;
        if (_overflow && !_animating) {
            startAnimation();
        }
    }

    function onFrame() as Void {
        if (!_overflow) {
            stopAnimation();
            return;
        }
        WatchUi.requestUpdate();
    }

    hidden function startAnimation() as Void {
        if (_animTimer == null) {
            _animTimer = new Timer.Timer();
        }
        _animTimer.start(method(:onFrame), FRAME_MS, true);
        _animating = true;
    }

    hidden function stopAnimation() as Void {
        if (_animTimer != null) {
            _animTimer.stop();
        }
        _animating = false;
    }
```

- [ ] **Step 3: Update `source/ui/OverviewView.mc`** in the same way:
  - Add `import Toybox.System;` and `const FRAME_MS = 150;`.
  - Add the same four fields (`_animTimer`, `_animating`, `_overflow`, `_startMs`) and the same `onFrame`, `startAnimation` and `stopAnimation` as in Step 2. The code is duplicated on purpose: two small views, and a shared base class would be overkill.
  - In `onShow()`, at the end, add `_startMs = System.getTimer();`. In `onHide()`, add `stopAnimation();`.
  - Replace the row loop in `onUpdate` (from `dc.setColor(Graphics.COLOR_WHITE, ...)` after the title to the end) with:

```monkeyc
        var now = Time.now().value();
        var elapsed = System.getTimer() - _startMs;
        var font = Graphics.FONT_TINY;
        var overflow = false;
        for (var i = 0; i < _rows.size(); i++) {
            var rw = OverviewLayout.rowWidth(i, w, h);
            overflow = RowPainter.draw(dc, (w - rw) / 2, OverviewLayout.rowY(i, h), rw, font,
                _rows[i] as FavoriteRow, now, elapsed) || overflow;
        }
        _overflow = overflow;
        if (_overflow && !_animating) {
            startAnimation();
        }
```

- [ ] **Step 4: Run `make test`. It should pass** (41). Build all three devices with no new warnings. `grep -rn "\.text(\|title()" source test` should return nothing.

- [ ] **Step 5: Commit** `feat: time-first rows with scrolling info in glance and overview`

---

### Task 3 (user): device check on Venu 4
1. Glance: the time is always visible. Long rows pause, scroll left, pause, then jump back. Note whether the glance animates at all.
2. Overview: the same for up to 4 rows, and nothing runs off the round edge.
3. Leave the glance or overview, then come back: the animation restarts from the beginning.
