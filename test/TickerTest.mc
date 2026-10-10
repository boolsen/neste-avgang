import Toybox.Lang;
import Toybox.Test;

(:test)
function testTickerNoOverflowNeverMoves(logger as Logger) as Boolean {
    return Check.eq(logger, "0", Ticker.offset(0, 0), 0)
        && Check.eq(logger, "neg", Ticker.offset(5000, -10), 0);
}

(:test)
function testTickerPauseScrollPause(logger as Logger) as Boolean {
    // overflow 120 px at 60 px/s -> 2000 ms scroll; cycle = 1500 + 2000 + 1500 = 5000 ms
    return Check.eq(logger, "start pause", Ticker.offset(0, 120), 0)
        && Check.eq(logger, "end of start pause", Ticker.offset(1499, 120), 0)
        && Check.eq(logger, "mid scroll", Ticker.offset(2500, 120), 60)
        && Check.eq(logger, "end pause", Ticker.offset(3600, 120), 120)
        && Check.eq(logger, "end pause last", Ticker.offset(4999, 120), 120)
        && Check.eq(logger, "next cycle", Ticker.offset(5000, 120), 0)
        && Check.eq(logger, "next cycle scroll", Ticker.offset(7500, 120), 60);
}
