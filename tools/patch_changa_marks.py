#!/usr/bin/env python3
"""Make Changa 3.003 keep Arabic words whole when a shadda carries a haraka.

Changa 3.003 (Google Fonts, googlefonts/changa-vf fb3207d, the latest
release) composes a shadda and the haraka on it (fatha, damma, kasra, the
three tanween, superscript alef; either order) into one glyph in its `ccmp`
feature (GSUB lookup 5): `shaddaFathaar` and its siblings. The same lookup
joins a hamza typed as a mark (U+0654, U+0655) with its haraka. Those
glyphs are classed as base glyphs (GDEF class 1), are 269 to 358 units
wide and have no mark anchor. So a shaper sets them as a letter of their
own between two letters: the word is torn apart and the marks leave their
letter (مُحَمَّد، إِنَّ، يُعدَّل).

The fix takes lookup 5 out of `ccmp` and nothing else: the shadda and the
haraka then stay two marks, and the font's own `mark` and `mkmk` features
put the shadda (or hamza) on its letter and the haraka on it (the kasra
and kasratan under the letter). The glyphs stay in the font, unused. Changa
has no Reserved Font Name, so the OFL lets the modified font keep its name;
the version string records the change.

Usage: python3 tools/patch_changa_marks.py UPSTREAM.ttf OUT.ttf
UPSTREAM.ttf must be the published file (its SHA-256 is checked).
"""

import hashlib
import sys

from fontTools.ttLib import TTFont

UPSTREAM_SHA256 = (
    "7c4f7a14d4b70ac8816ea8df3a0b127aee4c5f5af7239aca2afecc84ddc7f4d3"
)
MARK_LIGATURES = {
    "shaddaFathaar",
    "shaddaDammaar",
    "shaddaKasraar",
    "shaddaFathatanar",
    "shaddaDammatanar",
    "shaddaKasratanar",
    "shaddaAlefabovear",
    "hamzaaboveFathaar",
    "hamzaaboveDammaar",
    "hamzaaboveFathatanar",
    "hamzaaboveDammatanar",
    "hamzaaboveSukunar",
    "hamzabelowKasraar",
    "hamzabelowKasratanar",
}
VERSION_NOTE = (
    "; Tibyan: shadda/hamza and haraka as two marks (ccmp lookup 5 off)"
)


def mark_ligature_lookups(gsub):
    """Indices of the ligature lookups that join two marks into one glyph."""
    found = set()
    for i, lookup in enumerate(gsub.LookupList.Lookup):
        for sub in lookup.SubTable:
            if lookup.LookupType == 7:
                sub = sub.ExtSubTable
            if getattr(sub, "LookupType", lookup.LookupType) != 4:
                continue
            outs = {
                lig.LigGlyph for ligs in sub.ligatures.values() for lig in ligs
            }
            if outs & MARK_LIGATURES:
                if not outs <= MARK_LIGATURES:
                    sys.exit(f"lookup {i} makes other ligatures too: stop")
                found.add(i)
    return found


def main(src, dst):
    data = open(src, "rb").read()
    digest = hashlib.sha256(data).hexdigest()
    if digest != UPSTREAM_SHA256:
        sys.exit(f"{src}: SHA-256 {digest}, expected the Changa 3.003 release")
    font = TTFont(src, recalcTimestamp=False)
    gsub = font["GSUB"].table
    drop = mark_ligature_lookups(gsub)
    if drop != {5}:
        sys.exit(f"expected lookup 5 only, found {sorted(drop)}")
    for record in gsub.FeatureList.FeatureRecord:
        feature = record.Feature
        kept = [i for i in feature.LookupListIndex if i not in drop]
        if len(kept) != len(feature.LookupListIndex):
            if record.FeatureTag != "ccmp":
                sys.exit(f"lookup 5 is also in {record.FeatureTag}: stop")
            feature.LookupListIndex = kept
            feature.LookupCount = len(kept)
    name = font["name"]
    for rec in name.names:
        if rec.nameID == 5 and VERSION_NOTE not in rec.toUnicode():
            rec.string = rec.toUnicode() + VERSION_NOTE
    font.save(dst)
    print(dst, hashlib.sha256(open(dst, "rb").read()).hexdigest())


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
