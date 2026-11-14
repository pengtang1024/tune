import 'package:tune/data/services/components/local_component.dart';

/// The single list of local components (docs/local-components.md §1).
///
/// Sizes and digests are the ones the publishers print; a release that moves
/// an asset updates them here, not in a feature. Runtime and model are
/// separate downloads so either can be replaced without the other.
class LocalComponentRegistry {
  const LocalComponentRegistry._();

  /// The default offline model (docs/local-ai-evaluation.md §4.2).
  static const String translationModelFileName = 'Qwen3-0.6B-Q8_0.gguf';

  static const LocalComponentSpec translationRuntime = LocalComponentSpec(
    id: 'translation-runtime',
    kind: LocalComponentKind.runtime,
    label: LocalComponentLabel.translationRuntime,
    archive: LocalComponentArchive.tarGz,
    executable: 'llama-cli',
    files: [
      LocalComponentFile(
        fileName: 'llama-b12274-bin-ubuntu-x64.tar.gz',
        url:
            'https://github.com/ggml-org/llama.cpp/releases/download/b12274/'
            'llama-b12274-bin-ubuntu-x64.tar.gz',
        bytes: 23287295,
        sha256: '5f9de4d104502b38fdb1081d00087683ca224ca5c450eaba4eeb436b9a1bcd94',
      ),
    ],
    systemNames: ['llama-cli'],
    legacyDirectories: ['translation/bin'],
  );

  /// Qwen3-0.6B is the default: newer than 2.5-0.5B, still Apache-2.0.
  static const LocalComponentSpec translationModel = LocalComponentSpec(
    id: 'translation-model',
    kind: LocalComponentKind.model,
    label: LocalComponentLabel.translationModel,
    files: [
      LocalComponentFile(
        fileName: translationModelFileName,
        url:
            'https://huggingface.co/Qwen/Qwen3-0.6B-GGUF/resolve/main/'
            'Qwen3-0.6B-Q8_0.gguf',
        bytes: 639446688,
        sha256: '9465e63a22add5354d9bb4b99e90117043c7124007664907259bd16d043bb031',
      ),
    ],
    requiredFiles: [translationModelFileName],
  );

  /// The low-memory tier; also the model the previous release downloaded.
  static const LocalComponentSpec translationModelLow = LocalComponentSpec(
    id: 'translation-model-low',
    kind: LocalComponentKind.model,
    label: LocalComponentLabel.translationModelLow,
    files: [
      LocalComponentFile(
        fileName: 'qwen2.5-0.5b-instruct-q4_k_m.gguf',
        url:
            'https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/'
            'main/qwen2.5-0.5b-instruct-q4_k_m.gguf',
        bytes: 491400032,
        sha256: '74a4da8c9fdbcd15bd1f6d01d621410d31c6fc00986f5eb687824e7b93d7a9db',
      ),
    ],
    requiredFiles: ['qwen2.5-0.5b-instruct-q4_k_m.gguf'],
    legacyFiles: ['translation/models/qwen2.5-0.5b-instruct-q4_k_m.gguf'],
  );

  /// The optional quality tier, much slower on a small CPU.
  static const LocalComponentSpec translationModelQuality = LocalComponentSpec(
    id: 'translation-model-quality',
    kind: LocalComponentKind.model,
    label: LocalComponentLabel.translationModelQuality,
    files: [
      LocalComponentFile(
        fileName: 'qwen2.5-1.5b-instruct-q4_k_m.gguf',
        url:
            'https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/'
            'main/qwen2.5-1.5b-instruct-q4_k_m.gguf',
        bytes: 1117320736,
        sha256: '6a1a2eb6d15622bf3c96857206351ba97e1af16c30d7a74ee38970e434e9407e',
      ),
    ],
    requiredFiles: ['qwen2.5-1.5b-instruct-q4_k_m.gguf'],
  );

  /// Default first, then the two alternatives the reader may download.
  static const List<LocalComponentSpec> translationModels = [
    translationModel,
    translationModelLow,
    translationModelQuality,
  ];

