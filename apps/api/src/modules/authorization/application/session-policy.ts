const DAY_MS = 24 * 3600 * 1000;

export const WEB_SESSION_MS = 3 * DAY_MS;
export const NATIVE_SESSION_MS = 7 * DAY_MS;
// Không đăng xuất vì không thao tác trước khi phiên hết hạn; các hàm SQL dùng cùng mốc 7 ngày.
export const SESSION_IDLE_MS = NATIVE_SESSION_MS;
