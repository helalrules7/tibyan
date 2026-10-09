"""Fine-tune the CTC branch of NVIDIA's Arabic FastConformer hybrid model
with a plain PyTorch loop (MPS when available, else CPU).

Only the encoder and the CTC decoder train; the transducer branch is left
as it is (Tibyan exports and ships only the CTC branch). The loop
checkpoints every `ckpt_every` steps and on interruption, and resumes
from the last checkpoint, so stopping the runner never loses more than a
few minutes of work.
"""
from __future__ import annotations

import math
import os
import random
import time
from pathlib import Path

os.environ.setdefault("PYTORCH_ENABLE_MPS_FALLBACK", "1")

from .audio import read_wav  # noqa: E402
from .textnorm import norm_text  # noqa: E402


class Stopped(Exception):
    """Raised when the runner was asked to stop; a checkpoint was saved."""


def pick_device(pref: str = "auto"):
    import torch

    if pref == "cpu":
        return torch.device("cpu")
    if pref in ("auto", "mps") and torch.backends.mps.is_available():
        return torch.device("mps")
    return torch.device("cpu")


def load_model(path: Path):
    import nemo.collections.asr as nemo_asr

    return nemo_asr.models.ASRModel.restore_from(str(path), map_location="cpu")


def _batches(items: list[dict], batch_size: int, seed: int) -> list[list[dict]]:
    """Shuffle, then sort within pools of 50 batches by duration (less
    padding), then shuffle the batches. Deterministic per seed."""
    rng = random.Random(seed)
    items = items[:]
    rng.shuffle(items)
    pool = batch_size * 50
    batches = []
    for i in range(0, len(items), pool):
        chunk = sorted(items[i:i + pool], key=lambda e: e["duration"])
        batches += [chunk[j:j + batch_size] for j in range(0, len(chunk), batch_size)]
    rng.shuffle(batches)
    return batches


