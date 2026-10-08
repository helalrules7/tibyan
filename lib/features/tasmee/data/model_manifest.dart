/// The recognition model the app uses: NVIDIA's Arabic FastConformer (CTC
/// branch, int8), CC-BY-4.0.
const recitationModelId = 'nvidia-ar-fastconformer-ctc';

/// Where the recognition model's manifest is published: Tibyan's mirror,
/// in its own folder (`mirror/recitation-models/<id>/`, files under `<version>/`).
const recitationModelManifestUrl =
    'https://tibyan.ahmedhelal.dev/mirror/recitation-models/'
    '$recitationModelId/manifest.json';

/// The first beta model (Whisper, Tarteel). It stays on the mirror only to
/// compare recognisers; the app no longer downloads it.
const whisperComparisonManifestUrl =
    'https://tibyan.ahmedhelal.dev/mirror/recitation-models/'
    'tarteel-whisper-base-ar-quran/manifest.json';

/// Models an earlier build may have installed and nothing uses now: removed
/// once the current model is installed, to give back the space.
const retiredRecitationModelIds = {'tarteel-whisper-base-ar-quran'};

/// How a model is run (the manifest's `engine`).
abstract final class ModelEngine {
  /// A NeMo CTC model in sherpa_onnx (`OfflineNemoEncDecCtcModelConfig`).
  static const sherpaNemoCtc = 'sherpa-onnx-nemo-ctc';

  /// Whisper in sherpa_onnx. A manifest without `engine` is one of these:
  /// it was the only engine before the field was read.
  static const sherpaWhisper = 'sherpa-onnx-whisper';
}

/// One file of a recognition model: where to fetch it, how big it is and
/// the SHA-256 it must have. The manager never trusts a file whose size or
/// checksum differs from this.
class ModelFileSpec {
  const ModelFileSpec({
    required this.name,
    required this.url,
    required this.sha256,
    required this.bytes,
  });

  /// A plain file name (no directories); it is stored under the model's
  /// own folder.
  final String name;
  final Uri url;

  /// Lower-case hex, 64 characters.
  final String sha256;
  final int bytes;

  static final _name = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$');
  static final _sha = RegExp(r'^[0-9a-f]{64}$');

  /// Names the store keeps for itself.
  static const reservedNames = {'installed.json', 'installed.json.tmp'};

  factory ModelFileSpec.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final url = json['url'];
    final sha = json['sha256'];
    final bytes = json['bytes'];
    if (name is! String ||
        !_name.hasMatch(name) ||
        name.endsWith('.part') ||
        reservedNames.contains(name)) {
      throw FormatException('Bad model file name: $name');
    }
    final uri = url is String ? Uri.tryParse(url) : null;
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw FormatException('Not an https URL: $url');
    }
    final lowerSha = sha is String ? sha.toLowerCase() : null;
    if (lowerSha == null || !_sha.hasMatch(lowerSha)) {
      throw FormatException('Bad sha256 for $name');
    }
    if (bytes is! int || bytes <= 0) {
      throw FormatException('Bad size for $name');
    }
    return ModelFileSpec(name: name, url: uri, sha256: lowerSha, bytes: bytes);
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'url': url.toString(),
    'sha256': sha256,
    'bytes': bytes,
  };
}

/// What to download for one version of a recognition model. The app ships
/// no model; this description (a small JSON file the app fetches or carries)
/// is all it needs, so a stronger model later is a new manifest, not a new
/// app build.
class ModelManifest {
  const ModelManifest({
    required this.id,
    required this.version,
    required this.license,
    required this.files,
    this.engine = ModelEngine.sherpaWhisper,
    this.attribution,
  });

  /// e.g. `whisper-base-ar-quran`.
  final String id;

  /// A new version of the same [id] replaces the old one once installed.
  final String version;

  /// SPDX id (or the licence's name) of the weights; required so no model
  /// is installed without its licence being written down.
  final String license;
  final List<ModelFileSpec> files;

  /// How the model is run: one of [ModelEngine].
  final String engine;

  /// The credit the licence asks for (CC-BY), as published with the model.
  final String? attribution;

  int get totalBytes => files.fold(0, (sum, f) => sum + f.bytes);

  static final _token = RegExp(r'^[a-z0-9][a-z0-9._-]{0,63}$');

  factory ModelManifest.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final version = json['version'];
    final license = json['license'];
    final files = json['files'];
    final engine = json['engine'] ?? ModelEngine.sherpaWhisper;
    final attribution = json['attribution'];
    if (id is! String || !_token.hasMatch(id)) {
      throw FormatException('Bad model id: $id');
    }
    if (version is! String || !_token.hasMatch(version)) {
      throw FormatException('Bad model version: $version');
    }
    if (license is! String || license.trim().isEmpty) {
      throw const FormatException('A model manifest needs its licence');
    }
    if (engine is! String || !_token.hasMatch(engine)) {
      throw FormatException('Bad model engine: $engine');
    }
    if (attribution != null && attribution is! String) {
      throw const FormatException('Bad attribution');
    }
    if (files is! List || files.isEmpty) {
      throw const FormatException('A model manifest needs files');
    }
    final specs = [
      for (final f in files)
        if (f is Map<String, dynamic>)
          ModelFileSpec.fromJson(f)
        else
          throw const FormatException('Bad file entry'),
    ];
    if (specs.map((f) => f.name).toSet().length != specs.length) {
      throw const FormatException('Duplicate file names');
    }
    return ModelManifest(
      id: id,
      version: version,
      license: license.trim(),
      files: List.unmodifiable(specs),
      engine: engine,
      attribution: (attribution as String?)?.trim(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'version': version,
    'license': license,
    'engine': engine,
    if (attribution != null) 'attribution': attribution,
    'files': [for (final f in files) f.toJson()],
  };
}
