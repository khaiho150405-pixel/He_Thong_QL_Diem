import 'package:flutter/material.dart';

Future<void> showRecognitionImage(
  BuildContext context, {
  required Widget image,
}) => showDialog<void>(
  context: context,
  builder: (context) => Dialog.fullscreen(
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Xem ảnh bảng điểm'),
        leading: IconButton(
          tooltip: 'Đóng ảnh',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Dùng hai ngón tay hoặc con lăn để phóng to, kéo để xem các ô điểm.',
            ),
          ),
          Expanded(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 8,
              child: SizedBox.expand(child: image),
            ),
          ),
        ],
      ),
    ),
  ),
);

String recognitionFailureMessage(String? code) => switch (code) {
  'ROW_MATCH_FAILED' =>
    'Không xác định được học sinh cho một số dòng. Kiểm tra đúng lớp và chụp lại rõ cột Họ tên.',
  'IMAGE_UNREADABLE' => 'Không đọc được tệp ảnh. Chọn ảnh PNG/JPEG khác.',
  'IMAGE_QUALITY_LOW' =>
    'Ảnh mờ hoặc độ phân giải thấp. Chụp lại gần hơn, đủ sáng, không rung.',
  'GRID_NOT_FOUND' =>
    'Không tìm thấy bảng kẻ ô trong ảnh. Chụp thẳng, đủ toàn bộ bảng.',
  'NOT_A_GRADEBOOK' => 'Ảnh không giống bảng điểm. Kiểm tra lại ảnh.',
  'SCORE_COLUMN_NOT_FOUND' =>
    'Không xác định được cột Điểm số/Điểm chữ. Chụp rõ hàng tiêu đề của bảng.',
  'GRADE_DEADLINE_EXPIRED' =>
    'Cột điểm đã hết hạn nhập; phiếu không còn được duyệt.',
  'MODEL_UNAVAILABLE' =>
    'Mô hình nhận diện chưa sẵn sàng. Liên hệ quản trị viên để cấu hình mô hình.',
  'QUEUE_UNAVAILABLE' =>
    'Hàng đợi nhận diện chưa sẵn sàng. Liên hệ quản trị viên để kiểm tra dịch vụ.',
  'MODEL_TIMEOUT' || 'RECOGNITION_TIMEOUT' =>
    'Nhận diện quá thời gian chờ. Kiểm tra dịch vụ trước khi gửi lại.',
  'RECOGNITION_SERVICE_ERROR' || 'MALFORMED_RESPONSE' =>
    'Dịch vụ nhận dạng gặp lỗi. Thử lại sau hoặc liên hệ quản trị viên.',
  'GRID_ROW_COUNT_MISMATCH' =>
    'Số dòng trong ảnh không phù hợp. Kiểm tra và chụp lại ảnh đủ bảng.',
  _ =>
    'Không hoàn tất nhận diện (${code ?? 'không xác định'}). Kiểm tra ảnh và liên hệ quản trị viên nếu lỗi lặp lại.',
};