  static const LocalComponentSpec whisperRuntime = LocalComponentSpec(
    id: 'lyrics-whisper-runtime',
    kind: LocalComponentKind.runtime,
    label: LocalComponentLabel.whisperRuntime,
    archive: LocalComponentArchive.tarGz,
    executable: 'whisper-cli',
    files: [
      LocalComponentFile(
        fileName: 'whisper-bin-ubuntu-x64.tar.gz',
        url:
            'https://github.com/ggml-org/whisper.cpp/releases/download/b5454/'
            'whisper-bin-ubuntu-x64.tar.gz',
        bytes: 10364195,
        sha256: 'a72becf15d7917f990f6313867a52638b82b7f9ef237fb0c980dac56a135781c',
      ),
    ],
    systemNames: ['whisper-cli', 'whisper-cpp', 'whisper'],
    legacyDirectories: ['whisper/bin'],
  );

  static const List<LocalComponentSpec> whisperModels = [
    LocalComponentSpec(
      id: 'lyrics-whisper-model-tiny',
      kind: LocalComponentKind.model,
      label: LocalComponentLabel.whisperModelTiny,
      files: [
        LocalComponentFile(
          fileName: 'ggml-tiny.bin',
          url:
              'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/'
              'ggml-tiny.bin',
          bytes: 77691713,
          sha256:
              'be07e048e1e599ad46341c8d2a135645097a538221678b7acdd1b1919c6e1b21',
        ),
      ],
      requiredFiles: ['ggml-tiny.bin'],
      legacyFiles: ['whisper/models/ggml-tiny.bin'],
    ),
    LocalComponentSpec(
      id: 'lyrics-whisper-model-base',
      kind: LocalComponentKind.model,
      label: LocalComponentLabel.whisperModelBase,
      files: [
        LocalComponentFile(
          fileName: 'ggml-base.bin',
          url:
              'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/'
              'ggml-base.bin',
          bytes: 147951465,
          sha256:
              '60ed5bc3dd14eea856493d334349b405782ddcaf0028d4b5df4088345fba2efe',
        ),
      ],
      requiredFiles: ['ggml-base.bin'],
      legacyFiles: ['whisper/models/ggml-base.bin'],
    ),
    LocalComponentSpec(
      id: 'lyrics-whisper-model-small',
      kind: LocalComponentKind.model,
      label: LocalComponentLabel.whisperModelSmall,
      files: [
        LocalComponentFile(
          fileName: 'ggml-small.bin',
          url:
              'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/'
              'ggml-small.bin',
          bytes: 487601967,
          sha256:
              '1be3a9b2063867b937e64e2ec7483364a79917e157fa98c5d94b5c1fffea987b',
        ),
      ],
      requiredFiles: ['ggml-small.bin'],
      legacyFiles: ['whisper/models/ggml-small.bin'],
    ),
    LocalComponentSpec(
      id: 'lyrics-whisper-model-large-v3-turbo',
      kind: LocalComponentKind.model,
      label: LocalComponentLabel.whisperModelLargeTurbo,
      files: [
        LocalComponentFile(
          fileName: 'ggml-large-v3-turbo.bin',
          url:
              'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/'
              'ggml-large-v3-turbo.bin',
          bytes: 1624555275,
          sha256:
              '1fc70f774d38eb169993ac391eea357ef47c88757ef72ee5943879b7e8e2bc69',
        ),
      ],
      requiredFiles: ['ggml-large-v3-turbo.bin'],
      legacyFiles: ['whisper/models/ggml-large-v3-turbo.bin'],
    ),
  ];

