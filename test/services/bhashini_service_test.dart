import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:project_zerotype/services/bhashini_service.dart';

void main() {
  group('BhashiniService Tests', () {
    test(
      'normalizeWavToPcm16 converts 32-bit IEEE float WAV into 16-bit PCM WAV',
      () {
        // Build a synthetic 32-bit IEEE float WAV (format tag 3) with 2 samples
        const sampleRate = 22050;
        const numChannels = 1;
        const sampleCount = 2;
        final dataSize = sampleCount * 4;
        final bytes = Uint8List(44 + dataSize);
        final bd = ByteData.view(bytes.buffer);

        bytes.setAll(0, [0x52, 0x49, 0x46, 0x46]); // RIFF
        bd.setUint32(4, 36 + dataSize, Endian.little);
        bytes.setAll(8, [0x57, 0x41, 0x56, 0x45]); // WAVE
        bytes.setAll(12, [0x66, 0x6D, 0x74, 0x20]); // fmt
        bd.setUint32(16, 16, Endian.little);
        bd.setUint16(20, 3, Endian.little); // IEEE float
        bd.setUint16(22, numChannels, Endian.little);
        bd.setUint32(24, sampleRate, Endian.little);
        bd.setUint32(28, sampleRate * numChannels * 4, Endian.little);
        bd.setUint16(32, numChannels * 4, Endian.little);
        bd.setUint16(34, 32, Endian.little); // 32-bit float
        bytes.setAll(36, [0x64, 0x61, 0x74, 0x61]); // data
        bd.setUint32(40, dataSize, Endian.little);
        bd.setFloat32(44, 0.5, Endian.little);
        bd.setFloat32(48, -1.0, Endian.little);

        final pcmBytes = BhashiniService.normalizeWavToPcm16(bytes);
        final outBd = ByteData.sublistView(pcmBytes);

        expect(pcmBytes.length, equals(44 + sampleCount * 2));
        expect(outBd.getUint16(20, Endian.little), equals(1)); // PCM format 1
        expect(outBd.getUint32(24, Endian.little), equals(sampleRate));
        expect(outBd.getUint16(34, Endian.little), equals(16)); // 16-bit
        expect(outBd.getInt16(44, Endian.little), closeTo(13926, 2));
        expect(outBd.getInt16(46, Endian.little), closeTo(-27852, 2));
      },
    );
  });
}
