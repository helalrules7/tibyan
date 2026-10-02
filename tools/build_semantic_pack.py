"""Build the optional «بحث بالمعنى» (search by meaning) pack.

The pack lets the app find verses by what they mean, offline. It holds:

* the multilingual-e5-small text encoder (intfloat, MIT), its weights
  quantised to int8 per output row, in a small binary format the app runs
  in pure Dart (`lib/features/search/semantic/e5_model.dart`): no native
  runtime, so it works the same on Android and iOS and adds nothing to the
  app bundle;
* its SentencePiece vocabulary (piece and score per line);
* one embedding per verse for every meaning text shipped in content.db
  (al-Tafsir al-Muyassar, Saheeh International, Pickthall), computed here
  with the original fp32 weights from the stored texts as they are. The
  texts themselves are not in the pack and never change: the app shows
  them from content.db.

Inputs (fetched and checked against the SHA-256 below on first run):
  tools/.cache/multilingual-e5-small/  model.safetensors, config.json,
                                        tokenizer.json (revision REVISION)
  assets/db/content.db                  commentary rows of the meaning texts
Output:
  tools/out/semantic-e5-small-v1.zip   (stored zip, manifest.json inside)
  test/fixtures/semantic/e5_reference.json  (expected ids and vectors,
                                        for the Dart port's tests)
Usage:
  python3 -m venv .venv && .venv/bin/pip install numpy scipy tokenizers onnxruntime
  .venv/bin/python tools/build_semantic_pack.py [--check-onnx]

`--check-onnx` also fetches the official int8 ONNX export and checks the
numpy forward pass against it (cosine > 0.97 on every test sentence).
"""
import argparse
import hashlib
import json
import sqlite3
import struct
import sys
import urllib.request
import zipfile
from pathlib import Path

import numpy as np
from scipy.special import erf
from tokenizers import Tokenizer

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parent
CACHE = ROOT / '.cache' / 'multilingual-e5-small'
OUT_DIR = ROOT / 'out'
DB = REPO / 'assets' / 'db' / 'content.db'
FIXTURE = REPO / 'test' / 'fixtures' / 'semantic' / 'e5_reference.json'
PACK_ID = 'semantic-e5-small-v1'

REVISION = '614241f622f53c4eeff9890bdc4f31cfecc418b3'
HF = f'https://huggingface.co/intfloat/multilingual-e5-small/resolve/{REVISION}/'
MIRROR = 'https://tibyan.ahmedhelal.dev/mirror/sources/multilingual-e5-small/'
FILES = {
    # name in the cache: (path in the HF repo, sha256)
    'model.safetensors': ('model.safetensors',
                          '1a55775f53449dac10a2bcbc312469fac40b96d53198c407081a831f81c98477'),
    'config.json': ('config.json',
                    '69137736cab8b8903a07fe8afaafdda25aac55415a12a55d1bffa9f581abf959'),
    'tokenizer.json': ('onnx/tokenizer.json',
                       '0b44a9d7b51c3c62626640cda0e2c2f70fdacdc25bbbd68038369d14ebdf4c39'),
}
ONNX = ('onnx/model_qint8_avx512_vnni.onnx',
        'dd476dd0c2514e9b9be83aeb3853fac0763e0bdf4a71645407587d77c48a2d88')

# content.db source ids of the meaning texts, in the pack's row order.
SOURCES = [7, 8, 9]
MAX_TOKENS = 512

# Sentences the Dart port is checked against (tokens and vectors).
REFERENCE = [
    'query: الصبر على البلاء',
    'query: patience in hardship',
    'query: رحمة الله بعباده',
    'query: who created the heavens and the earth',
    'query: بر الوالدين',
    'query: the day of judgement',
    'query: Zakat and charity',
    'query: قصة موسى مع فرعون',
]


def sha256(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(1 << 20), b''):
            h.update(chunk)
    return h.hexdigest()


def fetch(name, repo_path, digest):
    """The file from the cache, else from Tibyan's mirror, else from HF."""
    CACHE.mkdir(parents=True, exist_ok=True)
    path = CACHE / name
    if path.exists() and sha256(path) == digest:
        return path
    for url in (MIRROR + Path(repo_path).name, HF + repo_path):
        try:
            print(f'fetching {url}')
            urllib.request.urlretrieve(url, path)
        except Exception as e:  # noqa: BLE001 - try the next source
            print(f'  failed: {e}')
            continue
        if sha256(path) == digest:
            return path
        print('  wrong SHA-256')
    sys.exit(f'cannot fetch {name}')


