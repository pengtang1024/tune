import 'package:tune/data/services/components/local_component.dart';

/// The single list of local components (docs/local-components.md §1).
///
/// Sizes and digests are the ones the publishers print; a release that moves
/// an asset updates them here, not in a feature. Runtime and model are
/// separate downloads so either can be replaced without the other.
class LocalComponentRegistry {
  const LocalComponentRegistry._();

  static const String translationModelFileName =
      'qwen2.5-0.5b-instruct-q4_k_m.gguf';

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

  static const LocalComponentSpec translationModel = LocalComponentSpec(
    id: 'translation-model',
    kind: LocalComponentKind.model,
    label: LocalComponentLabel.translationModel,
    files: [
      LocalComponentFile(
        fileName: translationModelFileName,
        url:
            'https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/'
            'main/qwen2.5-0.5b-instruct-q4_k_m.gguf',
        bytes: 491400032,
        sha256: '74a4da8c9fdbcd15bd1f6d01d621410d31c6fc00986f5eb687824e7b93d7a9db',
      ),
    ],
    requiredFiles: [translationModelFileName],
    legacyFiles: ['translation/models/$translationModelFileName'],
  );

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

  static const LocalComponentSpec ffmpeg = LocalComponentSpec(
    id: 'ffmpeg',
    kind: LocalComponentKind.runtime,
    label: LocalComponentLabel.ffmpeg,
    archive: LocalComponentArchive.zip,
    executable: 'ffmpeg',
    files: [
      LocalComponentFile(
        fileName: 'ffmpeg-4.4.1-linux-64.zip',
        url:
            'https://github.com/ffbinaries/ffbinaries-prebuilt/releases/'
            'download/v4.4.1/ffmpeg-4.4.1-linux-64.zip',
        bytes: 27072705,
        sha256: '4348301b0d5e18174925e2022da1823aebbdb07282bbe9adb64b2485e1ef2df7',
      ),
    ],
    systemNames: ['ffmpeg'],
    systemPaths: ['/usr/bin/ffmpeg', '/usr/local/bin/ffmpeg'],
  );

  /// Everything the settings page lists, in display order.
  static const List<LocalComponentSpec> all = [
    translationRuntime,
    translationModel,
    whisperRuntime,
    ...whisperModels,
    sherpaRuntime,
    sensevoiceModel,
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
