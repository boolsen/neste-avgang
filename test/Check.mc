import Toybox.Lang;
import Toybox.Test;

module Check {
    // Value equality (equals) with null handling; logs on mismatch.
    function eq(logger as Logger, name as String, actual, expected) as Boolean {
        var ok = (actual == null || expected == null) ? actual == expected : actual.equals(expected);
        if (!ok) {
            logger.error(name + ": expected <" + expected + "> got <" + actual + ">");
        }
        return ok;
    }
}
