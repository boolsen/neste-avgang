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
