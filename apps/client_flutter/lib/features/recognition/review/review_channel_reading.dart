import 'package:flutter/material.dart';

import '../../../app/design_tokens.dart';

enum ReviewChannel { numeric, written }

String? reviewConfidenceText(String? raw) {
  final value = double.tryParse(raw ?? '');
  if (value == null) return null;
  return '${(value * 100).round()}%';
}

String reviewReadingText({
  required ReviewChannel channel,
  required String? raw,
  required String? value,
  required String? confidence,
}) {
  final percent = reviewConfidenceText(confidence);
  final text = raw?.trim() ?? '';
  final parts = <String>[];
  if (channel == ReviewChannel.numeric) {
    parts.add(value == null ? 'Không đọc được' : 'Máy đọc ${value.trim()}');
  } else if (value != null && text.isNotEmpty) {
    parts.add('Chữ đọc được "$text" → $value');
  } else if (value != null) {
    parts.add('Điểm quy đổi $value');
  } else if (text.isNotEmpty) {
    parts.add('Chữ đọc được "$text", không quy đổi được điểm');
  } else {
    parts.add('Không đọc được');
  }
  if (percent != null) parts.add('Tin cậy $percent');
  return parts.join(' · ');
}

class ReviewChannelReading extends StatelessWidget {
  const ReviewChannelReading({
    super.key,
    required this.channel,
    required this.raw,
    required this.value,
    required this.confidence,
    this.compact = false,
  });

  final ReviewChannel channel;
  final String? raw;
  final String? value;
  final String? confidence;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final unreadable = value == null && (raw?.trim().isEmpty ?? true);
    return Text(
      reviewReadingText(
        channel: channel,
        raw: raw,
        value: value,
        confidence: confidence,
      ),
      maxLines: compact ? 2 : 3,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: compact ? 11 : 12,
        fontWeight: FontWeight.w600,
        color: unreadable ? t.bad : t.ink2,
      ),
    );
  }
}
