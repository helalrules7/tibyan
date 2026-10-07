# Sajdah timer (مؤقت سجدات التلاوة) — design

Ahmed approved this design on 2026-10-07.

## Goal

When the recitation reaches a verse of prostration, the app pauses and
shows a small card. The card holds the sajdah's supplications and a
countdown. When the countdown ends, the card fades out and the recitation
resumes. Touch reading shows the same card, without audio. The feature is
off unless the reader turns it on.

## Settings

The listening settings get two new entries:

- **«مؤقت سجدات التلاوة»**: an on/off switch. It is off by default.
- **The timer's length**: 10, 15, 20, 30, 45 or 60 seconds. The default is
  20. This entry shows only while the switch is on.

Both are saved like the other settings.

## When the card shows

**While listening:**

- When the reciter finishes a sajdah verse, the player pauses on its own
  and the card shows.
- When the countdown ends, the card fades out and the player resumes.
- If the verse is repeated (the repeat setting), the card shows after the
  last repetition only.
- The card never shows during tafsir or translation clips, nor in a hifz
  test.

**Touch reading:**

- The card shows as soon as the reader touches the verse that follows a
  sajdah verse.
- It uses the same countdown. There is no audio.

**«آية آية» (one verse a screen):**

- The card shows as soon as the reader moves to the verse that follows a
  sajdah verse: a swipe, the big arrow buttons, or the auto-turn.
- While the card is up, the auto-turn countdown waits; it starts again
  only once the card closes (its countdown ends, or a tap).
- While the recitation plays there, the listening rule applies: the pause
  at the sajdah verse's end, the card, then the recitation goes on. The
  screen following the recitation to the next verse does not show the
  card a second time.
- The same card, over the verse.

**Editions:** the card works in every edition, in line with edition parity.

## The card

- **Size and place:** centred on the screen. Its width is about 85% of a
  phone and at most 420 pt. Its height keeps to 40% of the screen. The
  supplications are never scrolled (Ahmed, 2026-10-07): when they do not
  fit, they first shrink to a floor, then the pictogram and the countdown
  shrink, and only then does the card grow (at most 90%), as in elderly
  mode on a small phone.
- **Look:** a translucent background (the theme's paper colour, slightly
  see-through) that keeps the text readable in every theme and mode. It
  fades in and out in about 250 ms, and appears at once when the system
  asks for less motion.
- **Contents, from top to bottom:**
  - a prostration pictogram (a person in sujood: knees, hands and forehead
    on the ground), Tibyan's own single-colour SVG
    (`assets/ornaments/sajdah.svg`), tinted with the theme's control
    colour so it reads in every theme and mode;
  - the supplications, copied verbatim from Hisn al-Muslim (see
    *Sources*);
  - a circular countdown;
  - a small line «اضغط للاستكمال».
- **A tap** closes the card at once and resumes the recitation.
- **Screen readers** announce the card, and its button resumes.

## Sources

The golden rule applies: never generate, alter or paraphrase religious text.

- **Supplications:**
  - Copy them verbatim from a published copy of Hisn al-Muslim (حصن المسلم,
    Sa'id ibn Wahf al-Qahtani): the chapter on the sajdah of recitation, and
    the chapter on the supplications of prostration for «سُبْحَانَ رَبِّيَ
    الأَعْلَى» and «سُبْحَانَكَ اللَّهُمَّ رَبَّنَا وَبِحَمْدِكَ، اللَّهُمَّ
    اغْفِرْ لِي».
  - Mirror the source on the server under `mirror/sources/<name>/`, with
    SHA256SUMS checked there.
  - Record the source in `docs/DATA_SOURCES.md`, and list it in
    `docs/MISSING_DATA.md` for the scholarly review.
  - The owner's draft:

    > قال ﷺ: «سَجَدَ وَجْهِي للَّذِي خَلَقَهُ، وَشَقَّ سَمْعَهُ وَبَصَرَهُ
    > بِحَوْلِهِ وَقُوَّتِهِ، فَتَبَارَكَ اللَّهُ أَحْسَنُ الْخَالِقِينَ»
    > / «سُبْحَانَ رَبِّيَ الأَعْلَى» (ثلاث مرات أو مرة واحدة)، أو
    > «سُبْحَانَكَ اللَّهُمَّ رَبَّنَا وَبَحْمَدِكَ، اللَّهُمَّ اغْفِرْ لي»

    If the source differs from this draft in any letter or mark, stop and
    report the difference before writing it into the app.
- **Hafs positions:** the `ayah.sajda` column of content.db: 15 verses from
  Tanzil, marked recommended or obligatory.
- **The riwayat:**
  - Look for the sajdah sign ۩ (U+06E9) in each riwaya's KFGQPC text that
    the app already ships.
  - If a riwaya has no such marks, stop and report before deciding
    anything.
  - Record what was found in `docs/DATA_SOURCES.md`.

## Testing

- **Unit tests:** the settings (default, saved, range), and the sajdah
  positions for Hafs and for each riwaya found.
- **Flow tests:**
  - With a fake recitation, a sajdah verse's end pauses the player and
    shows the card; the countdown resumes it, and a tap resumes it at once.
  - With repetition, the card shows after the last repetition only.
  - Touch reading on the next verse shows the card.
  - With the setting off, nothing happens.
  - At the five sizes used by `opening_fit_test`, in elderly mode and in
    the night mode, the card is centred, within 90% of the screen, and its
    text has nothing left to scroll.
- **Previews:** an env-gated render test, uploaded to
  `public_html/previews/sajdah_timer/` with an index.html.
