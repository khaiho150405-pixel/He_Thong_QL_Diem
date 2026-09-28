class TimetableItem {
  final int maTietHoc;
  final int maLop;
  final String tenLop;
  final int maMon;
  final String tenMon;
  final int maGiaoVien;
  final String tenGiaoVien;
  final int maHocKy;
  final String tenHocKy;
  final int thu; // 2 -> 8 (Thứ Hai -> Chủ nhật)
  final int tiet; // 1 -> 10
  final String? phongHoc;
  final String? ghiChu;

  const TimetableItem({
    required this.maTietHoc,
    required this.maLop,
    required this.tenLop,
    required this.maMon,
    required this.tenMon,
    required this.maGiaoVien,
    required this.tenGiaoVien,
    required this.maHocKy,
    required this.tenHocKy,
    required this.thu,
    required this.tiet,
    this.phongHoc,
    this.ghiChu,
  });

  factory TimetableItem.fromJson(Map<String, dynamic> json) {
    return TimetableItem(
      maTietHoc: (json['ma_tiet_hoc'] as num?)?.toInt() ?? 0,
      maLop: (json['ma_lop'] as num?)?.toInt() ?? 0,
      tenLop: json['ten_lop']?.toString() ?? '',
      maMon: (json['ma_mon'] as num?)?.toInt() ?? 0,
      tenMon: json['ten_mon']?.toString() ?? '',
      maGiaoVien: (json['ma_giao_vien'] as num?)?.toInt() ?? 0,
      tenGiaoVien: json['ten_giao_vien']?.toString() ?? '',
      maHocKy: (json['ma_hoc_ky'] as num?)?.toInt() ?? 0,
      tenHocKy: json['ten_hoc_ky']?.toString() ?? '',
      thu: (json['thu'] as num?)?.toInt() ?? 2,
      tiet: (json['tiet'] as num?)?.toInt() ?? 1,
      phongHoc: json['phong_hoc']?.toString(),
      ghiChu: json['ghi_chu']?.toString(),
    );
  }

  String get thuLabel {
    switch (thu) {
      case 2:
        return 'Thứ Hai';
      case 3:
        return 'Thứ Ba';
      case 4:
        return 'Thứ Tư';
      case 5:
        return 'Thứ Năm';
      case 6:
        return 'Thứ Sáu';
      case 7:
        return 'Thứ Bảy';
      case 8:
        return 'Chủ nhật';
      default:
        return 'Thứ $thu';
    }
  }

  String get sessionLabel => tiet <= 5 ? 'Buổi sáng' : 'Buổi chiều';

  String get timeSlotLabel {
    switch (tiet) {
      case 1:
        return '07:00 - 07:45';
      case 2:
        return '07:50 - 08:35';
      case 3:
        return '08:50 - 09:35';
      case 4:
        return '09:40 - 10:25';
      case 5:
        return '10:30 - 11:15';
      case 6:
        return '13:00 - 13:45';
      case 7:
        return '13:50 - 14:35';
      case 8:
        return '14:50 - 15:35';
      case 9:
        return '15:40 - 16:25';
      case 10:
        return '16:30 - 17:15';
      default:
        return 'Tiết $tiet';
    }
  }
}
