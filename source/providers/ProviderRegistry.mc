import Toybox.Lang;

// Maps a favorite's "provider" id to its Provider. Register new countries here.
(:glance)
module ProviderRegistry {
    const DEFAULT_ID = "entur";

    function get(id as String) as Provider or Null {
        if (id.equals("entur")) {
            return new EnturProvider();
        }
        return null;
    }
}
