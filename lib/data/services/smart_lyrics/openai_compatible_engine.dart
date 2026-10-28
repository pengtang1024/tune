import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_engine.dart';
import 'package:tune/utils/logger.dart';

/// Speaks the OpenAI dialect for the smart lyrics pipeline
/// (docs/smart-lyrics.md §6.1): the transcriptions of the audio and the
/// completions of the text model, on the endpoint the reader configured.
class OpenAiCompatibleClient {
  final Dio _dio;
  final String baseUrl;
  final String apiKey;

  OpenAiCompatibleClient({
    required Dio dio,
    required this.baseUrl,
    required this.apiKey,
  }) : _dio = dio;

  /// Reads the words off the audio with [model].
  ///
  /// The answer is asked as `verbose_json`, so a well-behaved endpoint
  /// hands back segments with their places in time. An endpoint that
  /// answers plain text, or with a shape nothing knows, comes back as an
  /// empty sheet — a reference vote at best, never a lie about the time. A
  /// request that never arrived is an error: the channel failed, and the
  /// pool votes without it.
  Future<TranscriptionResult> transcribe({
    required String model,
    required File audio,
  }) async {
    final Map<String, dynamic> answer;
    try {
      final form = FormData.fromMap({
        'model': model,
        'response_format': 'verbose_json',
        'file': await MultipartFile.fromFile(audio.path),
      });
      answer = await _post('$baseUrl/audio/transcriptions', form);
    } on SmartLyricsEndpointException catch (error, stackTrace) {
      Log.error('云端转写的回答读不懂: $error', stackTrace);
      return const TranscriptionResult(segments: []);
    } on FormatException catch (error, stackTrace) {
      Log.error('云端转写的回答读不懂: $error', stackTrace);
      return const TranscriptionResult(segments: []);
    }
    return _transcriptionOf(answer);
  }

  /// Asks the text model [prompt], and answers with what it said.
  Future<String> complete({required String model, required String prompt}) async {
    final answer = await _post('$baseUrl/chat/completions', {
      'model': model,
      'temperature': 0,
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
    });
    final choices = answer['choices'];
    if (choices is List && choices.isNotEmpty) {
      final first = choices.first;
      if (first is Map) {
        final message = first['message'];
        if (message is Map && message['content'] is String) {
          return message['content'] as String;
        }
      }
    }
    throw const SmartLyricsEndpointException('the answer has no content');
  }

  Future<Map<String, dynamic>> _post(String url, Object data) async {
    final response = await _dio.post(
      url,
      data: data,
      options: Options(
        headers: {'authorization': 'Bearer $apiKey'},
        // A body of any shape arrives: the parsing decides what it is.
        responseType: ResponseType.plain,
      ),
    );
    final raw = response.data;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.trim().isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    throw const SmartLyricsEndpointException('the answer is not an object');
  }

  TranscriptionResult _transcriptionOf(Map<String, dynamic> answer) {
    final segments = answer['segments'];
    final language = answer['language'] is String
        ? answer['language'] as String
        : null;
    if (segments is! List) {
      return TranscriptionResult(segments: const [], language: language);
    }
    return TranscriptionResult(
      language: language,
      segments: [
        for (final segment in segments)
          if (segment is Map)
            TranscribedSegment(
              start: _secondsOf(segment['start']),
              end: _secondsOf(segment['end']),
              text: segment['text'] is String
                  ? (segment['text'] as String).trim()
                  : '',
            ),
      ],
    );
  }

  /// The seconds an endpoint declared, as the clock reads them.
  static Duration _secondsOf(Object? value) {
    final seconds = value is num ? value.toDouble() : double.tryParse('$value');
    if (seconds == null) return Duration.zero;
    return Duration(milliseconds: (seconds * 1000).round());
  }
}

/// The endpoint answered with something nothing can vote on.
class SmartLyricsEndpointException implements Exception {
  final String message;

  const SmartLyricsEndpointException(this.message);

  @override
  String toString() => 'SmartLyricsEndpointException: $message';
}

/// One cloud channel: the endpoint with one model name.
class OpenAiCompatibleEngine extends SmartLyricsEngine {
  final String model;
  final OpenAiCompatibleClient client;

  OpenAiCompatibleEngine({required this.model, required this.client});

  @override
  String get id => 'cloud:$model';

  @override
  Future<TranscriptionResult> runTranscription(
    SmartAudioInput input, {
    void Function(double progress)? onProgress,
  }) => client.transcribe(model: model, audio: input.audio);
}
