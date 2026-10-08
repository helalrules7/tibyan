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

A «وضع التركيز» section in Settings holds three controls:

- **The on/off switch.** It is persisted like the other settings.
- **«إظهار الأدوات»**, with two choices (see *Tools* below):
  - **الزرار البسيط** (default): the top bar's three buttons.
  - **القائمة**: a long press on the page opens a dialog that holds every
    tool.
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
- **Tools.** How the tools are reached depends on «إظهار الأدوات».
- **«الزرار البسيط» (default).** The top bar has three buttons:
  1. Exit focus mode, back to the normal reading screen.
  2. Show the bottom tools (today's tools). While they are shown, a tap
     anywhere on the page hides them.
  3. Open the main menus, the same as a tap on the frame does today.

  A long press on a verse still opens the verse services, as it does today.
- **«القائمة».** The top bar keeps its information and one button, which
  exits focus mode. A long press anywhere on the page opens a dialog that
  holds every tool:
  - The dialog is a window centred on the screen on every device. A tap
    outside it closes it.
  - **Header:** the buttons of today's top bar, such as home, the index,
    search and settings, and the exit from focus mode.
  - **Body:**
    - the verse tools for the verse under the long press (today's verse
      services). This part is left out when the press is not on a verse;
    - the page tools: go to page, bookmarks/fawasil and the other page
      actions.
  - **Footer:** the touch-reading buttons, the page number and the rest of
    today's bottom tools (`ReadingBar`).
- **Taps:**
  - A single tap on the page does nothing while the tools are hidden.
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

## Player style (شكل المشغل)

A «شكل المشغل» setting in Settings applies with focus mode on or off. It has
four choices:

- **تلقائي** (default): the normal player in normal reading, and the focus
  pill while focus mode is on.
- **العادي**: today's player, everywhere.
- **وضع التركيز**: the pill, everywhere:
  - It is small and floating, about 40% opaque, and fully opaque while
    touched.
  - It holds one play/pause button, a settings button (it opens the player's
    settings) and a small × that stops the recitation and closes the pill.
- **الزر الواحد**: one small, translucent round button, everywhere:
  - A tap plays or pauses.
  - A long press opens a small menu with the player's settings, the full
    player, stop and close.
  - A ring around it fills with the progress through the surah.

The pill and the single button share these rules:

- They can be dragged anywhere on the screen.
- Their position is saved, and kept inside the screen when its size changes.
- They show only while a recitation is active.

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
- The pill and the single button: drag, saved position, clamped to the
  screen, the × stops playback, and the single button's tap and long press.
- «شكل المشغل»: each choice with focus mode on and off.
- «القائمة»:
  - a long press opens the dialog, with the verse part present on a verse
    and absent elsewhere;
  - each section's buttons do what their counterparts do today;
  - a tap outside closes it.
- Previews before and after at the five sizes, uploaded to
  `public_html/previews/focus_mode/` with an index.html.
