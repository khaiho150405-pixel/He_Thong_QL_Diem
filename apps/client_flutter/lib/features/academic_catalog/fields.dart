class FormFieldSpec {
  const FormFieldSpec(
    this.key,
    this.label,
    this.kind, {
    this.optional = false,
    this.reference,
  });
  final String key, label, kind;
  final bool optional;
  final String? reference;
}

class ResourceSpec {
  const ResourceSpec(this.key, this.label, this.id, this.fields);
  final String key, label, id;
  final List<FormFieldSpec> fields;
}

const resources = <ResourceSpec>[
  ResourceSpec('years', 'Năm học', 'ma_nam_hoc', [
    FormFieldSpec('ten', 'Tên', 'text', optional: false),
    FormFieldSpec('ngay_bat_dau', 'Ngày bắt đầu', 'date', optional: false),
    FormFieldSpec('ngay_ket_thuc', 'Ngày kết thúc', 'date', optional: false),
    FormFieldSpec('hien_hanh', 'Năm hiện hành', 'boolean', optional: false),
  ]),
  ResourceSpec('semesters', 'Học kỳ', 'ma_hoc_ky', [
    FormFieldSpec(
      'ma_nam_hoc',
      'Năm học',
      'int',
      optional: false,
      reference: 'years',
    ),
    FormFieldSpec('ten', 'Tên', 'text', optional: false),
    FormFieldSpec('thu_tu', 'Thứ tự', 'int', optional: false),
    FormFieldSpec('ngay_bat_dau', 'Ngày bắt đầu', 'date', optional: false),
    FormFieldSpec('ngay_ket_thuc', 'Ngày kết thúc', 'date', optional: false),
  ]),
  ResourceSpec('classes', 'Lớp học', 'ma_lop', [
    FormFieldSpec(
      'ma_nam_hoc',
      'Năm học',
      'int',
      optional: false,
      reference: 'years',
    ),
    FormFieldSpec(
      'ma_gv_chu_nhiem',
      'Giáo viên chủ nhiệm',
      'int',
      optional: false,
      reference: 'teachers',
    ),
    FormFieldSpec('ten_lop', 'Tên lớp', 'text', optional: false),
    FormFieldSpec('khoi', 'Khối', 'int', optional: false),
  ]),
  ResourceSpec('students', 'Học sinh', 'ma_hoc_sinh', [
    FormFieldSpec(
      'ma_nguoi_dung',
      'Tài khoản học sinh',
      'int',
      optional: true,
      reference: 'accounts',
    ),
    FormFieldSpec(
      'ma_lop',
      'Lớp',
      'int',
      optional: false,
      reference: 'classes',
    ),
    FormFieldSpec('ho_ten', 'Họ và tên', 'text', optional: false),
    FormFieldSpec('ngay_sinh', 'Ngày sinh', 'date', optional: false),
    FormFieldSpec('dang_theo_hoc', 'Đang theo học', 'boolean', optional: false),
  ]),
  ResourceSpec('subjects', 'Môn học', 'ma_mon', [
    FormFieldSpec('ten_mon', 'Tên môn', 'text', optional: false),
    FormFieldSpec('so_tiet_tuan', 'Số tiết mỗi tuần', 'int', optional: false),
  ]),
  ResourceSpec('components', 'Thành phần điểm', 'ma_thanh_phan', [
    FormFieldSpec(
      'ma_mon',
      'Môn học',
      'int',
      optional: false,
      reference: 'subjects',
    ),
    FormFieldSpec('ten_thanh_phan', 'Tên thành phần', 'text', optional: false),
    FormFieldSpec('he_so', 'Hệ số', 'decimal', optional: false),
    FormFieldSpec('bat_buoc', 'Bắt buộc', 'boolean', optional: false),
    FormFieldSpec('thu_tu_hien_thi', 'Thứ tự hiển thị', 'int', optional: false),
  ]),
  ResourceSpec('teachers', 'Giáo viên', 'ma_giao_vien', [
    FormFieldSpec(
      'ma_giao_vien',
      'Giáo viên',
      'int',
      optional: false,
      reference: 'accounts',
    ),
    FormFieldSpec('ho_ten', 'Họ và tên', 'text', optional: false),
    FormFieldSpec('to_chuyen_mon', 'Tổ chuyên môn', 'text', optional: true),
    FormFieldSpec('email', 'Email', 'text', optional: true),
    FormFieldSpec('dien_thoai', 'Điện thoại', 'text', optional: true),
  ]),
  ResourceSpec('assignments', 'Phân công', 'ma_phan_cong', [
    FormFieldSpec(
      'ma_giao_vien',
      'Giáo viên',
      'int',
      optional: false,
      reference: 'teachers',
    ),
    FormFieldSpec(
      'ma_lop',
      'Lớp',
      'int',
      optional: false,
      reference: 'classes',
    ),
    FormFieldSpec(
      'ma_mon',
      'Môn học',
      'int',
      optional: false,
      reference: 'subjects',
    ),
    FormFieldSpec(
      'ma_hoc_ky',
      'Học kỳ',
      'int',
      optional: false,
      reference: 'semesters',
    ),
    FormFieldSpec('ngay_phan_cong', 'Ngày phân công', 'date', optional: false),
  ]),
  ResourceSpec('accounts', 'Tài khoản', 'id', [
    FormFieldSpec('username', 'Tên đăng nhập', 'text'),
    FormFieldSpec('password', 'Mật khẩu mới (ít nhất 12 ký tự)', 'password'),
    FormFieldSpec('role', 'Vai trò', 'role'),
    FormFieldSpec('active', 'Cho phép đăng nhập', 'boolean'),
  ]),
];
String rowLabel(Map<String, dynamic> row) =>
    (row['label'] ??
            row['ho_ten'] ??
            row['ten_lop'] ??
            row['ten_mon'] ??
            row['ten_thanh_phan'] ??
            row['ten'] ??
            row['username'] ??
            'Phân công')
        .toString();
String roleLabel(String role) => switch (role) {
  'QUAN_TRI_VIEN' => 'Quản trị viên',
  'GIAO_VIEN' => 'Giáo viên',
  'HOC_SINH' => 'Học sinh',
  _ => role,
};