def load_safetensors(path):
    data = path.read_bytes()
    n = struct.unpack('<Q', data[:8])[0]
    header = json.loads(data[8:8 + n])
    base = 8 + n
    out = {}
    for name, info in header.items():
        if name == '__metadata__' or name.endswith('position_ids'):
            continue
        assert info['dtype'] == 'F32', (name, info['dtype'])
        a, b = info['data_offsets']
        out[name] = np.frombuffer(data[base + a:base + b], dtype='<f4').reshape(info['shape'])
    return out


class Bert:
    """The encoder's forward pass in numpy. With `quantised`, the linear
    weights go through the same int8 rounding the app uses, to measure the
    difference the app sees."""

    def __init__(self, w, config, quantised=False):
        self.w = w
        self.c = config
        self.q = quantised

    def linear(self, x, name):
        weight = self.w[f'{name}.weight']
        if self.q:
            q, scale = quantise_rows(weight)
            weight = q.astype(np.float32) * scale[:, None]
        return x @ weight.T + self.w[f'{name}.bias']

    def norm(self, x, name):
        mean = x.mean(-1, keepdims=True)
        var = ((x - mean) ** 2).mean(-1, keepdims=True)
        eps = self.c['layer_norm_eps']
        return (x - mean) / np.sqrt(var + eps) * self.w[f'{name}.weight'] + self.w[f'{name}.bias']

    def embed_words(self, ids):
        table = self.w['embeddings.word_embeddings.weight']
        if self.q:
            rows = table[ids]
            q, scale = quantise_rows(rows)
            return q.astype(np.float32) * scale[..., None]
        return table[ids]

    def __call__(self, ids, mask):
        """ids, mask: [batch, length] int arrays. Returns normalised mean-pooled
        vectors [batch, 384]."""
        c = self.c
        b, n = ids.shape
        h = (self.embed_words(ids)
             + self.w['embeddings.position_embeddings.weight'][:n][None]
             + self.w['embeddings.token_type_embeddings.weight'][0])
        h = self.norm(h, 'embeddings.LayerNorm')
        heads = c['num_attention_heads']
        d = c['hidden_size'] // heads
        bias = (1.0 - mask[:, None, None, :].astype(np.float32)) * -1e9
        for i in range(c['num_hidden_layers']):
            p = f'encoder.layer.{i}'
            def split(x):
                return x.reshape(b, n, heads, d).transpose(0, 2, 1, 3)
            q = split(self.linear(h, f'{p}.attention.self.query'))
            k = split(self.linear(h, f'{p}.attention.self.key'))
            v = split(self.linear(h, f'{p}.attention.self.value'))
            s = q @ k.transpose(0, 1, 3, 2) / np.sqrt(d) + bias
            s = np.exp(s - s.max(-1, keepdims=True))
            s /= s.sum(-1, keepdims=True)
            a = (s @ v).transpose(0, 2, 1, 3).reshape(b, n, -1)
            h = self.norm(self.linear(a, f'{p}.attention.output.dense') + h,
                          f'{p}.attention.output.LayerNorm')
            f = self.linear(h, f'{p}.intermediate.dense')
            f = 0.5 * f * (1.0 + erf(f / np.sqrt(2.0)))
            h = self.norm(self.linear(f, f'{p}.output.dense') + h, f'{p}.output.LayerNorm')
        m = mask[..., None].astype(np.float32)
        pooled = (h * m).sum(1) / m.sum(1)
        return pooled / np.linalg.norm(pooled, axis=-1, keepdims=True)


def quantise_rows(m):
    """Symmetric int8 per row: m ≈ q * scale[:, None]."""
    m = np.asarray(m, dtype=np.float32)
    scale = np.abs(m).max(-1) / 127.0
    scale = np.where(scale == 0, 1.0, scale).astype(np.float32)
    q = np.clip(np.rint(m / scale[..., None]), -127, 127).astype(np.int8)
    return q, scale


