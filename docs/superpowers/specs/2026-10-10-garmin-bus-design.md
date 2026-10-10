# Garmin Bus — Design

## Goal

A Connect IQ glance + app for Garmin watches that shows the next 2–3 real-time departures for a user-chosen **line at a specific platform** (which implies direction). Norway first (Entur). The architecture lets other countries' APIs be added as new providers without UI changes.

## Why build it

Existing apps (e.g. Mobi) only let you save favorite *stops*. They list every line in both directions, and they match stops by name ("Gyldenprisveien" also matches "Gyldenprisveien nord"). This app saves one exact platform + line and shows only those departures.

## Scope

- Target: Venu / Vivoactive family (touchscreen, glance support). Exact model is confirmed in Milestone 1 and used as the primary simulator target.
- Distribution: personal sideload. The Connect IQ Store is out of scope.
- Watch-only. No proxy server.

## User experience

**Glance** (in the watch's glance loop): first favorite only, fetched live when the glance is shown.
`10 Gyldenprisveien · 3 min`

**App view** (tap glance): one page per favorite, swipe between them.
- Header: line number + stop name
- Next 2–3 departures in minutes (`Nå`, `3 min`, `11 min`), each with destination text and a marker if the time is real-time rather than scheduled
- Footer: `oppdatert hh:mm`
- Refreshes on open and every 30 s while visible

**Menu**: Add favorite, Delete favorite, Move favorite to top.

**Add favorite flow**:
1. Get GPS fix (show "Finner posisjon…"; retry option on timeout).
2. List nearest stops (stop places within ~500 m, max 10) with distance.
3. Pick stop → list of lines + directions served there. Each entry = one (quay, line) pair, labelled with line number and the destination text(s) seen at that quay, e.g. `10 → Søndre Skogveien / Wergeland`, `10 → Mulen`, `20 → Nesttun terminal`.
4. Pick entry → saved as favorite (appended to the end of the list).

## Architecture

```
GlanceView ─┐
AppViews ───┼─> DepartureService ──> Provider (interface)
AddFlow ────┘        │                 └─ EnturProvider
                     │
              FavoritesStore (Application.Storage)
```

### Common models (the parsing boundary)
UI and service code only ever see these. No provider JSON leaks past a provider.
- `Favorite { providerId, stopId, stopName, quayId, lineId, lineCode, label }`
- `Departure { lineCode, destination, departureEpoch, isRealtime }`
- `NearbyStop { stopId, name, distanceM }`
- `LineOption { quayId, lineId, lineCode, label }`

### Provider interface
Each provider builds requests and parses responses into the common models:
- `buildDeparturesRequest(favorite, count)` → `{ url, params, options }`
- `parseDepartures(responseData)` → `Array<Departure>` or error
- `buildNearbyStopsRequest(lat, lon)` / `parseNearbyStops(data)`
- `buildLineOptionsRequest(stopId)` / `parseLineOptions(data)`

A `ProviderRegistry` maps `providerId` → provider instance. Each favorite stores its `providerId`, so adding Sweden later means one new provider class plus a registry entry.

### DepartureService
Calls `Communications.makeWebRequest` with the provider's request and passes the result to the provider's parser. It caches the last successful result per favorite in memory and storage, and reports errors as a small enum (`NO_PHONE`, `HTTP_ERROR`, `PARSE_ERROR`, `NO_DEPARTURES`).

### FavoritesStore
Ordered list of `Favorite` dictionaries in `Application.Storage`.

## Entur provider

- Endpoint: `POST https://api.entur.io/journey-planner/v3/graphql`
- Headers: `ET-Client-Name: <owner>-garminbus`, `Content-Type: application/json`. No API key.
- **Departures**: `quay(id) { estimatedCalls(numberOfDepartures: N, whiteListed: { lines: [lineId] }) { expectedDepartureTime realtime destinationDisplay { frontText } serviceJourney { line { publicCode } } } }`
- **Nearby stops**: `nearest(latitude, longitude, maximumDistance: 500, filterByPlaceTypes: [stopPlace], first: 10)`
- **Line options for a stop**: `stopPlace(id) { quays { id estimatedCalls(numberOfDepartures: ~20, timeRange: ~2h) { destinationDisplay { frontText } serviceJourney { line { id publicCode } } } } }`. Group by (quay, line) and collect distinct destination texts for the label.
- Queries request only the fields above to keep responses small (watch memory limits).
- Verified 2026-10-10: Gyldenprisveien (`NSR:StopPlace:29169`) has quays `NSR:Quay:50123` (lines 10 and 20 one way) and `NSR:Quay:50122` (line 10 → Mulen). This confirms that quay + line is the right favorite key and that destination text is not, since one line shows several destination texts in the same direction.
- Time parsing: ISO-8601 with offset (e.g. `2026-10-10T10:00:46+02:00`) → epoch seconds; minutes until departure = `(epoch − now) / 60`, floored, `0` shown as `Nå`.

## Error handling

| Situation | Shown |
|---|---|
| Phone not connected | `Ingen telefon` + cached departures with age |
| HTTP / network error | `Feil (kode)` + cached departures with age |
| No departures returned | `Ingen avganger` |
| GPS timeout | `Fant ikke posisjon` + Retry |
| No favorites | Glance: `Legg til favoritt`; App: opens the Add flow |

Cached departures whose time has already passed are dropped before display.

## Testing

- Provider parsing: Connect IQ `(:test)` unit tests using captured Entur JSON responses as fixtures (departures, nearest, stop line options, empty result).
- Time/minutes formatting: unit tests.
- UI and network: manual testing in the simulator, then on the watch.

## Milestones

1. **Toolchain**: install the Connect IQ SDK, VS Code Monkey C extension, and a developer key; confirm the watch model; run "hello" in the simulator and sideload it to the watch.
2. **Hardcoded pipeline**: one hardcoded favorite (Gyldenprisveien quay + line) → live departures in app view and glance.
3. **Provider layer**: extract the Provider interface, common models, and EnturProvider; add fixture-based tests.
4. **Favorites + Add flow**: GPS nearby → stop → line/direction → save; multiple favorites with swipe; delete/move to top.
5. **Polish**: error states, caching, 30 s refresh, layout tuned for the target screen.

Each milestone ends with a working build on the watch.

## Out of scope (for now)

Other countries, proxy server, watch face/complication, Connect IQ Store publishing, trip planning, ticketing.
