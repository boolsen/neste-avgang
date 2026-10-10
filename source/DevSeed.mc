import Toybox.Lang;

// Temporary hardcoded favorite until the Add flow exists (deleted in Task 8).
module DevSeed {
    function favorite() as Dictionary {
        return Model.favorite("entur", "NSR:StopPlace:29169", "Gyldenprisveien", "NSR:Quay:50122", "SKY:Line:10", "10", "10 > Mulen");
    }
}
