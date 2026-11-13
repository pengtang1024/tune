import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/translation/translation_prompt.dart';

void main() {
  group('translationPayload', () {
    test('numbers the items so the answer can find them again', () {
      final decoded = jsonDecode(translationPayload(['One', 'Two'])) as List;
      expect(decoded, [
        {'id': 0, 'text': 'One'},
        {'id': 1, 'text': 'Two'},
      ]);
    });

    test('names the target language in the instruction', () {
      expect(translationInstruction('zh-CN'), contains('zh-CN'));
    });
  });

  group('parseTranslationPayload', () {
    const sources = ['Blue in Green', 'Kind of Blue'];

    test('reads a clean array', () {
      final raw = jsonEncode([
        {'id': 0, 'text': '绿中蓝'},
        {'id': 1, 'text': '泛蓝'},
      ]);
      expect(parseTranslationPayload(raw, sources), {
        'Blue in Green': '绿中蓝',
        'Kind of Blue': '泛蓝',
      });
    });

    test('reads an array the model wrapped in prose', () {
      const raw = 'Here you go:\n[{"id": 1, "text": "泛蓝"}]\nHope that helps.';
      expect(parseTranslationPayload(raw, sources), {'Kind of Blue': '泛蓝'});
    });

    test('drops the ids it does not know', () {
      const raw = '[{"id": 9, "text": "越界"}]';
      expect(parseTranslationPayload(raw, sources), isEmpty);
    });

    test('drops an empty answer', () {
      const raw = '[{"id": 0, "text": "   "}]';
      expect(parseTranslationPayload(raw, sources), isEmpty);
    });

    test('drops a runaway generation', () {
      final raw = jsonEncode([
        {'id': 0, 'text': '长' * 400},
      ]);
      expect(parseTranslationPayload(raw, sources), isEmpty);
    });

    test('drops an answer that broke into lines', () {
      const raw = '[{"id": 0, "text": "绿中\\n蓝"}]';
      expect(parseTranslationPayload(raw, sources), isEmpty);
    });

    test('accepts a bare answer for a single item', () {
      expect(parseTranslationPayload('"绿中蓝"', const ['Blue in Green']), {
        'Blue in Green': '绿中蓝',
      });
    });

    test('a bare answer needs exactly one item', () {
      expect(parseTranslationPayload('绿中蓝', sources), isEmpty);
    });

    test('an unusable body yields nothing', () {
      expect(parseTranslationPayload('', const ['Blue in Green']), isEmpty);
    });
  });
}
