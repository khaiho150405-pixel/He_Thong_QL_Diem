export const DB_MESSAGES: Record<string, string> = {
  ADJUSTMENT_IMMUTABLE: "Đơn điều chỉnh đã xử lý, không sửa được nữa.",
  ADJUSTMENT_LINES_APPEND_ONLY:
    "Không sửa hoặc xóa dòng của đơn điều chỉnh đã gửi.",
  ADJUSTMENT_LINE_BOOK_MISMATCH:
    "Dòng điều chỉnh không thuộc bảng điểm của đơn.",
  ADJUSTMENT_NOT_PENDING: "Đơn điều chỉnh không còn ở trạng thái chờ duyệt.",
  ADJUSTMENT_NO_CHANGE: "Đơn không có thay đổi nào so với điểm hiện tại.",
  ADJUSTMENT_PENDING_EXISTS:
    "Bảng điểm đang có một đơn điều chỉnh chờ duyệt; xử lý đơn đó trước.",
  ADJUSTMENT_STALE:
    "Điểm của một ô trong đơn đã thay đổi sau lúc gửi; từ chối đơn và gửi lại.",
  ADJUSTMENT_VERSION_OR_STATE_CONFLICT:
    "Bảng điểm hoặc đơn điều chỉnh vừa thay đổi; tải lại rồi thử lại.",
  ALL_ROWS_REQUIRED:
    "Phải quyết định giá trị cho mọi dòng bắt buộc xem trước khi duyệt phiếu.",
  APPEND_ONLY: "Lịch sử chỉ được ghi thêm, không được sửa hoặc xóa.",
  ASSIGNMENT_IN_TIMETABLE:
    "Phân công đang được dùng trong thời khóa biểu; xóa hoặc đổi các tiết học trước.",
  ASSIGNMENT_YEAR_MISMATCH:
    "Lớp và học kỳ của phân công thuộc hai năm học khác nhau.",
  AUDIT_APPEND_ONLY: "Nhật ký hệ thống không được sửa hoặc xóa.",
  BATCH_DELETE_FORBIDDEN: "Không được xóa lô nhận dạng; hãy hủy lô.",
  BATCH_NOT_FOUND: "Không tìm thấy lô nhận dạng.",
  BATCH_NOT_PROCESSING: "Lô nhận dạng không còn ở trạng thái đang xử lý.",
  BATCH_ROW_PAGE_MISMATCH: "Kết quả nhận dạng trỏ tới trang không có trong lô.",
  CELL_EXEMPT: "Ô được miễn; bỏ miễn trước khi nhập điểm cho ô này.",
  CELL_HAS_VALUE:
    "Ô đã có điểm hoặc đang chờ đối chiếu; chỉ miễn được ô còn trống.",
  CELL_NOT_EDITABLE:
    "Không sửa được ô này: học sinh đã nghỉ hoặc chuyển lớp, hoặc cột không cho nhập.",
  CELL_NOT_EXEMPT: "Ô này không ở trạng thái miễn.",
  CELL_NOT_LOCKED:
    "Cột của ô này còn mở: nhập điểm trực tiếp, đơn điều chỉnh chỉ dùng cho cột đã khóa.",
  CELL_OUTSIDE_BOOK: "Ô điểm không thuộc bảng điểm này.",
  CLASSIFICATION_POLICY_GAP:
    "Chính sách xếp loại không phủ hết thang điểm; quản trị viên cần cập nhật.",
  CLASSIFICATION_POLICY_INCOMPLETE:
    "Chính sách xếp loại thiếu mức bắt đầu từ 0.0 hoặc thiếu mức đạt/không đạt.",
  CLASSIFICATION_POLICY_UNAVAILABLE:
    "Chưa có chính sách làm tròn điểm đang áp dụng; quản trị viên cần kích hoạt một chính sách.",
  COLUMNS_WITHOUT_DEADLINE: "Còn cột điểm chưa được đặt lịch nhập.",
  COLUMN_LOCKED: "Cột điểm đã khóa; muốn sửa hãy gửi đơn điều chỉnh.",
  COLUMN_LOCK_APPEND_ONLY: "Cột đã khóa thì không mở lại được.",
  COLUMN_NOT_OPEN:
    "Cột điểm chưa mở, đã hết hạn hoặc đã khóa; không đặt hoặc bỏ miễn được.",
  COMPONENT_NOT_MAPPABLE:
    "Cột điểm đã chọn không ghép được với cột của mẫu bảng điểm.",
  COMPONENT_OUTSIDE_BOOK: "Cột điểm không thuộc môn của bảng điểm này.",
  COMPONENT_SUBJECT_MISMATCH: "Thành phần điểm không thuộc môn của bảng điểm.",
  DEADLINE_VERSION_CONFLICT:
    "Lịch nhập điểm vừa thay đổi; tải lại trước khi lưu.",
  DUPLICATE_CELL: "Một ô điểm xuất hiện nhiều lần trong cùng lần lưu.",
  DUPLICATE_FILE: "Ảnh này đã được tải lên ở một phiếu khác.",
  DUPLICATE_REVIEW_ROW: "Một dòng xuất hiện nhiều lần trong lần duyệt.",
  DUPLICATE_STUDENT: "Một học sinh xuất hiện nhiều lần trong danh sách.",
  EFFECTIVE_DATE_OUT_OF_RANGE:
    "Ngày hiệu lực phải nằm trong năm học và sau ngày bắt đầu ghi danh hiện tại.",
  ENROLLMENT_APPEND_ONLY: "Lịch sử xếp lớp không được xóa.",
  ENROLLMENT_NOT_ACTIVE: "Học sinh không đang học ở lớp được chọn.",
  ENROLLMENT_YEAR_MISMATCH: "Lớp không thuộc năm học của ghi danh.",
  EXEMPTION_HISTORY_APPEND_ONLY: "Lịch sử miễn điểm không được sửa hoặc xóa.",
  EXEMPTION_VERSION_OR_STATE_CONFLICT:
    "Bảng điểm vừa thay đổi hoặc đã khóa; tải lại rồi thử lại.",
  EXEMPT_CELL_FORBIDDEN: "Không được tạo trực tiếp ô miễn điểm.",
  FORBIDDEN_OR_STATE_CONFLICT:
    "Bạn không có quyền, hoặc dữ liệu đã đổi trạng thái; tải lại rồi thử lại.",
  GRADEBOOK_EMPTY_ROSTER_OR_COMPONENTS:
    "Lớp chưa có học sinh đang học hoặc môn học chưa có thành phần điểm.",
  GRADEBOOK_FORBIDDEN:
    "Bạn chưa được phân công dạy môn này cho lớp và học kỳ đã chọn.",
  GRADEBOOK_NOT_EDITABLE:
    "Bảng điểm đã khóa; muốn sửa hãy gửi đơn điều chỉnh để quản trị viên duyệt.",
  GRADEBOOK_NOT_LOCKED:
    "Bảng điểm chưa khóa nên chưa tổng kết được; chờ hết hạn nhập của mọi cột.",
  GRADEBOOK_VERSION_OR_STATE_CONFLICT:
    "Bảng điểm vừa được thay đổi; tải lại để xem dữ liệu mới nhất rồi thử lại.",
  GRADEBOOK_YEAR_MISMATCH: "Lớp và học kỳ thuộc hai năm học khác nhau.",
  GRADE_CELL_NOT_FOUND: "Không tìm thấy ô điểm.",
  GRADE_ENTRY_WINDOW_CLOSED:
    "Chưa đến thời gian nhập hoặc đã hết hạn do nhà trường đặt; không được nhập/duyệt thêm.",
  GRADE_STUDENT_NOT_ENROLLED: "Học sinh không thuộc lớp của bảng điểm.",
  GRID_ROW_COUNT_MISMATCH:
    "Số dòng trên ảnh không khớp danh sách lớp; chụp lại đủ bảng điểm.",
  IDEMPOTENCY_MISMATCH:
    "Mã yêu cầu đã dùng cho một thao tác khác; tải lại trang rồi thử lại.",
  INCOMPLETE_COLUMN:
    "Cột còn thiếu điểm bắt buộc hoặc thiếu học sinh; nhập đủ và đồng bộ sĩ số trước khi khóa.",
  INCOMPLETE_ROSTER_OR_REQUIRED_GRADES:
    "Còn học sinh thiếu điểm bắt buộc hoặc chưa có trong bảng điểm.",
  INVALID_ADJUSTMENT_CHANGE:
    "Dòng điều chỉnh không hợp lệ: cần điểm mới hoặc miễn, kèm ghi chú đúng độ dài.",
  INVALID_ADJUSTMENT_REQUEST:
    "Đơn điều chỉnh không hợp lệ: cần lý do và ít nhất một dòng thay đổi.",
  INVALID_BATCH_SIZE: "Mỗi lần lưu chỉ từ 1 đến 100 ô điểm.",
  INVALID_CANCEL_REQUEST: "Lý do hủy phải có từ 1 đến 200 ký tự.",
  INVALID_CHANGE: "Một thay đổi điểm thiếu ô, giá trị hoặc lý do.",
  INVALID_CHANGES: "Danh sách thay đổi điểm không hợp lệ.",
  INVALID_CLASSIFICATION_CRITERION: "Một mức xếp loại không hợp lệ.",
  INVALID_CLASSIFICATION_POLICY: "Chính sách xếp loại không hợp lệ.",
  INVALID_ENROLLMENT_REQUEST:
    "Yêu cầu xếp lớp không hợp lệ: kiểm tra ngày hiệu lực và lý do.",
  INVALID_ENTRY_WINDOW:
    "Thời điểm đóng phải sau thời điểm mở và nằm trong tương lai.",
  INVALID_ERROR_CODE: "Mã lỗi nhận dạng không hợp lệ.",
  INVALID_EXEMPTION_CHANGE: "Dòng miễn điểm không hợp lệ.",
  INVALID_EXEMPTION_REQUEST: "Yêu cầu miễn điểm cần lý do và ít nhất một ô.",
  INVALID_FINAL_RESULT_REQUEST:
    "Yêu cầu tổng kết cần lý do từ 1 đến 500 ký tự.",
  INVALID_GRADE: "Điểm phải từ 0.0 đến 10.0, bước 0.1.",
  INVALID_LATE_STUDENT_REQUEST:
    "Thêm học sinh vào bảng cần chọn học sinh và lý do.",
  INVALID_LOGO_FILE: "Logo phải là ảnh PNG hoặc JPEG hợp lệ, tối đa 1 MB.",
  INVALID_OPERATION_RATE_LIMIT: "Cấu hình giới hạn thao tác không hợp lệ.",
  INVALID_REASON: "Lý do sửa điểm phải có từ 1 đến 500 ký tự.",
  INVALID_RECOGNITION_REQUEST: "Yêu cầu nhận dạng không hợp lệ.",
  INVALID_REMOVAL_REQUEST: "Yêu cầu xóa học sinh không hợp lệ.",
  INVALID_REVIEW_DECISION: "Một dòng duyệt thiếu giá trị hoặc lý do.",
  INVALID_REVIEW_GRADE: "Điểm duyệt phải từ 0.0 đến 10.0, bước 0.1.",
  INVALID_REVIEW_REASON: "Lý do duyệt phải có từ 1 đến 500 ký tự.",
  INVALID_REVIEW_REQUEST: "Yêu cầu duyệt phiếu không hợp lệ.",
  INVALID_ROSTER_SNAPSHOT: "Danh sách lớp chốt cho phiếu không hợp lệ.",
  INVALID_SCHOOL_PROFILE: "Thông tin trường không hợp lệ.",
  INVALID_TEMPLATE_DEFINITION: "Định nghĩa mẫu bảng điểm không hợp lệ.",
  INVALID_WEIGHTS: "Hệ số của các cột điểm phải lớn hơn 0.",
  MALFORMED_RECOGNITION_RESULT:
    "Dịch vụ nhận dạng trả về dữ liệu không hợp lệ.",
  NO_RESULTS_TO_PUBLISH: "Học kỳ chưa có kết quả để công bố.",
  PASS_FAIL_SUBJECT_NOT_RECOGNIZABLE:
    "Môn đánh giá Đạt/Không đạt không dùng nhận dạng ảnh.",
  PASS_FAIL_VALUE_REQUIRED: "Môn Đạt/Không đạt chỉ nhận Đạt hoặc Không đạt.",
  PENDING_REVIEW:
    "Còn phiếu nhận dạng đang xử lý hoặc chờ duyệt; xử lý xong trước.",
  PROFILE_ROLE_MISMATCH:
    "Vai trò của tài khoản không khớp với hồ sơ giáo viên/học sinh.",
  RECOGNITION_ALREADY_PENDING:
    "Thành phần điểm này đang có phiếu chờ xử lý/đối chiếu; duyệt hoặc hủy phiếu đó trước.",
  REVIEW_ROW_NOT_AVAILABLE: "Dòng nhận dạng không còn khả dụng để duyệt.",
  ROSTER_APPEND_ONLY: "Danh sách lớp đã chốt của phiếu không được sửa.",
  ROW_CELL_MISMATCH: "Dòng nhận dạng không khớp với ô điểm.",
  ROW_STUDENT_EXEMPT:
    "Học sinh ở dòng này được miễn cột điểm; không duyệt giá trị cho dòng này.",
  ROW_STUDENT_NOT_IN_ROSTER:
    "Học sinh của dòng không có trong danh sách lớp đã chốt của phiếu.",
  SCHOOL_PROFILE_PROTECTED: "Hồ sơ trường không được xóa.",
  SCHOOL_PROFILE_VERSION_CONFLICT:
    "Thông tin trường vừa được người khác thay đổi; tải lại rồi thử lại.",
  SEMESTER_WEIGHTS_LOCKED:
    "Học kỳ đã có cột/bảng điểm khóa; không thể sửa hoặc xóa hệ số.",
  SERIALIZABLE_REQUIRED: "Thao tác cần chạy lại; vui lòng thử lại.",
  STUDENT_ALREADY_REMOVED: "Hồ sơ học sinh này đã được xóa.",
  STUDENT_REMOVED_READONLY: "Hồ sơ học sinh đã xóa, không sửa được nữa.",
  SUBJECT_MODE_IN_USE: "Môn đã có bảng điểm; không thể đổi hình thức đánh giá.",
  TEMPLATE_DELETE_FORBIDDEN:
    "Không được xóa mẫu bảng điểm; hãy ngừng dùng mẫu.",
  TEMPLATE_INACTIVE: "Mẫu bảng điểm chưa được kích hoạt hoặc đã ngừng dùng.",
  TEMPLATE_IN_USE:
    "Mẫu đã được dùng để nhận dạng nên không sửa được; hãy tạo phiên bản mới.",
  TEMPLATE_NOT_FOUND: "Không tìm thấy mẫu bảng điểm.",
  TERM_ALREADY_PUBLISHED:
    "Học kỳ đã công bố; không được thay đổi hoặc tính lại kết quả.",
  TERM_OUTSIDE_YEAR: "Học kỳ phải nằm trong thời gian của năm học.",
  TERM_RESULTS_INCOMPLETE:
    "Học kỳ còn bảng chưa khóa hoặc học sinh chưa có tổng kết; xem danh sách cần xử lý.",
  TICKET_ALREADY_APPROVED: "Phiếu đã duyệt, không thể hủy.",
  TICKET_BATCH_MISMATCH: "Phiếu không thuộc lô nhận dạng đã chọn.",
  TICKET_NOT_FOUND: "Không tìm thấy phiếu nhận dạng.",
  TICKET_NOT_PROCESSING: "Phiếu không còn ở trạng thái đang xử lý.",
  TICKET_VERSION_OR_STATE_CONFLICT:
    "Phiếu vừa được xử lý hoặc thay đổi; tải lại phiếu rồi thử lại.",
  TIMETABLE_ASSIGNMENT_REQUIRED:
    "Tiết học phải có phân công giảng dạy tương ứng (lớp, môn, học kỳ, giáo viên).",
  TIMETABLE_YEAR_MISMATCH:
    "Lớp và học kỳ của tiết học thuộc hai năm học khác nhau.",
  UNKNOWN_CLASSIFICATION: "Mã xếp loại không có trong danh mục.",
  VERSION_CONFLICT: "Phiếu vừa thay đổi, tải lại rồi thử lại.",
  VERSION_OR_STATE_CONFLICT:
    "Bảng điểm vừa thay đổi hoặc đã khóa; tải lại để xem trạng thái mới nhất.",
  YEAR_RANGE_EXCLUDES_TERM:
    "Khoảng thời gian năm học không bao trùm các học kỳ hiện có.",
};

export function databaseMessage(diagnostic: string): string | null {
  for (const match of diagnostic.matchAll(/[A-Z][A-Z0-9_]{2,}/g)) {
    const message = DB_MESSAGES[match[0]];
    if (message) return message;
  }
  return null;
}