  static const LocalComponentSpec sherpaRuntime = LocalComponentSpec(
    id: 'lyrics-sherpa-runtime',
    kind: LocalComponentKind.runtime,
    label: LocalComponentLabel.sherpaRuntime,
    archive: LocalComponentArchive.tarBz2,
    executable: 'sherpa-onnx-offline',
    files: [
      LocalComponentFile(
        fileName: 'sherpa-onnx-v2.0.1-linux-x64-static-no-tts.tar.bz2',
        url:
            'https://github.com/k2-fsa/sherpa-onnx/releases/download/v2.0.1/'
            'sherpa-onnx-v2.0.1-linux-x64-static-no-tts.tar.bz2',
        bytes: 373735272,
        sha256: 'ea25c18660047a8ec8aa0cda291ccf806ae9c18a9b3b76372399cc4a7f4d7663',
      ),
    ],
    systemNames: ['sherpa-onnx-offline'],
    systemPaths: ['~/.local/opt/sherpa-onnx/bin/sherpa-onnx-offline'],
  );

  static const LocalComponentSpec sensevoiceModel = LocalComponentSpec(
    id: 'lyrics-sensevoice-model',
    kind: LocalComponentKind.model,
    label: LocalComponentLabel.sensevoiceModel,
    files: [
      LocalComponentFile(
        fileName: 'model.int8.onnx',
        url:
            'https://huggingface.co/csukuangfj/'
            'sherpa-onnx-sense-voice-zh-en-ja-ko-yue-2024-07-17/resolve/main/'
            'model.int8.onnx',
        bytes: 239233841,
        sha256:
            'c71f0ce00bec95b07744e116345e33d8cbbe08cef896382cf907bf4b51a2cd51',
      ),
      LocalComponentFile(
        fileName: 'tokens.txt',
        url:
            'https://huggingface.co/csukuangfj/'
            'sherpa-onnx-sense-voice-zh-en-ja-ko-yue-2024-07-17/resolve/main/'
            'tokens.txt',
        bytes: 315894,
        sha256:
            'f449eb28dc567533d7fa59be34e2abca8784f771850c78a47fb731a31429a1dc',
      ),
    ],
    requiredFiles: ['model.int8.onnx', 'tokens.txt'],
    systemPaths: ['~/.local/opt/sherpa-onnx/models/sense-voice'],
  );

  /// The optional third ASR family (docs/local-ai-evaluation.md D12): it runs
  /// on the sherpa-onnx runtime above, so no runtime component of its own.
  ///
  /// The six files stay flat because the installer copies each by name; the
  /// component folder is also the tokenizer directory `--funasr-nano-tokenizer`
  /// asks for, which only reads `vocab.json`, `merges.txt` and
  /// `tokenizer.json` out of it.
  ///
  /// The canonical repo, tried first.
  static const String _funasrNanoUrl =
      'https://huggingface.co/csukuangfj/'
      'sherpa-onnx-funasr-nano-int8-2025-12-30/resolve/main';

  /// Mainland networks often cannot reach huggingface.co. The mirror serves
  /// the same bytes and must pass the same pinned length and sha256 — a
  /// mirror can save the download, never weaken the check.
  static const String _funasrNanoMirror =
      'https://hf-mirror.com/csukuangfj/'
      'sherpa-onnx-funasr-nano-int8-2025-12-30/resolve/main';

