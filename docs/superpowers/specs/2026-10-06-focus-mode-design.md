# Focus mode (وضع التركيز) — design

Approved by Ahmed on 2026-10-06. The idea came from a user, who showed another
app's frameless page.

## Goal

The reading screen with nothing around the page. There is no frame and nothing
at the bottom, only a thin top bar. The page takes all the room the screen
has. Focus mode is turned on and off in Settings, and turned off from its own
top bar.

## Architecture

- Focus mode is a presentation variant of the existing `MushafScreen`, not a
  new screen or a theme. Touch, tajweed, hifz, tasmee', listening and
  tap-to-jump keep working unchanged.
- It covers every edition (1441, 1405, Shamarly, Warsh and the rest), so
  edition parity holds.
- Theme colours still apply: paper, ink and the night modes. Only the frame
  art goes.

## Settings

A «وضع التركيز» section in Settings holds two controls:

- **The on/off switch.** It is persisted like the other settings.
- **«ملء الشاشة»**, with three choices:
  - **توزيع السطور** (default): each line fills the width at the glyphs' own
    proportions, and the lines are spread over the full height. This is what
    the strip layouts (`StripLayout`, the 1441 `_PageLayout`) already do.
  - **توزيع + مط خفيف**: the same, plus a horizontal stretch of up to 12%
    (`StripLayout.maxStretch`) where the page is fitted to the height.
  - **مط كامل**: the page is scaled on both axes to fill the room. A note
    under it says the letters' shape changes.

## The screen in focus mode

- **No frame at all.** The page's room is the whole screen below the top bar,
  inside the safe area.
- **Nothing at the bottom:**
  - no page number;
  - no `ReadingBar`;
  - no catchword;
  - no hizb-quarter marker.
- **Top bar.** One row, about 32 pt high:
  - right: the surah name;
  - centre: the page number;
  - left: the juz and the hizb quarter, for example «½ الحزب ٢٨» (the same
    text as today's top box);
  - at the far left: three small icon buttons.
- **The three buttons:**
  1. Exit focus mode, back to the normal reading screen.
  2. Show the bottom tools (today's tools). While they are shown, a tap
     anywhere on the page hides them.
  3. Open the main menus, the same as a tap on the frame does today.
- **Taps:**
  - A single tap on the page does nothing while the tools are hidden.
  - A long press on a verse still works (verse services).
  - A tap on a verse while listening still moves the reciter (tap-to-jump).
- **Status bar:** the system status bar is hidden (immersive). The top bar
  respects the notch and the safe area.
- **Two-page spreads** (wide screens): both pages are kept, each in half the
  screen with no frame. There is one top bar, and it names both pages.
- **Opening pages:**
  - al-Fatiha and the start of al-Baqarah have no frame. Their text is as
    wide as the screen and centred vertically; their lines are not spread.
  - The cover stays as it is.
- **Task bars stay:** the hifz-test bar, the selection bar, the word-pick bar
  and the auto-scroll bar still appear when their task is running, as they do
  today.

## Player in focus mode

- A small floating pill, about 40% opaque, fully opaque while touched. It
  holds:
  - one play/pause button;
  - a settings button, which opens the player's settings;
  - a small ×, which stops the recitation and closes the pill.
- It can be dragged anywhere on the screen. Its position is saved and kept
  inside the screen when the size changes.
- It shows only while a recitation is active.

## Elderly mode

Focus mode works with elderly mode on. The top bar, the buttons and the pill
are larger, and every button carries its name, as elsewhere in elderly mode.

## Testing

- Widget tests:
  - the top bar's contents;
  - nothing below the page;
  - the page's rect fills the room (each fill choice), at the five sizes
    used by `opening_fit_test` (iPhone 6.1", iPhone 6.7", iPhone SE, Android,
    laptop);
  - the spread;
  - the opening pages;
  - the three buttons' actions;
  - the tools shown and then hidden by a tap.
- The pill: drag, saved position, clamped to the screen, and the × stops
  playback.
- Previews before and after at the five sizes, uploaded to
  `public_html/previews/focus_mode/` with an index.html.
