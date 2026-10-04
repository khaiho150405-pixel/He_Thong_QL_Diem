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
  'MODEL_UNAVAILABLE' =>
    'Mô hình nhận diện chưa sẵn sàng. Liên hệ quản trị viên để cấu hình mô hình.',
  'QUEUE_UNAVAILABLE' =>
    'Hàng đợi nhận diện chưa sẵn sàng. Liên hệ quản trị viên để kiểm tra dịch vụ.',
  'GRID_ROW_COUNT_MISMATCH' =>
    'Số dòng trong ảnh không khớp danh sách học sinh. Kiểm tra thứ tự và chụp đủ bảng rồi gửi ảnh mới.',
  'MODEL_TIMEOUT' =>
    'Nhận diện quá thời gian chờ. Kiểm tra dịch vụ trước khi gửi lại.',
  _ =>
    'Không hoàn tất nhận diện (${code ?? 'không xác định'}). Kiểm tra ảnh và liên hệ quản trị viên nếu lỗi lặp lại.',
};
