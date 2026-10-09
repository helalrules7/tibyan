"""WER / CER per voice group, after the same Arabic normalisation as the
model evaluation (textnorm)."""
from __future__ import annotations

from .textnorm import edit_ops, norm_words

GROUPS = ("men", "women", "children", "unspecified")


def score(items: list[dict], hyps: dict[int, str]) -> dict:
    """items: dataset entries with id, text, group. Returns
    {"groups": {group|all: {n, words, chars, wer, cer}}} in percent."""
    acc: dict[str, dict] = {}
    for item in items:
        if item["id"] not in hyps:
            continue
        ref = norm_words(item["text"])
        hyp = norm_words(hyps[item["id"]] or "")
        w = edit_ops(ref, hyp)[0]
        ref_c, hyp_c = list(" ".join(ref)), list(" ".join(hyp))
        c = edit_ops(ref_c, hyp_c)[0]
        for key in (item.get("group", "unspecified"), "all"):
            g = acc.setdefault(key, {"n": 0, "words": 0, "chars": 0, "w_err": 0, "c_err": 0})
            g["n"] += 1
            g["words"] += len(ref)
            g["chars"] += len(ref_c)
            g["w_err"] += w
            g["c_err"] += c
    out = {}
    for key, g in acc.items():
        out[key] = {
            "n": g["n"],
            "words": g["words"],
            "chars": g["chars"],
            "wer": round(100 * g["w_err"] / g["words"], 2) if g["words"] else None,
            "cer": round(100 * g["c_err"] / g["chars"], 2) if g["chars"] else None,
        }
    return {"groups": out}
