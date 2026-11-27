import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:project_zerotype/services/bhashini_service.dart';

void main() {
  group('BhashiniService (NMT Translation Only) Tests', () {
    test('translate discovers pipeline config and translates text cleanly', () async {
      final client = MockClient((request) async {
        if (request.url.path.contains('getModelsPipeline')) {
          return http.Response(
            jsonEncode({
              'pipelineInferenceAPIEndPoint': {
                'callbackUrl': 'https://mock-dhruva.example.com/services/inference/pipeline',
                'inferenceApiKey': {'value': 'mock-inference-key'},
              },
              'pipelineResponseConfig': [
                {
                  'taskType': 'translation',
                  'config': [
                    {'serviceId': 'ai4bharat/indictrans-v2-all-gpu--t4'},
                  ],
                },
              ],
            }),
            200,
          );
        }

        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'pipelineResponse': [
                {
                  'output': [
                    {'target': 'हस्तनिर्मित मिट्टी का घड़ा'},
                  ],
                },
              ],
            }),
          ),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = BhashiniService(client: client);
      addTearDown(service.dispose);

      final translated = await service.translate(
        'Handmade Clay Pot',
        sourceLanguage: 'en',
        targetLanguage: 'hi',
      );
      expect(translated, equals('हस्तनिर्मित मिट्टी का घड़ा'));
    });

    test('translate throws BhashiniException when output is empty', () async {
      final client = MockClient((request) async {
        if (request.url.path.contains('getModelsPipeline')) {
          return http.Response(
            jsonEncode({
              'pipelineInferenceAPIEndPoint': {
                'callbackUrl': 'https://mock-dhruva.example.com/services/inference/pipeline',
                'inferenceApiKey': {'value': 'mock-inference-key'},
              },
              'pipelineResponseConfig': [
                {
                  'taskType': 'translation',
                  'config': [
                    {'serviceId': 'ai4bharat/indictrans-v2-all-gpu--t4'},
                  ],
                },
              ],
            }),
            200,
          );
        }

        return http.Response(
          jsonEncode({
            'pipelineResponse': [
              {
                'output': [
                  {'target': ''},
                ],
              },
            ],
          }),
          200,
        );
      });

      final service = BhashiniService(client: client);
      addTearDown(service.dispose);

      await expectLater(
        service.translate('Clay Pot', sourceLanguage: 'en', targetLanguage: 'ta'),
        throwsA(isA<BhashiniException>()),
      );
    });
  });
}
