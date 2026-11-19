import 'package:client_flutter/app/theme.dart';
import 'package:client_flutter/features/recognition/review/review_channel_reading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('kênh điểm số: giá trị chuẩn hóa và độ tin cậy phần trăm', () {
    expect(
      reviewReadingText(
        channel: ReviewChannel.numeric,
        raw: '8,5',
        value: '8.5',
        confidence: '0.9640',
      ),
      'Máy đọc 8.5 · Tin cậy 96%',
    );
  });

  test('kênh điểm chữ: chữ đọc được kèm điểm quy đổi', () {
    expect(
      reviewReadingText(
        channel: ReviewChannel.written,
        raw: 'tám rưỡi',
        value: '8.5',
        confidence: '0.9300',
      ),
      'Chữ đọc được "tám rưỡi" → 8.5 · Tin cậy 93%',
    );
    expect(
      reviewReadingText(
        channel: ReviewChannel.written,
        raw: null,
        value: '8.5',
        confidence: null,
      ),
      'Điểm quy đổi 8.5',
    );
    expect(
      reviewReadingText(
        channel: ReviewChannel.written,
        raw: 'bảy',
        value: null,
        confidence: '0.4000',
      ),
      'Chữ đọc được "bảy", không quy đổi được điểm · Tin cậy 40%',
    );
  });

  test('kênh không đọc được ghi rõ Không đọc được', () {
    expect(
      reviewReadingText(
        channel: ReviewChannel.numeric,
        raw: null,
        value: null,
        confidence: null,
      ),
      'Không đọc được',
    );
    expect(
      reviewReadingText(
        channel: ReviewChannel.written,
        raw: '  ',
        value: null,
        confidence: '0.1000',
      ),
      'Không đọc được · Tin cậy 10%',
    );
  });

  testWidgets('widget hiện văn bản đọc của kênh', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: ReviewChannelReading(
            channel: ReviewChannel.numeric,
            raw: '9.0',
            value: '9.0',
            confidence: '0.9100',
          ),
        ),
      ),
    );
    expect(find.text('Máy đọc 9.0 · Tin cậy 91%'), findsOneWidget);
  });
}
