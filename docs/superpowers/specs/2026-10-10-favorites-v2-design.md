# Garmin Bus: Favorites v2 (time windows, overview, ranking)

Builds on `2026-10-10-garmin-bus-design.md`. Approved by the user on 2026-10-10.

## Problem

The user's commute has two favorites: the home stop on the way to work and the centre stop on the way back. Today the glance always shows favorite #1, so the user has to reorder favorites twice a day. Ranking is also limited to "Flytt øverst".

## Behaviour

### Time windows
- Each favorite can have an optional hour window `fromH`–`toH`, the same every day.
  - `fromH`: 0–23. `toH`: 1–24, and never equal to `fromH`.
  - A favorite without a window is active all day. Existing stored favorites have no window and keep working unchanged.
- Active test, where `h` is the current local hour:
  - `fromH < toH`: active when `fromH <= h < toH`.
  - `fromH > toH` (crosses midnight, e.g. 22–02): active when `h >= fromH || h < toH`.
- **Display order:** the indexes of the active favorites in rank order, followed by the inactive ones in rank order.

### Glance
- Shows up to 2 rows, taking the first 2 favorites in display order.
- Row format: `<lineCode> <stopName>: <status>`, truncated to fit the width. Status is the next departure's minutes, otherwise an error message, otherwise "Henter…".
- Cached departures are shown first. Live fetches run **one at a time**, so the watch's request queue doesn't overflow.
- With exactly 1 favorite, the glance keeps today's 2-line layout: the label on top, then `stopName: status`.
- With 0 favorites it shows "Legg til favoritt".

### App pages
- **Page 0, the overview:** title "Neste avganger" and up to 4 rows in display order, in the same row format as the glance.
  - Fetches run one at a time and refresh every 30 s.
  - Tapping a row opens that favorite's page.
  - The button or menu opens a menu with only "Legg til favoritt".
- **Pages 1…n:** one page per favorite in rank order, as today. The stop line also shows the window, e.g. `Gyldenprisveien  05-12`.
- **Swiping:** overview → favorite 1 → … → favorite n → overview, wrapping around.
- **Start page:** the app opens on the overview. With no favorites it opens the empty favorite page, which auto-starts the Add flow once, as today.

### Favorite page menu
- Items: Legg til favoritt, Flytt opp, Flytt ned, Flytt øverst, Tidsvindu, Slett favoritt.
- "Flytt opp" and "Flytt øverst" are hidden for the first favorite. "Flytt ned" is hidden for the last.
- After a move, the page follows the moved favorite.
- **Tidsvindu:** a "Fra kl." list with "Hele dagen" plus 00–23. Picking a start hour opens a "Til kl." list of the 23 hours after it (the start hour excluded, shown 01–24, wrapping past midnight). "Hele dagen" clears the window.

## Architecture additions
- `Model.isActive(fav, hour)` and `Model.windowText(fav)`. A favorite's window is stored as optional `"fromH"` and `"toH"` keys.
- `FavoritesStore.moveUp(i)`, `moveDown(i)`, `setWindow(i, fromH, toH)` and `displayOrder(hour)`.
- `TimeUtil.currentHour()`.
- `FavoriteRow`, glance-safe: one favorite's latest departures, error and status text.
- `RowFetcher`, glance-safe: fetches a list of `FavoriteRow`s one at a time.
- `OverviewLayout`: pure row geometry, shared by drawing and tap handling.
- `OverviewView` and `OverviewDelegate`; `Pages` switches between the overview and favorite pages; `TimeWindowFlow`.

## Testing
- **Unit tests:**
  - `isActive`: no window, a normal window, a window past midnight, and a window ending at 24.
  - `windowText`.
  - `moveUp` and `moveDown` at the edges, `setWindow` set and clear, `displayOrder`.
  - `FavoriteRow` status text.
  - `OverviewLayout.rowAt`.
- **Manual:** glance rows, the overview, tap to open, swipe order, and the Tidsvindu flow on Venu 4.

## Out of scope
Weekday-specific windows, choosing a favorite by closest location, and adding stops beyond 500 m.