def train(job_dir: Path, job: dict, dataset: dict, base_path: Path, report, stop,
          device_pref: str = "auto", threads: int = 4, ckpt_every: int = 25,
          max_steps: int | None = None) -> Path:
    """Fine-tune and save job_dir/model.nemo. Returns its path."""
    import torch

    torch.set_num_threads(max(1, threads))
    params = job["params"]
    seed = int(params.get("seed", 42))
    torch.manual_seed(seed)
    device = pick_device(device_pref)

    audio_dir = job_dir / "audio"
    max_s = float(params.get("max_duration_s", 30))
    items = []
    skipped = 0
    for e in dataset["train"]:
        if e["duration"] > max_s or e["duration"] < 0.3:
            skipped += 1
            continue
        items.append(e)
    if not items:
        raise RuntimeError("no training clips within the duration limit")

    report(None, "loading base model", [f"device {device}, threads {threads}; "
                                        f"{len(items)} clips, {skipped} skipped (> {max_s}s)"])
    model = load_model(base_path)
    model.train()
    tokenizer = model.tokenizer
    blank = model.ctc_decoder.num_classes_with_blank - 1
    unk = getattr(tokenizer, "unk_id", None)

    targets = {}
    unk_count = 0
    for e in items:
        text = norm_text(e["text"]) if params.get("text_norm", "plain") == "plain" else e["text"]
        ids = tokenizer.text_to_ids(text)
        unk_count += sum(1 for i in ids if i == unk)
        targets[e["id"]] = ids
    if unk_count:
        report(None, None, [f"note: {unk_count} unknown tokens in the training targets"])

    freeze = bool(params.get("freeze_encoder"))
    for p in model.parameters():
        p.requires_grad = False
    trainable = list(model.ctc_decoder.parameters())
    if not freeze:
        trainable += list(model.encoder.parameters())
    for p in trainable:
        p.requires_grad = True
    model.to(device)

    epochs = int(params.get("epochs", 5))
    bs = int(params.get("batch_size", 4))
    steps_per_epoch = math.ceil(len(items) / bs)
    total = epochs * steps_per_epoch
    if max_steps:
        total = min(total, max_steps)
    warmup = max(1, min(100, total // 10))
    lr = float(params.get("learning_rate", 3e-5))
    opt = torch.optim.AdamW(trainable, lr=lr, weight_decay=1e-3)
    sched = torch.optim.lr_scheduler.LambdaLR(
        opt,
        lambda s: min(1.0, (s + 1) / warmup) * (0.1 + 0.9 * 0.5 * (1 + math.cos(math.pi * min(1.0, s / total)))),
    )
    ctc = torch.nn.CTCLoss(blank=blank, zero_infinity=True, reduction="mean")

    ckpt = job_dir / "ckpt.pt"
    epoch0, step_in_epoch0, global_step = 0, 0, 0
    if ckpt.is_file():
        state = torch.load(ckpt, map_location="cpu", weights_only=False)
        model.encoder.load_state_dict(state["encoder"])
        model.ctc_decoder.load_state_dict(state["ctc_decoder"])
        opt.load_state_dict(state["opt"])
        sched.load_state_dict(state["sched"])
        epoch0, step_in_epoch0, global_step = state["epoch"], state["step_in_epoch"], state["global_step"]
        report(None, None, [f"resumed from checkpoint: epoch {epoch0 + 1}, step {global_step}"])

    def save_ckpt(epoch: int, step_in_epoch: int) -> None:
        tmp = ckpt.with_suffix(".tmp")
        torch.save({
            "encoder": model.encoder.state_dict(),
            "ctc_decoder": model.ctc_decoder.state_dict(),
            "opt": opt.state_dict(),
            "sched": sched.state_dict(),
            "epoch": epoch,
            "step_in_epoch": step_in_epoch,
            "global_step": global_step,
        }, tmp)
        tmp.replace(ckpt)

    audio_cache: dict[int, object] = {}

    def wav(e):
        if e["id"] not in audio_cache:
            audio_cache[e["id"]] = torch.from_numpy(read_wav(audio_dir / f"{e['id']}.wav"))
        return audio_cache[e["id"]]

    t0 = time.time()
    done = False
    for epoch in range(epoch0, epochs):
        batches = _batches(items, bs, seed + epoch)
        start = step_in_epoch0 if epoch == epoch0 else 0
        running = 0.0
        for i in range(start, len(batches)):
            if stop.is_set():
                save_ckpt(epoch, i)
                raise Stopped()
            batch = batches[i]
            sig = [wav(e) for e in batch]
            lens = torch.tensor([len(s) for s in sig], dtype=torch.long)
            x = torch.zeros(len(sig), int(lens.max()))
            for j, s in enumerate(sig):
                x[j, : len(s)] = s
            tgt = [torch.tensor(targets[e["id"]], dtype=torch.long) for e in batch]
            tlen = torch.tensor([len(t) for t in tgt], dtype=torch.long)
            flat = torch.cat(tgt) if tgt else torch.zeros(0, dtype=torch.long)

            x, lens_d = x.to(device), lens.to(device)
            processed, plen = model.preprocessor(input_signal=x, length=lens_d)
            if model.spec_augmentation is not None:
                processed = model.spec_augmentation(input_spec=processed, length=plen)
            enc, elen = model.encoder(audio_signal=processed, length=plen)
            log_probs = model.ctc_decoder(encoder_output=enc)  # B, T, V+1
            # CTC loss on CPU (not implemented on MPS); gradients flow back.
            loss = ctc(log_probs.transpose(0, 1).float().cpu(), flat, elen.cpu(), tlen)
            opt.zero_grad(set_to_none=True)
            loss.backward()
            torch.nn.utils.clip_grad_norm_(trainable, 1.0)
            opt.step()
            sched.step()
            global_step += 1
            running += float(loss.detach())

            if global_step % 5 == 0 or global_step == total:
                rate = (time.time() - t0) / max(1, global_step - (epoch0 * steps_per_epoch + step_in_epoch0))
                report(0.15 + 0.55 * global_step / total, f"training epoch {epoch + 1}/{epochs}",
                       [f"step {global_step}/{total} loss {float(loss.detach()):.4f} "
                        f"lr {sched.get_last_lr()[0]:.2e} ({rate:.1f}s/step)"])
            if global_step % ckpt_every == 0:
                save_ckpt(epoch, i + 1)
            if global_step >= total:
                done = True
                break
        report(None, None, [f"epoch {epoch + 1} mean loss {running / max(1, len(batches) - start):.4f}"])
        save_ckpt(epoch + 1, 0)
        if done:
            break

    model.eval()
    model.to("cpu")
    out = job_dir / "model.nemo"
    tmp = job_dir / "model.nemo.tmp"
    model.save_to(str(tmp))
    tmp.replace(out)
    report(0.72, "trained", [f"saved {out.name} after {global_step} steps"])
    return out


def export_ctc_int8(nemo_path: Path, out_dir: Path, source: str) -> None:
    """Export the CTC branch to ONNX with sherpa-onnx metadata and quantise
    to int8 — the same steps as the mirror's convert/export_nemo_ctc.py
    (based on k2-fsa/sherpa-onnx scripts/nemo, Apache-2.0)."""
    import onnx
    from onnxruntime.quantization import QuantType, quantize_dynamic

    out_dir.mkdir(parents=True, exist_ok=True)
    m = load_model(nemo_path)
    m.eval()
    m.preprocessor.featurizer.dither = 0.0
    m.preprocessor.featurizer.pad_to = 0
    vocab = m.ctc_decoder.vocabulary if hasattr(m, "ctc_decoder") else m.decoder.vocabulary
    with open(out_dir / "tokens.txt", "w", encoding="utf-8") as f:
        for i, s in enumerate(vocab):
            f.write(f"{s} {i}\n")
        f.write(f"<blk> {i + 1}\n")
    m.set_export_config({"decoder_type": "ctc"})
    fp32 = out_dir / "model.onnx"
    m.export(str(fp32))
    cfg = m.cfg.preprocessor
    meta = {
        "vocab_size": len(vocab) + 1,
        "normalize_type": cfg.get("normalize", "per_feature"),
        "subsampling_factor": 8, "model_type": "EncDecCTCModelBPE", "version": "1",
        "model_author": "NeMo", "url": source,
        "comment": "Only the CTC branch is exported", "feat_dim": cfg.get("features", 80),
    }
    mo = onnx.load(str(fp32))
    while len(mo.metadata_props):
        mo.metadata_props.pop()
    for k, v in meta.items():
        p = mo.metadata_props.add()
        p.key, p.value = k, str(v)
    onnx.save(mo, str(fp32))
    quantize_dynamic(model_input=str(fp32), model_output=str(out_dir / "model.int8.onnx"),
                     weight_type=QuantType.QUInt8)
    fp32.unlink(missing_ok=True)


def transcribe_sherpa(model_path: Path, tokens: Path, items: list[dict], audio_dir: Path,
                      threads: int, stop) -> dict[int, str]:
    """Transcribe each eval clip with sherpa-onnx (as the app does), cutting
    long clips into app-like segments and joining the text."""
    import sherpa_onnx

    from .audio import SR, segments

    rec = sherpa_onnx.OfflineRecognizer.from_nemo_ctc(
        model=str(model_path), tokens=str(tokens), num_threads=max(1, threads),
        decoding_method="greedy_search", provider="cpu",
    )
    hyps = {}
    for e in items:
        if stop.is_set():
            raise Stopped()
        texts = []
        for seg in segments(read_wav(audio_dir / f"{e['id']}.wav")):
            s = rec.create_stream()
            s.accept_waveform(SR, seg)
            rec.decode_stream(s)
            texts.append(s.result.text)
        hyps[e["id"]] = " ".join(texts)
    return hyps