  static const LocalComponentSpec funasrNanoModel = LocalComponentSpec(
    id: 'lyrics-funasr-nano-model',
    kind: LocalComponentKind.model,
    label: LocalComponentLabel.funasrNanoModel,
    files: [
      LocalComponentFile(
        fileName: 'encoder_adaptor.int8.onnx',
        url: '$_funasrNanoUrl/encoder_adaptor.int8.onnx',
        mirrors: ['$_funasrNanoMirror/encoder_adaptor.int8.onnx'],
        bytes: 237792748,
        sha256:
            'f36dea2e30fbc33b5db1d7a7265cc976c5e5586c77b042d5adb1ad27c72db422',
      ),
      LocalComponentFile(
        fileName: 'llm.int8.onnx',
        url: '$_funasrNanoUrl/llm.int8.onnx',
        mirrors: ['$_funasrNanoMirror/llm.int8.onnx'],
        bytes: 600356593,
        sha256:
            'dfbf9aa3be41bccc257587f151e15c63fbe1b549f2b517f5ccd5bdce3bf4322a',
      ),
      LocalComponentFile(
        fileName: 'embedding.int8.onnx',
        url: '$_funasrNanoUrl/embedding.int8.onnx',
        mirrors: ['$_funasrNanoMirror/embedding.int8.onnx'],
        bytes: 155584380,
        sha256:
            '95e61cd0c9c3b9543339a4cf973c95c116815e745ccc1e0285cbd81f76d18644',
      ),
      LocalComponentFile(
        fileName: 'vocab.json',
        url: '$_funasrNanoUrl/Qwen3-0.6B/vocab.json',
        mirrors: ['$_funasrNanoMirror/Qwen3-0.6B/vocab.json'],
        bytes: 2776833,
        sha256:
            'ca10d7e9fb3ed18575dd1e277a2579c16d108e32f27439684afa0e10b1440910',
      ),
      LocalComponentFile(
        fileName: 'merges.txt',
        url: '$_funasrNanoUrl/Qwen3-0.6B/merges.txt',
        mirrors: ['$_funasrNanoMirror/Qwen3-0.6B/merges.txt'],
        bytes: 1671853,
        sha256:
            '8831e4f1a044471340f7c0a83d7bd71306a5b867e95fd870f74d0c5308a904d5',
      ),
      LocalComponentFile(
        fileName: 'tokenizer.json',
        url: '$_funasrNanoUrl/Qwen3-0.6B/tokenizer.json',
        mirrors: ['$_funasrNanoMirror/Qwen3-0.6B/tokenizer.json'],
        bytes: 11422654,
        sha256:
            'aeb13307a71acd8fe81861d94ad54ab689df773318809eed3cbe794b4492dae4',
      ),
    ],
    requiredFiles: [
      'encoder_adaptor.int8.onnx',
      'llm.int8.onnx',
      'embedding.int8.onnx',
      'vocab.json',
      'merges.txt',
      'tokenizer.json',
    ],
    systemPaths: ['~/.local/opt/sherpa-onnx/models/funasr-nano'],
  );

  /// GPL-2.0-or-later build, hosted in our own GitHub release so the
  /// corresponding source and license travel with it (docs/licensing.md §3).
  /// `tool/build_ffmpeg.sh` produces this exact archive.
  static const LocalComponentSpec ffmpeg = LocalComponentSpec(
    id: 'ffmpeg',
    kind: LocalComponentKind.runtime,
    label: LocalComponentLabel.ffmpeg,
    archive: LocalComponentArchive.tarXz,
    executable: 'ffmpeg',
    files: [
      LocalComponentFile(
        fileName: 'ffmpeg-8.0.1-linux-x64-gpl.tar.xz',
        url:
            'https://github.com/pengtang1024/tune/releases/download/'
            'components-ffmpeg-8.0.1/ffmpeg-8.0.1-linux-x64-gpl.tar.xz',
        bytes: 6100948,
        sha256: 'd3358b749aaf4e4e40abda891e9a4628ff4cadfb02ed1352898fa322c6dd38b3',
      ),
    ],
    systemNames: ['ffmpeg'],
    systemPaths: ['/usr/bin/ffmpeg', '/usr/local/bin/ffmpeg'],
  );

  /// Everything the settings page lists, in display order.
  static const List<LocalComponentSpec> all = [
    translationRuntime,
    ...translationModels,
    whisperRuntime,
    ...whisperModels,
    sherpaRuntime,
    sensevoiceModel,
    funasrNanoModel,
    ffmpeg,
  ];

  /// The whisper model component for a model name the settings page uses.
  static LocalComponentSpec whisperModel(String name) {
    for (final spec in whisperModels) {
      if (spec.id == 'lyrics-whisper-model-$name') return spec;
    }
    throw ArgumentError.value(name, 'name', 'no such whisper model');
  }

  /// The model file name inside a whisper model component.
  static String whisperModelFile(String name) => 'ggml-$name.bin';

  static LocalComponentSpec byId(String id) =>
      all.firstWhere((spec) => spec.id == id);
}
