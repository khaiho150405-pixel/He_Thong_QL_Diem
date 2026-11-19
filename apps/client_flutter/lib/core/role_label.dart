String roleLabelOf(String role) => switch (role) {
  'QUAN_TRI_VIEN' => 'Quản trị viên',
  'GIAO_VIEN' => 'Giáo viên',
  'HOC_SINH' => 'Học sinh',
  _ => role,
};
