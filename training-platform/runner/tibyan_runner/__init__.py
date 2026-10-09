"""Tibyan training runner: claims fine-tune jobs from train.altibyan.app,
trains NVIDIA's Arabic FastConformer (CTC branch) with NeMo on Apple
Silicon (MPS, CPU fallback), evaluates, exports a sherpa-onnx int8 model
and uploads the results for admin approval."""

__version__ = "0.1.0"