class Blob:
    """Binary file: b'TBE5', u32 version, u32 header length, JSON header,
    then 16-byte aligned little-endian tensors at the header's offsets
    (counted from the start of the data section)."""

    def __init__(self):
        self.tensors = {}
        self.parts = []
        self.size = 0

    def add(self, name, array):
        array = np.ascontiguousarray(array)
        dtype = {np.dtype('int8'): 'i8', np.dtype('float32'): 'f32'}[array.dtype]
        raw = array.astype('<f4').tobytes() if dtype == 'f32' else array.tobytes()
        pad = (-self.size) % 16
        if pad:
            self.parts.append(b'\0' * pad)
            self.size += pad
        self.tensors[name] = {'dtype': dtype, 'shape': list(array.shape), 'offset': self.size}
        self.parts.append(raw)
        self.size += len(raw)

    def bytes(self, meta):
        header = json.dumps({**meta, 'tensors': self.tensors}, ensure_ascii=False).encode()
        head = b'TBE5' + struct.pack('<II', 1, len(header)) + header
        head += b'\0' * ((-len(head)) % 16)
        return head + b''.join(self.parts)


def model_blob(w, config):
    blob = Blob()
    q, scale = quantise_rows(w['embeddings.word_embeddings.weight'])
    blob.add('embeddings.word', q)
    blob.add('embeddings.word.scale', scale)
    blob.add('embeddings.position', w['embeddings.position_embeddings.weight'])
    blob.add('embeddings.type', w['embeddings.token_type_embeddings.weight'][0])
    blob.add('embeddings.norm.weight', w['embeddings.LayerNorm.weight'])
    blob.add('embeddings.norm.bias', w['embeddings.LayerNorm.bias'])
    names = {
        'attention.self.query': 'q', 'attention.self.key': 'k',
        'attention.self.value': 'v', 'attention.output.dense': 'o',
        'intermediate.dense': 'ffn_in', 'output.dense': 'ffn_out',
    }
    for i in range(config['num_hidden_layers']):
        p = f'encoder.layer.{i}'
        for src, dst in names.items():
            q, scale = quantise_rows(w[f'{p}.{src}.weight'])
            blob.add(f'layer.{i}.{dst}', q)
            blob.add(f'layer.{i}.{dst}.scale', scale)
            blob.add(f'layer.{i}.{dst}.bias', w[f'{p}.{src}.bias'])
        for src, dst in (('attention.output.LayerNorm', 'norm1'), ('output.LayerNorm', 'norm2')):
            blob.add(f'layer.{i}.{dst}.weight', w[f'{p}.{src}.weight'])
            blob.add(f'layer.{i}.{dst}.bias', w[f'{p}.{src}.bias'])
    meta = {
        'model': 'intfloat/multilingual-e5-small',
        'revision': REVISION,
        'hidden': config['hidden_size'],
        'layers': config['num_hidden_layers'],
        'heads': config['num_attention_heads'],
        'intermediate': config['intermediate_size'],
        'eps': config['layer_norm_eps'],
        'max_positions': config['max_position_embeddings'],
        'quantisation': 'int8 symmetric per output row (linear weights and word embeddings)',
    }
    return blob.bytes(meta)


def vocab_text(tok_json):
    model = tok_json['model']
    assert model['type'] == 'Unigram'
    lines = [f"{model['unk_id']}"]
    for piece, score in model['vocab']:
        assert '\t' not in piece and '\n' not in piece, piece
        lines.append(f'{score!r}\t{piece}')
    return ('\n'.join(lines) + '\n').encode()


def encode_batch(tokenizer, texts):
    enc = tokenizer.encode_batch(texts)
    n = max(len(e.ids) for e in enc)
    ids = np.zeros((len(enc), n), dtype=np.int64)
    mask = np.zeros((len(enc), n), dtype=np.int64)
    for i, e in enumerate(enc):
        ids[i, :len(e.ids)] = e.ids
        mask[i, :len(e.ids)] = 1
    ids[mask == 0] = 1  # <pad>
    return ids, mask


TINY_FIXTURE = REPO / 'test' / 'fixtures' / 'semantic' / 'tiny_model.json'


