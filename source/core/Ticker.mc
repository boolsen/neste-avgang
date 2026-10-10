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