def tiny_fixture():
    """A tiny random encoder in the app's format, with the vector numpy
    computes for it (int8 path), so the Dart forward pass is tested without
    the 120 MB pack."""
    import base64
    rng = np.random.default_rng(7)
    config = {'hidden_size': 8, 'num_hidden_layers': 2, 'num_attention_heads': 2,
              'intermediate_size': 16, 'layer_norm_eps': 1e-12,
              'max_position_embeddings': 16}
    h, f = 8, 16
    w = {
        'embeddings.word_embeddings.weight': rng.normal(0, 1, (20, h)),
        'embeddings.position_embeddings.weight': rng.normal(0, 0.5, (16, h)),
        'embeddings.token_type_embeddings.weight': rng.normal(0, 0.5, (2, h)),
        'embeddings.LayerNorm.weight': rng.normal(1, 0.1, h),
        'embeddings.LayerNorm.bias': rng.normal(0, 0.1, h),
    }
    for i in range(2):
        p = f'encoder.layer.{i}'
        for name, shape in (('attention.self.query', (h, h)), ('attention.self.key', (h, h)),
                            ('attention.self.value', (h, h)), ('attention.output.dense', (h, h)),
                            ('intermediate.dense', (f, h)), ('output.dense', (h, f))):
            w[f'{p}.{name}.weight'] = rng.normal(0, 0.5, shape)
            w[f'{p}.{name}.bias'] = rng.normal(0, 0.1, shape[0])
        for name in ('attention.output.LayerNorm', 'output.LayerNorm'):
            w[f'{p}.{name}.weight'] = rng.normal(1, 0.1, h)
            w[f'{p}.{name}.bias'] = rng.normal(0, 0.1, h)
    w = {k: v.astype(np.float32) for k, v in w.items()}
    ids = np.array([[0, 5, 17, 3, 9, 2]])
    vec = Bert(w, config, quantised=True)(ids, np.ones_like(ids))[0]
    TINY_FIXTURE.parent.mkdir(parents=True, exist_ok=True)
    TINY_FIXTURE.write_text(json.dumps({
        'model': base64.b64encode(model_blob(w, config)).decode(),
        'ids': ids[0].tolist(),
        'vector': [float(x) for x in vec],
    }) + '\n')
    print(f'{TINY_FIXTURE.relative_to(REPO)} written')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check-onnx', action='store_true')
    ap.add_argument('--limit', type=int, default=0, help='verses per source (testing)')
    ap.add_argument('--fixture-only', action='store_true',
                    help='only write the tiny model fixture for the Dart tests')
    args = ap.parse_args()
    tiny_fixture()
    if args.fixture_only:
        return 0

    paths = {name: fetch(name, *spec) for name, spec in FILES.items()}
    config = json.loads(paths['config.json'].read_text())
    tok_json = json.loads(paths['tokenizer.json'].read_text())
    tokenizer = Tokenizer.from_file(str(paths['tokenizer.json']))
    tokenizer.enable_truncation(MAX_TOKENS)
    w = load_safetensors(paths['model.safetensors'])
    bert = Bert(w, config)
    bert_q = Bert(w, config, quantised=True)

    # Reference vectors, and the int8 model's distance from them.
    reference = []
    for s in REFERENCE:
        ids, mask = encode_batch(tokenizer, [s])
        full = bert(ids, mask)[0]
        quant = bert_q(ids, mask)[0]
        cos = float(full @ quant)
        assert cos > 0.99, (s, cos)
        reference.append({'text': s, 'ids': ids[0].tolist(),
                          'vector': [round(float(x), 6) for x in full],
                          'int8_cosine': round(cos, 5)})
        print(f'{s}: {len(ids[0])} tokens, int8 cosine {cos:.4f}')

    if args.check_onnx:
        import onnxruntime as ort
        onnx = fetch(Path(ONNX[0]).name, *ONNX)
        sess = ort.InferenceSession(str(onnx))
        for r in reference:
            ids = np.array([r['ids']])
            mask = np.ones_like(ids)
            h = sess.run(None, {'input_ids': ids, 'attention_mask': mask,
                                'token_type_ids': np.zeros_like(ids)})[0][0]
            v = h.mean(0)
            v /= np.linalg.norm(v)
            cos = float(v @ np.array(r['vector']))
            print(f"onnx vs numpy {r['text']}: {cos:.4f}")
            assert cos > 0.97, cos

    # Passage vectors of every meaning text, in (source, surah, ayah) order.
    db = sqlite3.connect(DB)
    sources = []
    vectors = []
    for sid in SOURCES:
        meta = db.execute(
            'SELECT s.key, s.version, s.sha256, e.name_en, e.language FROM source s '
            'JOIN commentary_edition e ON e.source_id = s.id WHERE s.id = ?', (sid,)).fetchone()
        rows = db.execute('SELECT c.surah, c.ayah, c.text FROM commentary c '
                          'JOIN ayah a ON a.surah = c.surah AND a.number = c.ayah '
                          'WHERE c.source_id = ? ORDER BY a.id', (sid,)).fetchall()
        assert len(rows) == 6236, (sid, len(rows))
        if args.limit:
            rows = rows[:args.limit]
        texts = [r[2] for r in rows]
        digest = hashlib.sha256('\n'.join(texts).encode()).hexdigest()
        order = sorted(range(len(texts)), key=lambda i: len(texts[i]))
        out = np.zeros((len(texts), config['hidden_size']), dtype=np.float32)
        batch = 32
        for start in range(0, len(order), batch):
            idx = order[start:start + batch]
            ids, mask = encode_batch(tokenizer, ['passage: ' + texts[i] for i in idx])
            out[idx] = bert(ids, mask)
            if start % (batch * 20) == 0:
                print(f'source {sid}: {start}/{len(texts)}', flush=True)
        vectors.append(out)
        sources.append({'source_id': sid, 'key': meta[0], 'version': meta[1],
                        'name': meta[3], 'language': meta[4], 'rows': len(texts),
                        'texts_sha256': digest, 'source_sha256': meta[2]})
    all_vectors = np.concatenate(vectors)
    q, scale = quantise_rows(all_vectors)
    emb = Blob()
    emb.add('passages', q)
    emb.add('passages.scale', scale)
    emb_bytes = emb.bytes({'rows': int(all_vectors.shape[0]), 'dim': config['hidden_size'],
                           'prefix': 'passage: ', 'max_tokens': MAX_TOKENS})

    # Retrieval sanity: the int8 passages rank like the fp32 ones.
    for r in reference:
        v = np.array(r['vector'], dtype=np.float32)
        exact = np.argsort(-(all_vectors @ v))[:10]
        approx = np.argsort(-((q.astype(np.float32) * scale[:, None]) @ v))[:10]
        r['top'] = [int(i) for i in exact[:5]]
        print(f"{r['text']}: top-10 overlap {len(set(exact) & set(approx))}/10")

    model_bytes = model_blob(w, config)
    vocab_bytes = vocab_text(tok_json)
    files = {'model.bin': model_bytes, 'vocab.tsv': vocab_bytes, 'embeddings.bin': emb_bytes}
    manifest = {
        'id': PACK_ID,
        'model': {
            'name': 'intfloat/multilingual-e5-small', 'revision': REVISION, 'license': 'MIT',
            'source_sha256': {n: d for n, (_, d) in FILES.items()},
            'query_prefix': 'query: ', 'passage_prefix': 'passage: ', 'pooling': 'mean',
        },
        'texts': 'Embeddings of the stored meaning texts in content.db; the texts '
                 'themselves are not in this pack and are shown from content.db verbatim.',
        'sources': sources,
        'files': [{'file': n, 'sha256': hashlib.sha256(b).hexdigest(), 'bytes': len(b)}
                  for n, b in files.items()],
    }
    OUT_DIR.mkdir(exist_ok=True)
    out = OUT_DIR / f'{PACK_ID}.zip'
    with zipfile.ZipFile(out, 'w', zipfile.ZIP_STORED) as z:
        for name, data in [*files.items(),
                           ('manifest.json', json.dumps(manifest, ensure_ascii=False, indent=1).encode())]:
            info = zipfile.ZipInfo(name, date_time=(2026, 10, 2, 0, 0, 0))
            info.external_attr = 0o644 << 16
            z.writestr(info, data)
    FIXTURE.parent.mkdir(parents=True, exist_ok=True)
    FIXTURE.write_text(json.dumps({'pack': PACK_ID, 'sentences': reference}, ensure_ascii=False) + '\n')
    print(f'{out.relative_to(REPO)}: {out.stat().st_size} bytes, sha256 {sha256(out)}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
