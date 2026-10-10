import { useState, useRef, type ReactNode } from "react";

// ── Icons ─────────────────────────────────────────────────────────────────────
type IconName =
  | "grid"
  | "book"
  | "score"
  | "scan"
  | "check"
  | "chart"
  | "users"
  | "search"
  | "bell"
  | "chevron"
  | "more"
  | "arrow"
  | "calendar"
  | "upload"
  | "plus"
  | "edit"
  | "eye"
  | "trash"
  | "x"
  | "download"
  | "filter"
  | "file"
  | "refresh"
  | "checkCircle"
  | "alertTriangle"
  | "info"
  | "user"
  | "settings"
  | "logout"
  | "layers"
  | "clipboard"
  | "printer"
  | "lock"
  | "shield"
  | "image"
  | "zap"
  | "arrowLeft"
  | "arrowDown"
  | "percentage"
  | "star";

function Icon({
  name,
  size = 18,
  stroke = 1.8,
}: {
  name: IconName;
  size?: number;
  stroke?: number;
}) {
  const c = {
    width: size,
    height: size,
    viewBox: "0 0 24 24",
    fill: "none",
    stroke: "currentColor",
    strokeWidth: stroke,
    strokeLinecap: "round" as const,
    strokeLinejoin: "round" as const,
  };
  const p: Record<IconName, ReactNode> = {
    grid: (
      <>
        <rect x="3" y="3" width="7" height="7" rx="1" />
        <rect x="14" y="3" width="7" height="7" rx="1" />
        <rect x="3" y="14" width="7" height="7" rx="1" />
        <rect x="14" y="14" width="7" height="7" rx="1" />
      </>
    ),
    book: (
      <>
        <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20" />
        <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2Z" />
      </>
    ),
    score: (
      <>
        <path d="M5 3v18" />
        <path d="M19 3v18" />
        <path d="M5 8h14" />
        <path d="M5 16h14" />
        <path d="M9 3v18" />
        <path d="M15 3v18" />
      </>
    ),
    scan: (
      <>
        <path d="M4 7V5a1 1 0 0 1 1-1h2" />
        <path d="M17 4h2a1 1 0 0 1 1 1v2" />
        <path d="M20 17v2a1 1 0 0 1-1 1h-2" />
        <path d="M7 20H5a1 1 0 0 1-1-1v-2" />
        <path d="M7 12h10" />
        <path d="M12 7v10" />
      </>
    ),
    check: <path d="M20 6 9 17l-5-5" />,
    chart: (
      <>
        <path d="M4 19V5" />
        <path d="M4 19h16" />
        <path d="m7 15 4-4 3 2 5-6" />
      </>
    ),
    users: (
      <>
        <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" />
        <circle cx="9" cy="7" r="4" />
        <path d="M22 21v-2a4 4 0 0 0-3-3.87" />
        <path d="M16 3.13a4 4 0 0 1 0 7.75" />
      </>
    ),
    search: (
      <>
        <circle cx="11" cy="11" r="6.5" />
        <path d="m16 16 4.3 4.3" />
      </>
    ),
    bell: (
      <>
        <path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9" />
        <path d="M10 21h4" />
      </>
    ),
    chevron: <path d="m8 10 4 4 4-4" />,
    more: (
      <>
        <circle cx="5" cy="12" r="1" fill="currentColor" />
        <circle cx="12" cy="12" r="1" fill="currentColor" />
        <circle cx="19" cy="12" r="1" fill="currentColor" />
      </>
    ),
    arrow: (
      <>
        <path d="M5 12h14" />
        <path d="m13 6 6 6-6 6" />
      </>
    ),
    calendar: (
      <>
        <rect x="3" y="5" width="18" height="16" rx="2" />
        <path d="M16 3v4M8 3v4M3 10h18" />
      </>
    ),
    upload: (
      <>
        <path d="M12 16V4" />
        <path d="m7 9 5-5 5 5" />
        <path d="M20 16v3a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1v-3" />
      </>
    ),
    plus: (
      <>
        <path d="M12 5v14" />
        <path d="M5 12h14" />
      </>
    ),
    edit: (
      <>
        <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" />
        <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" />
      </>
    ),
    eye: (
      <>
        <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" />
        <circle cx="12" cy="12" r="3" />
      </>
    ),
    trash: (
      <>
        <polyline points="3 6 5 6 21 6" />
        <path d="M19 6l-1 14H6L5 6" />
        <path d="M10 11v6M14 11v6" />
        <path d="M9 6V4h6v2" />
      </>
    ),
    x: (
      <>
        <path d="M18 6 6 18" />
        <path d="m6 6 12 12" />
      </>
    ),
    download: (
      <>
        <path d="M12 3v13" />
        <path d="m7 11 5 5 5-5" />
        <path d="M20 21H4" />
      </>
    ),
    filter: (
      <>
        <polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3" />
      </>
    ),
    file: (
      <>
        <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
        <polyline points="14 2 14 8 20 8" />
      </>
    ),
    refresh: (
      <>
        <path d="M3 12a9 9 0 0 1 15-6.7L21 8" />
        <path d="M21 3v5h-5" />
        <path d="M21 12a9 9 0 0 1-15 6.7L3 16" />
        <path d="M3 21v-5h5" />
      </>
    ),
    checkCircle: (
      <>
        <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
        <polyline points="22 4 12 14.01 9 11.01" />
      </>
    ),
    alertTriangle: (
      <>
        <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" />
        <line x1="12" y1="9" x2="12" y2="13" />
        <line x1="12" y1="17" x2="12.01" y2="17" />
      </>
    ),
    info: (
      <>
        <circle cx="12" cy="12" r="10" />
        <line x1="12" y1="16" x2="12" y2="12" />
        <line x1="12" y1="8" x2="12.01" y2="8" />
      </>
    ),
    user: (
      <>
        <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
        <circle cx="12" cy="7" r="4" />
      </>
    ),
    settings: (
      <>
        <circle cx="12" cy="12" r="3" />
        <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z" />
      </>
    ),
    logout: (
      <>
        <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
        <polyline points="16 17 21 12 16 7" />
        <line x1="21" y1="12" x2="9" y2="12" />
      </>
    ),
    layers: (
      <>
        <polygon points="12 2 2 7 12 12 22 7 12 2" />
        <polyline points="2 17 12 22 22 17" />
        <polyline points="2 12 12 17 22 12" />
      </>
    ),
    clipboard: (
      <>
        <path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2" />
        <rect x="8" y="2" width="8" height="4" rx="1" ry="1" />
      </>
    ),
    printer: (
      <>
        <polyline points="6 9 6 2 18 2 18 9" />
        <path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2" />
        <rect x="6" y="14" width="12" height="8" />
      </>
    ),
    lock: (
      <>
        <rect x="3" y="11" width="18" height="11" rx="2" ry="2" />
        <path d="M7 11V7a5 5 0 0 1 10 0v4" />
      </>
    ),
    shield: (
      <>
        <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
      </>
    ),
    image: (
      <>
        <rect x="3" y="3" width="18" height="18" rx="2" ry="2" />
        <circle cx="8.5" cy="8.5" r="1.5" />
        <polyline points="21 15 16 10 5 21" />
      </>
    ),
    zap: (
      <>
        <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2" />
      </>
    ),
    arrowLeft: (
      <>
        <path d="M19 12H5" />
        <path d="m11 18-6-6 6-6" />
      </>
    ),
    arrowDown: (
      <>
        <path d="M12 5v14" />
        <path d="m7 14 5 5 5-5" />
      </>
    ),
    percentage: (
      <>
        <line x1="19" y1="5" x2="5" y2="19" />
        <circle cx="6.5" cy="6.5" r="2.5" />
        <circle cx="17.5" cy="17.5" r="2.5" />
      </>
    ),
    star: (
      <>
        <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
      </>
    ),
  };
  return <svg {...c}>{p[name]}</svg>;
}

// ── Shared badge/pill ─────────────────────────────────────────────────────────
function StatusBadge({ status }: { status: string }) {
  const map: Record<string, string> = {
    "Đang nhập": "bg-[#f5e8c9] text-[#9a7222]",
    "Chờ duyệt": "bg-[#dbe7f1] text-[#3c6685]",
    "Đã chốt": "bg-[#dcebdd] text-[#347151]",
    "Đã hủy": "bg-[#fbe4dc] text-[#9b4430]",
    Xanh: "bg-[#d5ede5] text-[#256848]",
    Vàng: "bg-[#f5e8c9] text-[#9a7222]",
    Đỏ: "bg-[#fbe4dc] text-[#9b4430]",
    "Hoạt động": "bg-[#dcebdd] text-[#347151]",
    Khóa: "bg-[#e8e6df] text-[#6b6760]",
    "Quản trị": "bg-[#e4dff5] text-[#4a3b8c]",
    "Giáo viên": "bg-[#dbe7f1] text-[#3c6685]",
    "Học sinh": "bg-[#d5ede5] text-[#256848]",
    Đạt: "bg-[#dcebdd] text-[#347151]",
    Giỏi: "bg-[#d4f0e4] text-[#1e6645]",
    Khá: "bg-[#dbe7f1] text-[#3c6685]",
    "Chưa đạt": "bg-[#fbe4dc] text-[#9b4430]",
  };
  return (
    <span
      className={`inline-block rounded-full px-2.5 py-0.5 text-[10px] font-bold ${map[status] ?? "bg-[#e8e6df] text-[#6b6760]"}`}
    >
      {status}
    </span>
  );
}

// ── Page shell ────────────────────────────────────────────────────────────────
function PageHeader({
  title,
  subtitle,
  action,
}: {
  title: string;
  subtitle?: string;
  action?: ReactNode;
}) {
  return (
    <div className="flex items-end justify-between mb-7">
      <div>
        <h1 className="font-serif text-[34px] leading-none tracking-tight text-[#173f43]">
          {title}
        </h1>
        {subtitle && (
          <p className="mt-2.5 text-sm text-[#697472]">{subtitle}</p>
        )}
      </div>
      {action}
    </div>
  );
}

function Card({
  children,
  className = "",
  onClick,
}: {
  children: ReactNode;
  className?: string;
  onClick?: () => void;
}) {
  return (
    <div
      className={`rounded-xl border border-[#d8d4ca] bg-[#f7f6f1] ${className}`}
      onClick={onClick}
    >
      {children}
    </div>
  );
}

function SectionLabel({ children }: { children: ReactNode }) {
  return (
    <p className="text-[10px] font-bold tracking-[.16em] text-[#9c9587]">
      {children}
    </p>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 1: TỔNG QUAN (Dashboard)
// ─────────────────────────────────────────────────────────────────────────────
const gradesheets = [
  ["10A1", "Toán", "Nguyễn Hoàng Phúc", "32/36", "Đang nhập", "amber"],
  ["11A3", "Ngữ văn", "Trần Minh Anh", "40/40", "Chờ duyệt", "blue"],
  ["12A2", "Vật lý", "Lê Quốc Bảo", "38/38", "Đã chốt", "green"],
  ["10A4", "Tiếng Anh", "Phạm Thu Hà", "34/38", "Đang nhập", "amber"],
  ["11B2", "Hóa học", "Đinh Văn Thắng", "36/36", "Đã chốt", "green"],
];

function DashboardScreen() {
  return (
    <div className="px-9 py-8">
      <div className="flex items-end justify-between mb-8">
        <div>
          <p className="text-[11px] font-bold tracking-[.18em] text-[#ad8840]">
            12 THÁNG 11, 2024
          </p>
          <h1 className="mt-2 font-serif text-[37px] leading-none tracking-tight text-[#173f43]">
            Một buổi sáng nhiều tín hiệu tốt.
          </h1>
          <p className="mt-3 text-sm text-[#697472]">
            Tổng quan tiến độ nhập và duyệt điểm — THPT Nguyễn Du, Học kỳ I
            2024–2025.
          </p>
        </div>
        <button className="flex items-center gap-2 rounded-lg bg-[#173f43] px-4 py-3 text-xs font-bold text-[#f8f6ef] shadow-[0_5px_12px_rgba(22,59,63,.18)] hover:bg-[#24555a] transition">
          <Icon name="upload" size={16} /> Nhập điểm từ ảnh
        </button>
      </div>

      <div className="grid grid-cols-4 gap-4 mb-7">
        {[
          ["96%", "Bảng điểm đã tạo", "126 trên 131 bảng", "#dfe8e2"],
          ["82%", "Đã chốt điểm", "108 bảng hoàn tất", "#f2e8cb"],
          ["12", "Phiếu cần đối chiếu", "7 vàng · 5 đỏ", "#f2ded5"],
          ["1.248", "Học sinh đang theo dõi", "Khối 10 — 12", "#e1e4ec"],
        ].map(([value, label, hint, color]) => (
          <Card
            key={label}
            className="p-4 shadow-[0_2px_0_rgba(255,255,255,.9)_inset]"
          >
            <div className="flex items-start justify-between">
              <p className="font-serif text-[29px] leading-none text-[#173f43]">
                {value}
              </p>
              <span
                className="h-2.5 w-2.5 rounded-full mt-1"
                style={{ backgroundColor: color }}
              />
            </div>
            <p className="mt-4 text-xs font-bold text-[#3e5656]">{label}</p>
            <p className="mt-1 text-[11px] text-[#86847b]">{hint}</p>
          </Card>
        ))}
      </div>

      <div className="grid grid-cols-[minmax(0,1fr)_344px] gap-6 mb-7">
        <Card className="p-5">
          <div className="flex items-center justify-between mb-5">
            <div>
              <SectionLabel>BẢNG ĐIỂM GẦN ĐÂY</SectionLabel>
              <h2 className="mt-1 font-serif text-[22px] text-[#1b4143]">
                Tiến độ nhập điểm
              </h2>
            </div>
            <button className="flex items-center gap-1 text-xs font-bold text-[#196660]">
              Xem tất cả <Icon name="arrow" size={14} />
            </button>
          </div>
          <div className="overflow-hidden rounded-lg border border-[#e1ddd4]">
            <table className="w-full text-left text-xs">
              <thead className="bg-[#ece9e1] text-[10px] tracking-[.1em] text-[#817c71]">
                <tr>
                  <th className="px-4 py-3 font-bold">LỚP</th>
                  <th className="px-3 py-3 font-bold">MÔN</th>
                  <th className="px-3 py-3 font-bold">GIÁO VIÊN</th>
                  <th className="px-3 py-3 font-bold">TIẾN ĐỘ</th>
                  <th className="px-3 py-3 font-bold">TRẠNG THÁI</th>
                  <th />
                </tr>
              </thead>
              <tbody className="divide-y divide-[#e5e0d7]">
                {gradesheets.map(
                  ([cls, subject, teacher, progress, status, color]) => (
                    <tr
                      key={cls + subject}
                      className="text-[#52615e] hover:bg-[#fbfaf7]"
                    >
                      <td className="px-4 py-3.5 font-bold text-[#244749]">
                        {cls}
                      </td>
                      <td className="px-3 py-3.5">{subject}</td>
                      <td className="px-3 py-3.5">{teacher}</td>
                      <td className="px-3 py-3.5">
                        <div className="flex items-center gap-2">
                          <div className="h-1.5 w-14 overflow-hidden rounded-full bg-[#dedbd2]">
                            <div
                              className={`h-full rounded-full ${color === "green" ? "w-full bg-[#4a8a68]" : color === "blue" ? "w-full bg-[#527b99]" : "w-[82%] bg-[#c69c3c]"}`}
                            />
                          </div>
                          {progress}
                        </div>
                      </td>
                      <td className="px-3 py-3.5">
                        <StatusBadge status={status} />
                      </td>
                      <td className="px-2 py-3.5 text-[#8d8b82]">
                        <Icon name="more" size={17} />
                      </td>
                    </tr>
                  ),
                )}
              </tbody>
            </table>
          </div>
        </Card>

        <div className="overflow-hidden rounded-xl bg-[#173f43] text-[#f7f4ea] shadow-[0_6px_16px_rgba(23,63,67,.16)]">
          <div className="border-b border-white/10 p-5">
            <div className="flex items-start justify-between">
              <div>
                <SectionLabel>
                  <span className="text-[#c9b47a]">NHẬN DẠNG TỪ ẢNH</span>
                </SectionLabel>
                <h2 className="mt-1 font-serif text-[22px]">
                  Hàng chờ đối chiếu
                </h2>
              </div>
              <span className="grid h-9 w-9 place-items-center rounded-lg bg-white/10 text-[#e6ca74]">
                <Icon name="scan" />
              </span>
            </div>
            <p className="mt-3 text-xs leading-5 text-[#bdd0cd]">
              12 phiếu đã được máy đọc, cần xác nhận trước khi ghi vào sổ điểm.
            </p>
          </div>
          <div className="p-5">
            <div className="flex h-[92px] items-end gap-1.5 border-b border-white/10 pb-4">
              {[
                28, 50, 39, 74, 88, 53, 69, 100, 62, 80, 46, 91, 67, 40, 73, 55,
              ].map((h, i) => (
                <div
                  key={i}
                  className={`flex-1 rounded-t-sm ${i === 7 || i === 11 ? "bg-[#e7c864]" : i === 4 || i === 9 ? "bg-[#c87858]" : "bg-[#78aaa0]"}`}
                  style={{ height: `${h}%` }}
                />
              ))}
            </div>
            <div className="mt-4 flex gap-4 text-[10px] text-[#c7d1ce]">
              <span>
                <i className="mr-1 inline-block h-2 w-2 rounded-full bg-[#78aaa0]" />
                Xanh 74%
              </span>
              <span>
                <i className="mr-1 inline-block h-2 w-2 rounded-full bg-[#e7c864]" />
                Vàng 18%
              </span>
              <span>
                <i className="mr-1 inline-block h-2 w-2 rounded-full bg-[#c87858]" />
                Đỏ 8%
              </span>
            </div>
            <button className="mt-5 flex w-full items-center justify-center gap-2 rounded-lg bg-[#e7c864] px-4 py-3 text-xs font-bold text-[#1b4143] hover:bg-[#f0d77e]">
              Mở hàng chờ <Icon name="arrow" size={15} />
            </button>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-[1.1fr_.9fr] gap-6">
        <Card className="p-5">
          <div className="flex items-center justify-between mb-5">
            <div>
              <SectionLabel>PHÂN BỐ KẾT QUẢ</SectionLabel>
              <h2 className="mt-1 font-serif text-[22px] text-[#1b4143]">
                Mức điểm toàn trường
              </h2>
            </div>
            <button className="rounded-md border border-[#d8d4ca] px-2.5 py-1.5 text-[11px] text-[#586b68] flex items-center gap-1">
              HK I <Icon name="chevron" size={12} />
            </button>
          </div>
          <div className="flex items-end gap-4">
            {[
              ["Giỏi", 38, "#276e68"],
              ["Khá", 42, "#78a79d"],
              ["Đạt", 16, "#d3ae54"],
              ["Chưa đạt", 4, "#c87858"],
            ].map(([name, value, color]) => (
              <div
                key={name as string}
                className="flex flex-1 flex-col items-center gap-2"
              >
                <div className="flex h-28 w-full items-end rounded-t bg-[#e5e4dd]">
                  <div
                    className="w-full rounded-t"
                    style={{
                      height: `${Number(value) * 2.3}%`,
                      backgroundColor: color as string,
                    }}
                  />
                </div>
                <span className="text-[11px] font-bold text-[#375452]">
                  {value}%
                </span>
                <span className="text-[10px] text-[#858177]">{name}</span>
              </div>
            ))}
          </div>
        </Card>
        <Card className="p-5">
          <SectionLabel>NHẬT KÝ HÔM NAY</SectionLabel>
          <h2 className="mt-1 font-serif text-[22px] text-[#1b4143]">
            Hoạt động gần đây
          </h2>
          <div className="mt-4 space-y-3">
            {[
              ["09:42", "Cô Thu Hà đã nhập điểm Tiếng Anh 10A4"],
              ["09:16", "Thầy Quốc Bảo đã chốt bảng điểm Vật lý 12A2"],
              ["08:35", "Hệ thống nhận 4 ảnh phiếu điểm mới"],
              ["08:12", "Admin đã mở khóa bảng điểm Hóa 11B2"],
              ["07:58", "Thầy Minh Anh hoàn tất Ngữ văn 11A3"],
            ].map(([time, text]) => (
              <div key={time} className="flex gap-3">
                <span className="mt-1 h-2 w-2 shrink-0 rounded-full bg-[#c69c3c]" />
                <p className="text-[11px] leading-5 text-[#5c6965]">
                  <b className="mr-2 text-[#9a9386]">{time}</b>
                  {text}
                </p>
              </div>
            ))}
          </div>
        </Card>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 2: DANH MỤC HỌC TẬP
// ─────────────────────────────────────────────────────────────────────────────
const catalogTabs = [
  "Năm học",
  "Học kỳ",
  "Lớp học",
  "Học sinh",
  "Giáo viên",
  "Môn học",
];

const students = [
  {
    id: "HS001",
    name: "Nguyễn Thị Lan Anh",
    cls: "10A1",
    dob: "12/03/2009",
    gender: "Nữ",
    gpa: "8.5",
    rank: "Giỏi",
  },
  {
    id: "HS002",
    name: "Trần Hoàng Minh",
    cls: "10A1",
    dob: "05/07/2009",
    gender: "Nam",
    gpa: "7.2",
    rank: "Khá",
  },
  {
    id: "HS003",
    name: "Lê Bảo Châu",
    cls: "11A3",
    dob: "22/11/2008",
    gender: "Nữ",
    gpa: "9.1",
    rank: "Giỏi",
  },
  {
    id: "HS004",
    name: "Phạm Gia Huy",
    cls: "11A3",
    dob: "14/02/2008",
    gender: "Nam",
    gpa: "6.8",
    rank: "Đạt",
  },
  {
    id: "HS005",
    name: "Đinh Thu Trang",
    cls: "12A2",
    dob: "30/09/2007",
    gender: "Nữ",
    gpa: "8.9",
    rank: "Giỏi",
  },
  {
    id: "HS006",
    name: "Vũ Đức Thành",
    cls: "12A2",
    dob: "18/06/2007",
    gender: "Nam",
    gpa: "5.4",
    rank: "Đạt",
  },
  {
    id: "HS007",
    name: "Hoàng Ngọc Linh",
    cls: "10A4",
    dob: "03/01/2009",
    gender: "Nữ",
    gpa: "7.8",
    rank: "Khá",
  },
  {
    id: "HS008",
    name: "Đặng Quang Vinh",
    cls: "11B2",
    dob: "25/04/2008",
    gender: "Nam",
    gpa: "4.9",
    rank: "Chưa đạt",
  },
];

const teachers = [
  {
    id: "GV001",
    name: "Nguyễn Hoàng Phúc",
    subject: "Toán học",
    classes: "10A1, 10A2, 10A3",
    sheets: 12,
    status: "Hoạt động",
  },
  {
    id: "GV002",
    name: "Trần Minh Anh",
    subject: "Ngữ văn",
    classes: "11A3, 11A4",
    sheets: 8,
    status: "Hoạt động",
  },
  {
    id: "GV003",
    name: "Lê Quốc Bảo",
    subject: "Vật lý",
    classes: "12A1, 12A2",
    sheets: 8,
    status: "Hoạt động",
  },
  {
    id: "GV004",
    name: "Phạm Thu Hà",
    subject: "Tiếng Anh",
    classes: "10A4, 11B1",
    sheets: 10,
    status: "Hoạt động",
  },
  {
    id: "GV005",
    name: "Đinh Văn Thắng",
    subject: "Hóa học",
    classes: "11B2, 12B1",
    sheets: 8,
    status: "Khóa",
  },
];

const classes_catalog = [
  {
    id: "L001",
    name: "10A1",
    grade: "Khối 10",
    teacher: "Nguyễn Hoàng Phúc",
    students: 36,
    year: "2024–2025",
  },
  {
    id: "L002",
    name: "10A4",
    grade: "Khối 10",
    teacher: "Phạm Thu Hà",
    students: 38,
    year: "2024–2025",
  },
  {
    id: "L003",
    name: "11A3",
    grade: "Khối 11",
    teacher: "Trần Minh Anh",
    students: 40,
    year: "2024–2025",
  },
  {
    id: "L004",
    name: "11B2",
    grade: "Khối 11",
    teacher: "Đinh Văn Thắng",
    students: 36,
    year: "2024–2025",
  },
  {
    id: "L005",
    name: "12A2",
    grade: "Khối 12",
    teacher: "Lê Quốc Bảo",
    students: 38,
    year: "2024–2025",
  },
];

const subjects = [
  {
    id: "MH001",
    name: "Toán học",
    code: "TOAN",
    group: "Khoa học tự nhiên",
    periods: 4,
    required: true,
  },
  {
    id: "MH002",
    name: "Ngữ văn",
    code: "NVA",
    group: "Khoa học xã hội",
    periods: 3,
    required: true,
  },
  {
    id: "MH003",
    name: "Vật lý",
    code: "VLY",
    group: "Khoa học tự nhiên",
    periods: 2,
    required: false,
  },
  {
    id: "MH004",
    name: "Hóa học",
    code: "HOA",
    group: "Khoa học tự nhiên",
    periods: 2,
    required: false,
  },
  {
    id: "MH005",
    name: "Tiếng Anh",
    code: "ANH",
    group: "Ngoại ngữ",
    periods: 3,
    required: true,
  },
  {
    id: "MH006",
    name: "Sinh học",
    code: "SINH",
    group: "Khoa học tự nhiên",
    periods: 2,
    required: false,
  },
  {
    id: "MH007",
    name: "Lịch sử",
    code: "LS",
    group: "Khoa học xã hội",
    periods: 2,
    required: false,
  },
  {
    id: "MH008",
    name: "Địa lý",
    code: "DL",
    group: "Khoa học xã hội",
    periods: 2,
    required: false,
  },
];

function CatalogScreen() {
  const [tab, setTab] = useState("Lớp học");
  const [search, setSearch] = useState("");

  return (
    <div className="px-9 py-8">
      <PageHeader
        title="Danh mục học tập"
        subtitle="Quản lý năm học, học kỳ, lớp học, học sinh, giáo viên và môn học."
        action={
          <button className="flex items-center gap-2 rounded-lg bg-[#173f43] px-4 py-2.5 text-xs font-bold text-[#f8f6ef] shadow-[0_4px_10px_rgba(22,59,63,.15)] hover:bg-[#24555a] transition">
            <Icon name="plus" size={15} /> Thêm mới
          </button>
        }
      />

      <div className="flex gap-1 border-b border-[#d8d4ca] mb-6">
        {catalogTabs.map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className={`px-4 py-2.5 text-xs font-bold transition border-b-2 -mb-px ${tab === t ? "border-[#173f43] text-[#173f43]" : "border-transparent text-[#7a7670] hover:text-[#3a5050]"}`}
          >
            {t}
          </button>
        ))}
      </div>

      {(tab === "Học sinh" ||
        tab === "Giáo viên" ||
        tab === "Lớp học" ||
        tab === "Môn học") && (
        <div className="flex items-center gap-3 mb-5">
          <div className="relative flex-1 max-w-sm">
            <span className="absolute left-3 top-1/2 -translate-y-1/2 text-[#9a9590]">
              <Icon name="search" size={15} />
            </span>
            <input
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder={`Tìm kiếm ${tab.toLowerCase()}...`}
              className="w-full rounded-lg border border-[#d0ccc3] bg-white py-2 pl-9 pr-3 text-xs outline-none focus:ring-2 ring-[#aac4bc]"
            />
          </div>
          <button className="flex items-center gap-1.5 rounded-lg border border-[#d0ccc3] bg-[#f7f6f1] px-3 py-2 text-xs text-[#686460] hover:bg-[#ebe9e2]">
            <Icon name="filter" size={14} /> Lọc
          </button>
          <button className="flex items-center gap-1.5 rounded-lg border border-[#d0ccc3] bg-[#f7f6f1] px-3 py-2 text-xs text-[#686460] hover:bg-[#ebe9e2]">
            <Icon name="download" size={14} /> Xuất Excel
          </button>
        </div>
      )}

      {tab === "Năm học" && (
        <div className="grid grid-cols-3 gap-4">
          {[
            {
              year: "2024–2025",
              status: "Đang diễn ra",
              start: "05/09/2024",
              end: "31/05/2025",
              semesters: 2,
              classes: 18,
            },
            {
              year: "2023–2024",
              status: "Đã kết thúc",
              start: "04/09/2023",
              end: "30/05/2024",
              semesters: 2,
              classes: 17,
            },
            {
              year: "2022–2023",
              status: "Đã kết thúc",
              start: "05/09/2022",
              end: "31/05/2023",
              semesters: 2,
              classes: 16,
            },
          ].map((y) => (
            <Card key={y.year} className="p-5">
              <div className="flex items-start justify-between">
                <div>
                  <p className="font-serif text-[22px] text-[#173f43]">
                    {y.year}
                  </p>
                  <StatusBadge
                    status={y.status === "Đang diễn ra" ? "Hoạt động" : "Khóa"}
                  />
                </div>
                <span className="text-[#a0a49e]">
                  <Icon name="calendar" size={20} />
                </span>
              </div>
              <div className="mt-4 space-y-2 text-[11px] text-[#62706c]">
                <div className="flex justify-between">
                  <span>Bắt đầu</span>
                  <span className="font-semibold">{y.start}</span>
                </div>
                <div className="flex justify-between">
                  <span>Kết thúc</span>
                  <span className="font-semibold">{y.end}</span>
                </div>
                <div className="flex justify-between">
                  <span>Học kỳ</span>
                  <span className="font-semibold">{y.semesters}</span>
                </div>
                <div className="flex justify-between">
                  <span>Lớp học</span>
                  <span className="font-semibold">{y.classes} lớp</span>
                </div>
              </div>
              <div className="mt-4 flex gap-2">
                <button className="flex-1 rounded-md border border-[#d0ccc3] py-1.5 text-[11px] font-semibold text-[#445350] hover:bg-[#ebe9e2]">
                  Xem chi tiết
                </button>
                {y.status === "Đang diễn ra" && (
                  <button className="flex-1 rounded-md bg-[#173f43] py-1.5 text-[11px] font-semibold text-white hover:bg-[#24555a]">
                    Quản lý
                  </button>
                )}
              </div>
            </Card>
          ))}
        </div>
      )}

      {tab === "Học kỳ" && (
        <Card>
          <table className="w-full text-left text-xs">
            <thead className="bg-[#ece9e1] text-[10px] tracking-[.1em] text-[#817c71]">
              <tr>
                <th className="px-5 py-3 font-bold">HỌC KỲ</th>
                <th className="px-4 py-3 font-bold">NĂM HỌC</th>
                <th className="px-4 py-3 font-bold">BẮT ĐẦU</th>
                <th className="px-4 py-3 font-bold">KẾT THÚC</th>
                <th className="px-4 py-3 font-bold">SỐ TUẦN</th>
                <th className="px-4 py-3 font-bold">TRẠNG THÁI</th>
                <th />
              </tr>
            </thead>
            <tbody className="divide-y divide-[#e5e0d7]">
              {[
                [
                  "Học kỳ I",
                  "2024–2025",
                  "02/09/2024",
                  "20/01/2025",
                  19,
                  "Đang diễn ra",
                ],
                [
                  "Học kỳ II",
                  "2024–2025",
                  "03/02/2025",
                  "30/05/2025",
                  17,
                  "Chưa bắt đầu",
                ],
                [
                  "Học kỳ I",
                  "2023–2024",
                  "04/09/2023",
                  "19/01/2024",
                  19,
                  "Đã kết thúc",
                ],
                [
                  "Học kỳ II",
                  "2023–2024",
                  "05/02/2024",
                  "31/05/2024",
                  17,
                  "Đã kết thúc",
                ],
              ].map(([sem, year, start, end, weeks, status]) => (
                <tr
                  key={`${sem}${year}`}
                  className="text-[#52615e] hover:bg-[#fbfaf7]"
                >
                  <td className="px-5 py-3.5 font-semibold text-[#244749]">
                    {sem}
                  </td>
                  <td className="px-4 py-3.5">{year}</td>
                  <td className="px-4 py-3.5">{start}</td>
                  <td className="px-4 py-3.5">{end}</td>
                  <td className="px-4 py-3.5">{weeks}</td>
                  <td className="px-4 py-3.5">
                    <StatusBadge
                      status={
                        status === "Đang diễn ra"
                          ? "Hoạt động"
                          : status === "Chưa bắt đầu"
                            ? "Chờ duyệt"
                            : "Khóa"
                      }
                    />
                  </td>
                  <td className="px-3 py-3.5 text-[#8d8b82]">
                    <Icon name="more" size={16} />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </Card>
      )}

      {tab === "Lớp học" && (
        <Card>
          <table className="w-full text-left text-xs">
            <thead className="bg-[#ece9e1] text-[10px] tracking-[.1em] text-[#817c71]">
              <tr>
                <th className="px-5 py-3 font-bold">TÊN LỚP</th>
                <th className="px-4 py-3 font-bold">KHỐI</th>
                <th className="px-4 py-3 font-bold">GVCN</th>
                <th className="px-4 py-3 font-bold">SĨ SỐ</th>
                <th className="px-4 py-3 font-bold">NĂM HỌC</th>
                <th className="px-4 py-3 font-bold">THAO TÁC</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#e5e0d7]">
              {classes_catalog
                .filter(
                  (c) =>
                    !search ||
                    c.name.toLowerCase().includes(search.toLowerCase()) ||
                    c.teacher.toLowerCase().includes(search.toLowerCase()),
                )
                .map((c) => (
                  <tr key={c.id} className="text-[#52615e] hover:bg-[#fbfaf7]">
                    <td className="px-5 py-3.5 font-bold text-[#244749]">
                      {c.name}
                    </td>
                    <td className="px-4 py-3.5">{c.grade}</td>
                    <td className="px-4 py-3.5">{c.teacher}</td>
                    <td className="px-4 py-3.5">{c.students} học sinh</td>
                    <td className="px-4 py-3.5">{c.year}</td>
                    <td className="px-4 py-3.5">
                      <div className="flex gap-2">
                        <button className="text-[#62716e] hover:text-[#173f43]">
                          <Icon name="eye" size={15} />
                        </button>
                        <button className="text-[#62716e] hover:text-[#173f43]">
                          <Icon name="edit" size={15} />
                        </button>
                        <button className="text-[#62716e] hover:text-[#b34040]">
                          <Icon name="trash" size={15} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
            </tbody>
          </table>
        </Card>
      )}

      {tab === "Học sinh" && (
        <Card>
          <table className="w-full text-left text-xs">
            <thead className="bg-[#ece9e1] text-[10px] tracking-[.1em] text-[#817c71]">
              <tr>
                <th className="px-5 py-3 font-bold">MÃ HS</th>
                <th className="px-4 py-3 font-bold">HỌ VÀ TÊN</th>
                <th className="px-4 py-3 font-bold">LỚP</th>
                <th className="px-4 py-3 font-bold">NGÀY SINH</th>
                <th className="px-4 py-3 font-bold">GIỚI TÍNH</th>
                <th className="px-4 py-3 font-bold">ĐTB</th>
                <th className="px-4 py-3 font-bold">XẾP LOẠI</th>
                <th />
              </tr>
            </thead>
            <tbody className="divide-y divide-[#e5e0d7]">
              {students
                .filter(
                  (s) =>
                    !search ||
                    s.name.toLowerCase().includes(search.toLowerCase()) ||
                    s.id.toLowerCase().includes(search.toLowerCase()),
                )
                .map((s) => (
                  <tr key={s.id} className="text-[#52615e] hover:bg-[#fbfaf7]">
                    <td className="px-5 py-3.5 font-mono text-[11px] text-[#7a7873]">
                      {s.id}
                    </td>
                    <td className="px-4 py-3.5 font-semibold text-[#244749]">
                      {s.name}
                    </td>
                    <td className="px-4 py-3.5">{s.cls}</td>
                    <td className="px-4 py-3.5">{s.dob}</td>
                    <td className="px-4 py-3.5">{s.gender}</td>
                    <td className="px-4 py-3.5 font-bold text-[#244749]">
                      {s.gpa}
                    </td>
                    <td className="px-4 py-3.5">
                      <StatusBadge status={s.rank} />
                    </td>
                    <td className="px-3 py-3.5 text-[#8d8b82]">
                      <Icon name="more" size={16} />
                    </td>
                  </tr>
                ))}
            </tbody>
          </table>
        </Card>
      )}

      {tab === "Giáo viên" && (
        <Card>
          <table className="w-full text-left text-xs">
            <thead className="bg-[#ece9e1] text-[10px] tracking-[.1em] text-[#817c71]">
              <tr>
                <th className="px-5 py-3 font-bold">MÃ GV</th>
                <th className="px-4 py-3 font-bold">HỌ VÀ TÊN</th>
                <th className="px-4 py-3 font-bold">MÔN PHỤ TRÁCH</th>
                <th className="px-4 py-3 font-bold">CÁC LỚP</th>
                <th className="px-4 py-3 font-bold">BẢNG ĐIỂM</th>
                <th className="px-4 py-3 font-bold">TRẠNG THÁI</th>
                <th />
              </tr>
            </thead>
            <tbody className="divide-y divide-[#e5e0d7]">
              {teachers
                .filter(
                  (t) =>
                    !search ||
                    t.name.toLowerCase().includes(search.toLowerCase()),
                )
                .map((t) => (
                  <tr key={t.id} className="text-[#52615e] hover:bg-[#fbfaf7]">
                    <td className="px-5 py-3.5 font-mono text-[11px] text-[#7a7873]">
                      {t.id}
                    </td>
                    <td className="px-4 py-3.5 font-semibold text-[#244749]">
                      {t.name}
                    </td>
                    <td className="px-4 py-3.5">{t.subject}</td>
                    <td className="px-4 py-3.5 text-[#62716e]">{t.classes}</td>
                    <td className="px-4 py-3.5">{t.sheets} bảng</td>
                    <td className="px-4 py-3.5">
                      <StatusBadge status={t.status} />
                    </td>
                    <td className="px-3 py-3.5 text-[#8d8b82]">
                      <Icon name="more" size={16} />
                    </td>
                  </tr>
                ))}
            </tbody>
          </table>
        </Card>
      )}

      {tab === "Môn học" && (
        <Card>
          <table className="w-full text-left text-xs">
            <thead className="bg-[#ece9e1] text-[10px] tracking-[.1em] text-[#817c71]">
              <tr>
                <th className="px-5 py-3 font-bold">MÃ MÔN</th>
                <th className="px-4 py-3 font-bold">TÊN MÔN HỌC</th>
                <th className="px-4 py-3 font-bold">TỔ NHÓM</th>
                <th className="px-4 py-3 font-bold">SỐ TIẾT/TUẦN</th>
                <th className="px-4 py-3 font-bold">BẮT BUỘC</th>
                <th />
              </tr>
            </thead>
            <tbody className="divide-y divide-[#e5e0d7]">
              {subjects
                .filter(
                  (s) =>
                    !search ||
                    s.name.toLowerCase().includes(search.toLowerCase()),
                )
                .map((s) => (
                  <tr key={s.id} className="text-[#52615e] hover:bg-[#fbfaf7]">
                    <td className="px-5 py-3.5 font-mono text-[11px] text-[#7a7873]">
                      {s.code}
                    </td>
                    <td className="px-4 py-3.5 font-semibold text-[#244749]">
                      {s.name}
                    </td>
                    <td className="px-4 py-3.5">{s.group}</td>
                    <td className="px-4 py-3.5">{s.periods}</td>
                    <td className="px-4 py-3.5">
                      {s.required ? (
                        <StatusBadge status="Hoạt động" />
                      ) : (
                        <StatusBadge status="Khóa" />
                      )}
                    </td>
                    <td className="px-3 py-3.5 text-[#8d8b82]">
                      <Icon name="more" size={16} />
                    </td>
                  </tr>
                ))}
            </tbody>
          </table>
        </Card>
      )}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 3: QUẢN LÝ BẢNG ĐIỂM
// ─────────────────────────────────────────────────────────────────────────────
const allSheets = [
  {
    id: "BD001",
    cls: "10A1",
    subject: "Toán học",
    teacher: "Nguyễn Hoàng Phúc",
    semester: "HK I",
    year: "2024–2025",
    progress: 89,
    filled: 32,
    total: 36,
    status: "Đang nhập",
    updated: "10/11/2024",
  },
  {
    id: "BD002",
    cls: "11A3",
    subject: "Ngữ văn",
    teacher: "Trần Minh Anh",
    semester: "HK I",
    year: "2024–2025",
    progress: 100,
    filled: 40,
    total: 40,
    status: "Chờ duyệt",
    updated: "11/11/2024",
  },
  {
    id: "BD003",
    cls: "12A2",
    subject: "Vật lý",
    teacher: "Lê Quốc Bảo",
    semester: "HK I",
    year: "2024–2025",
    progress: 100,
    filled: 38,
    total: 38,
    status: "Đã chốt",
    updated: "09/11/2024",
  },
  {
    id: "BD004",
    cls: "10A4",
    subject: "Tiếng Anh",
    teacher: "Phạm Thu Hà",
    semester: "HK I",
    year: "2024–2025",
    progress: 89,
    filled: 34,
    total: 38,
    status: "Đang nhập",
    updated: "12/11/2024",
  },
  {
    id: "BD005",
    cls: "11B2",
    subject: "Hóa học",
    teacher: "Đinh Văn Thắng",
    semester: "HK I",
    year: "2024–2025",
    progress: 100,
    filled: 36,
    total: 36,
    status: "Đã chốt",
    updated: "08/11/2024",
  },
  {
    id: "BD006",
    cls: "12A1",
    subject: "Toán học",
    teacher: "Nguyễn Hoàng Phúc",
    semester: "HK I",
    year: "2024–2025",
    progress: 76,
    filled: 28,
    total: 37,
    status: "Đang nhập",
    updated: "11/11/2024",
  },
  {
    id: "BD007",
    cls: "10A2",
    subject: "Ngữ văn",
    teacher: "Trần Minh Anh",
    semester: "HK I",
    year: "2024–2025",
    progress: 100,
    filled: 35,
    total: 35,
    status: "Chờ duyệt",
    updated: "10/11/2024",
  },
  {
    id: "BD008",
    cls: "11A1",
    subject: "Sinh học",
    teacher: "Cao Thị Mỹ Linh",
    semester: "HK I",
    year: "2024–2025",
    progress: 50,
    filled: 18,
    total: 36,
    status: "Đang nhập",
    updated: "07/11/2024",
  },
];

const sheetStudents = [
  {
    rank: 1,
    name: "Nguyễn Thị Lan Anh",
    id: "HS001",
    tx1: 8.5,
    tx2: 9.0,
    gk: 8.0,
    ck: 8.5,
    avg: 8.6,
    letter: "G",
  },
  {
    rank: 2,
    name: "Lê Bảo Châu",
    id: "HS003",
    tx1: 9.5,
    tx2: 9.0,
    gk: 9.0,
    ck: 9.5,
    avg: 9.3,
    letter: "G",
  },
  {
    rank: 3,
    name: "Trần Hoàng Minh",
    id: "HS002",
    tx1: 7.0,
    tx2: 7.5,
    gk: 7.0,
    ck: 7.5,
    avg: 7.3,
    letter: "K",
  },
  {
    rank: 4,
    name: "Hoàng Ngọc Linh",
    id: "HS007",
    tx1: 7.5,
    tx2: 8.0,
    gk: 7.5,
    ck: 7.0,
    avg: 7.5,
    letter: "K",
  },
  {
    rank: 5,
    name: "Phạm Gia Huy",
    id: "HS004",
    tx1: 6.0,
    tx2: 6.5,
    gk: 7.0,
    ck: 6.5,
    avg: 6.5,
    letter: "Đ",
  },
  {
    rank: 6,
    name: "Vũ Đức Thành",
    id: "HS006",
    tx1: 5.0,
    tx2: 5.5,
    gk: 5.0,
    ck: 5.5,
    avg: 5.3,
    letter: "Đ",
  },
  {
    rank: 7,
    name: "Đinh Thu Trang",
    id: "HS005",
    tx1: 8.0,
    tx2: 8.5,
    gk: 9.0,
    ck: 8.5,
    avg: 8.6,
    letter: "G",
  },
  {
    rank: 8,
    name: "Đặng Quang Vinh",
    id: "HS008",
    tx1: 4.0,
    tx2: 4.5,
    gk: 5.0,
    ck: 4.0,
    avg: 4.4,
    letter: "CĐ",
  },
];

function GradeManagementScreen() {
  const [selectedSheet, setSelectedSheet] = useState<string | null>(null);
  const [filterStatus, setFilterStatus] = useState("Tất cả");

  const sheet = allSheets.find((s) => s.id === selectedSheet);

  if (sheet) {
    return (
      <div className="px-9 py-8">
        <button
          onClick={() => setSelectedSheet(null)}
          className="flex items-center gap-2 text-xs font-bold text-[#196660] mb-6 hover:text-[#173f43]"
        >
          <Icon name="arrowLeft" size={15} /> Quay lại danh sách
        </button>
        <div className="flex items-start justify-between mb-7">
          <div>
            <p className="text-[10px] font-bold tracking-[.16em] text-[#ad8840]">
              BẢNG ĐIỂM · {sheet.semester} {sheet.year}
            </p>
            <h1 className="mt-2 font-serif text-[32px] leading-none tracking-tight text-[#173f43]">
              {sheet.subject} — Lớp {sheet.cls}
            </h1>
            <p className="mt-2 text-sm text-[#697472]">
              Giáo viên phụ trách:{" "}
              <span className="font-semibold text-[#3a5050]">
                {sheet.teacher}
              </span>{" "}
              · Cập nhật: {sheet.updated}
            </p>
          </div>
          <div className="flex gap-2">
            <button className="flex items-center gap-1.5 rounded-lg border border-[#d0ccc3] bg-[#f7f6f1] px-3 py-2.5 text-xs font-semibold text-[#445350] hover:bg-[#ebe9e2]">
              <Icon name="printer" size={14} /> In bảng điểm
            </button>
            <button className="flex items-center gap-1.5 rounded-lg border border-[#d0ccc3] bg-[#f7f6f1] px-3 py-2.5 text-xs font-semibold text-[#445350] hover:bg-[#ebe9e2]">
              <Icon name="download" size={14} /> Xuất Excel
            </button>
            {sheet.status !== "Đã chốt" && (
              <button className="flex items-center gap-2 rounded-lg bg-[#173f43] px-4 py-2.5 text-xs font-bold text-[#f8f6ef] hover:bg-[#24555a]">
                <Icon name="check" size={14} /> Chốt bảng điểm
              </button>
            )}
          </div>
        </div>

        <div className="flex gap-4 mb-6">
          {[
            ["Tổng số học sinh", sheet.total + " em"],
            ["Đã nhập điểm", sheet.filled + " em"],
            ["Chưa nhập", sheet.total - sheet.filled + " em"],
            ["Trạng thái", sheet.status],
          ].map(([k, v]) => (
            <Card key={k} className="flex-1 px-4 py-3">
              <p className="text-[10px] font-bold tracking-[.14em] text-[#9c9587]">
                {k.toUpperCase()}
              </p>
              <p className="mt-1 font-serif text-[20px] text-[#173f43]">{v}</p>
            </Card>
          ))}
        </div>

        <Card>
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-[#ece9e1] text-[10px] tracking-[.1em] text-[#817c71]">
                <tr>
                  <th className="px-4 py-3 font-bold">STT</th>
                  <th className="px-4 py-3 font-bold">HỌ VÀ TÊN</th>
                  <th className="px-3 py-3 font-bold">MÃ HS</th>
                  <th className="px-3 py-3 font-bold text-center">
                    THƯỜNG XÉT 1
                  </th>
                  <th className="px-3 py-3 font-bold text-center">
                    THƯỜNG XÉT 2
                  </th>
                  <th className="px-3 py-3 font-bold text-center">GIỮA KỲ</th>
                  <th className="px-3 py-3 font-bold text-center">CUỐI KỲ</th>
                  <th className="px-3 py-3 font-bold text-center">ĐIỂM TB</th>
                  <th className="px-3 py-3 font-bold text-center">XẾP LOẠI</th>
                  <th />
                </tr>
              </thead>
              <tbody className="divide-y divide-[#e5e0d7]">
                {sheetStudents.map((s) => (
                  <tr key={s.id} className="hover:bg-[#fbfaf7]">
                    <td className="px-4 py-3.5 text-[#908c84]">{s.rank}</td>
                    <td className="px-4 py-3.5 font-semibold text-[#244749]">
                      {s.name}
                    </td>
                    <td className="px-3 py-3.5 font-mono text-[11px] text-[#7a7873]">
                      {s.id}
                    </td>
                    {[s.tx1, s.tx2, s.gk, s.ck].map((v, i) => (
                      <td key={i} className="px-3 py-3.5 text-center">
                        {sheet.status === "Đang nhập" ? (
                          <input
                            defaultValue={v}
                            className="w-14 rounded border border-[#d0ccc3] py-1 text-center text-xs outline-none focus:ring-1 ring-[#aac4bc] bg-white"
                          />
                        ) : (
                          <span
                            className={
                              v >= 8
                                ? "font-bold text-[#276e68]"
                                : v < 5
                                  ? "font-bold text-[#b34040]"
                                  : "text-[#52615e]"
                            }
                          >
                            {v}
                          </span>
                        )}
                      </td>
                    ))}
                    <td className="px-3 py-3.5 text-center font-bold text-[#173f43]">
                      {s.avg}
                    </td>
                    <td className="px-3 py-3.5 text-center">
                      <span
                        className={`inline-block rounded-full px-2 py-0.5 text-[10px] font-bold ${s.letter === "G" ? "bg-[#d4f0e4] text-[#1e6645]" : s.letter === "K" ? "bg-[#dbe7f1] text-[#3c6685]" : s.letter === "Đ" ? "bg-[#f5e8c9] text-[#9a7222]" : "bg-[#fbe4dc] text-[#9b4430]"}`}
                      >
                        {s.letter}
                      </span>
                    </td>
                    <td className="px-2 py-3.5 text-[#8d8b82]">
                      <Icon name="edit" size={14} />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Card>
      </div>
    );
  }

  const filtered = allSheets.filter(
    (s) => filterStatus === "Tất cả" || s.status === filterStatus,
  );

  return (
    <div className="px-9 py-8">
      <PageHeader
        title="Quản lý bảng điểm"
        subtitle="Theo dõi và quản lý toàn bộ bảng điểm của các lớp trong học kỳ."
        action={
          <button className="flex items-center gap-2 rounded-lg bg-[#173f43] px-4 py-2.5 text-xs font-bold text-[#f8f6ef] shadow-[0_4px_10px_rgba(22,59,63,.15)] hover:bg-[#24555a] transition">
            <Icon name="plus" size={15} /> Tạo bảng điểm
          </button>
        }
      />

      <div className="flex gap-2 mb-6">
        {["Tất cả", "Đang nhập", "Chờ duyệt", "Đã chốt"].map((s) => (
          <button
            key={s}
            onClick={() => setFilterStatus(s)}
            className={`rounded-full px-3.5 py-1.5 text-[11px] font-bold transition ${filterStatus === s ? "bg-[#173f43] text-white" : "border border-[#d0ccc3] text-[#62716e] hover:bg-[#ebe9e2]"}`}
          >
            {s}{" "}
            {s !== "Tất cả" && (
              <span className="ml-1 opacity-70">
                {allSheets.filter((x) => x.status === s).length}
              </span>
            )}
          </button>
        ))}
      </div>

      <div className="grid grid-cols-1 gap-3">
        {filtered.map((s) => (
          <Card
            key={s.id}
            className="p-4 hover:shadow-md transition-shadow cursor-pointer"
            onClick={() => setSelectedSheet(s.id)}
          >
            <div className="flex items-center gap-5">
              <div className="w-12 h-12 rounded-lg bg-[#173f43]/10 flex items-center justify-center shrink-0">
                <span className="font-serif text-[18px] font-bold text-[#173f43]">
                  {s.cls}
                </span>
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2">
                  <span className="font-semibold text-[#244749] text-sm">
                    {s.subject}
                  </span>
                  <span className="text-[#9a9590] text-xs">·</span>
                  <span className="text-xs text-[#62716e]">{s.teacher}</span>
                </div>
                <div className="flex items-center gap-3 mt-1.5">
                  <div className="flex items-center gap-1.5">
                    <div className="h-1.5 w-28 overflow-hidden rounded-full bg-[#dedbd2]">
                      <div
                        className="h-full rounded-full bg-[#4a8a68]"
                        style={{ width: `${s.progress}%` }}
                      />
                    </div>
                    <span className="text-[11px] text-[#7a7873]">
                      {s.filled}/{s.total}
                    </span>
                  </div>
                  <span className="text-[#c5c0b9]">·</span>
                  <span className="text-[11px] text-[#7a7873]">
                    {s.semester} {s.year}
                  </span>
                  <span className="text-[#c5c0b9]">·</span>
                  <span className="text-[11px] text-[#7a7873]">
                    Cập nhật {s.updated}
                  </span>
                </div>
              </div>
              <StatusBadge status={s.status} />
              <Icon name="arrow" size={16} />
            </div>
          </Card>
        ))}
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 4: NHẬP ĐIỂM TỪ ẢNH (OCR — tích hợp vào luồng nhập điểm)
// ─────────────────────────────────────────────────────────────────────────────
const confidenceColor = {
  Xanh: {
    bg: "bg-[#d5ede5]",
    text: "text-[#256848]",
    bar: "bg-[#4a9e6a]",
    border: "border-[#9dd4bb]",
  },
  Vàng: {
    bg: "bg-[#f5e8c9]",
    text: "text-[#9a7222]",
    bar: "bg-[#c69c3c]",
    border: "border-[#e8c96d]",
  },
  Đỏ: {
    bg: "bg-[#fbe4dc]",
    text: "text-[#9b4430]",
    bar: "bg-[#c87858]",
    border: "border-[#e8a992]",
  },
} as Record<string, { bg: string; text: string; bar: string; border: string }>;

// OCR result per student, with per-cell confidence
type OcrCell = { ocr: number | null; conf: "Xanh" | "Vàng" | "Đỏ" };
type OcrRow = {
  id: string;
  name: string;
  tx1: OcrCell;
  tx2: OcrCell;
  gk: OcrCell;
  ck: OcrCell;
};

const ocrRawRows: OcrRow[] = [
  {
    id: "HS001",
    name: "Nguyễn Thị Lan Anh",
    tx1: { ocr: 8.5, conf: "Xanh" },
    tx2: { ocr: 9.0, conf: "Xanh" },
    gk: { ocr: 8.0, conf: "Xanh" },
    ck: { ocr: 8.5, conf: "Xanh" },
  },
  {
    id: "HS003",
    name: "Lê Bảo Châu",
    tx1: { ocr: 9.5, conf: "Xanh" },
    tx2: { ocr: 9.0, conf: "Xanh" },
    gk: { ocr: 9.0, conf: "Xanh" },
    ck: { ocr: 9.5, conf: "Xanh" },
  },
  {
    id: "HS002",
    name: "Trần Hoàng Minh",
    tx1: { ocr: 7.0, conf: "Xanh" },
    tx2: { ocr: 7.5, conf: "Xanh" },
    gk: { ocr: 7.0, conf: "Vàng" },
    ck: { ocr: 7.1, conf: "Vàng" },
  },
  {
    id: "HS007",
    name: "Hoàng Ngọc Linh",
    tx1: { ocr: 7.5, conf: "Xanh" },
    tx2: { ocr: 8.0, conf: "Xanh" },
    gk: { ocr: 7.5, conf: "Xanh" },
    ck: { ocr: 7.0, conf: "Xanh" },
  },
  {
    id: "HS004",
    name: "Phạm Gia Huy",
    tx1: { ocr: 6.0, conf: "Xanh" },
    tx2: { ocr: 6.5, conf: "Xanh" },
    gk: { ocr: 7.0, conf: "Xanh" },
    ck: { ocr: 6.5, conf: "Xanh" },
  },
  {
    id: "HS006",
    name: "Vũ Đức Thành",
    tx1: { ocr: null, conf: "Đỏ" },
    tx2: { ocr: 5.5, conf: "Vàng" },
    gk: { ocr: 5.0, conf: "Xanh" },
    ck: { ocr: null, conf: "Đỏ" },
  },
  {
    id: "HS005",
    name: "Đinh Thu Trang",
    tx1: { ocr: 8.0, conf: "Xanh" },
    tx2: { ocr: 8.5, conf: "Xanh" },
    gk: { ocr: 9.0, conf: "Xanh" },
    ck: { ocr: 8.5, conf: "Xanh" },
  },
  {
    id: "HS008",
    name: "Đặng Quang Vinh",
    tx1: { ocr: 4.0, conf: "Xanh" },
    tx2: { ocr: 4.5, conf: "Vàng" },
    gk: { ocr: 5.0, conf: "Xanh" },
    ck: { ocr: 4.0, conf: "Xanh" },
  },
];

const mySheets = allSheets.filter(
  (s) =>
    s.teacher === "Phạm Thu Hà" ||
    s.teacher === "Nguyễn Hoàng Phúc" ||
    s.teacher === "Trần Minh Anh",
);

const ocrHistory = [
  {
    id: "H001",
    sheetId: "BD004",
    cls: "10A4",
    subject: "Tiếng Anh",
    file: "phieu_10A4_anh_v2.jpg",
    uploadedAt: "12/11 09:12",
    numConf: 95,
    letterConf: 93,
    conflict: 0,
    status: "Đã áp dụng",
  },
  {
    id: "H002",
    sheetId: "BD001",
    cls: "10A1",
    subject: "Toán học",
    file: "bang_10A1_toan.jpg",
    uploadedAt: "10/11 16:44",
    numConf: 78,
    letterConf: 72,
    conflict: 3,
    status: "Chờ xác nhận",
  },
];

type OcrStep = "select-sheet" | "upload" | "processing" | "result";

function OcrScreen() {
  const [step, setStep] = useState<OcrStep>("select-sheet");
  const [selectedSheetId, setSelectedSheetId] = useState<string | null>(null);
  const [dragging, setDragging] = useState(false);
  const [progress, setProgress] = useState(0);
  const [activeHistory, setActiveHistory] = useState<string | null>(null);
  const fileRef = useRef<HTMLInputElement>(null);

  const sheet = allSheets.find((s) => s.id === selectedSheetId);

  const startProcessing = () => {
    setStep("processing");
    let p = 0;
    const iv = setInterval(() => {
      p += Math.random() * 18 + 5;
      if (p >= 100) {
        p = 100;
        clearInterval(iv);
        setTimeout(() => setStep("result"), 600);
      }
      setProgress(Math.min(p, 100));
    }, 280);
  };

  // ── Step: chọn bảng điểm ────────────────────────────────────────
  if (step === "select-sheet") {
    return (
      <div className="px-9 py-8">
        <div className="flex items-end justify-between mb-7">
          <div>
            <p className="text-[10px] font-bold tracking-[.18em] text-[#ad8840]">
              PHƯƠNG THỨC NHẬP ĐIỂM
            </p>
            <h1 className="mt-2 font-serif text-[34px] leading-none tracking-tight text-[#173f43]">
              Nhập điểm từ ảnh chụp
            </h1>
            <p className="mt-3 text-sm text-[#697472]">
              Chọn bảng điểm cần nhập, rồi tải lên ảnh phiếu điểm — hệ thống sẽ
              nhận dạng và điền tự động.
            </p>
          </div>
        </div>

        {/* Workflow steps */}
        <div className="mb-8 flex items-start gap-0">
          {[
            { n: "1", label: "Chọn bảng điểm", active: true },
            { n: "2", label: "Tải lên ảnh" },
            { n: "3", label: "Nhận dạng OCR" },
            { n: "4", label: "Xác nhận & áp dụng" },
          ].map((s, i) => (
            <div key={s.n} className="flex flex-1 items-center">
              <div className="flex flex-col items-center text-center flex-1">
                <div
                  className={`grid h-8 w-8 place-items-center rounded-full text-xs font-bold ${s.active ? "bg-[#173f43] text-white" : "border-2 border-[#d0ccc3] text-[#a0a49e]"}`}
                >
                  {s.n}
                </div>
                <p
                  className={`mt-1.5 text-[11px] font-semibold ${s.active ? "text-[#173f43]" : "text-[#a0a49e]"}`}
                >
                  {s.label}
                </p>
              </div>
              {i < 3 && <div className="h-px w-8 bg-[#d0ccc3] shrink-0 mb-4" />}
            </div>
          ))}
        </div>

        <SectionLabel>BẢNG ĐIỂM CỦA BẠN — HK I 2024–2025</SectionLabel>
        <h2 className="mt-1 font-serif text-[20px] text-[#1b4143] mb-4">
          Chọn bảng điểm cần nhập từ ảnh
        </h2>

        <div className="grid grid-cols-2 gap-3 mb-8">
          {mySheets
            .filter((s) => s.status === "Đang nhập")
            .map((s) => (
              <button
                key={s.id}
                onClick={() => {
                  setSelectedSheetId(s.id);
                  setStep("upload");
                }}
                className="group flex items-center gap-4 rounded-xl border-2 border-[#d8d4ca] bg-[#f7f6f1] p-4 text-left hover:border-[#173f43] hover:bg-[#f0ede6] transition-all"
              >
                <div className="grid h-12 w-12 shrink-0 place-items-center rounded-lg bg-[#173f43]/8 text-[#173f43] group-hover:bg-[#173f43]/14">
                  <span className="font-serif text-[15px] font-bold">
                    {s.cls}
                  </span>
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-semibold text-[#244749]">{s.subject}</p>
                  <p className="mt-0.5 text-[11px] text-[#7a7873]">
                    {s.filled}/{s.total} học sinh đã có điểm
                  </p>
                  <div className="mt-2 h-1 overflow-hidden rounded-full bg-[#dedbd2]">
                    <div
                      className="h-full rounded-full bg-[#c69c3c]"
                      style={{ width: `${s.progress}%` }}
                    />
                  </div>
                </div>
                <span className="text-[#a0a49e] group-hover:text-[#173f43] transition-colors">
                  <Icon name="arrow" size={16} />
                </span>
              </button>
            ))}
        </div>

        {ocrHistory.length > 0 && (
          <>
            <SectionLabel>LỊCH SỬ NHẬN DẠNG GẦN ĐÂY</SectionLabel>
            <div className="mt-3 space-y-2">
              {ocrHistory.map((h) => {
                const overallConf = h.conflict > 0 ? "Vàng" : "Xanh";
                const cc = confidenceColor[overallConf];
                return (
                  <Card key={h.id} className="flex items-center gap-4 p-4">
                    <div
                      className={`grid h-10 w-10 shrink-0 place-items-center rounded-lg ${cc.bg} ${cc.text}`}
                    >
                      <Icon name="image" size={17} />
                    </div>
                    <div className="flex-1">
                      <p className="text-sm font-semibold text-[#244749]">
                        {h.subject} — {h.cls}
                      </p>
                      <p className="mt-0.5 text-[11px] text-[#7a7873]">
                        {h.file} · {h.uploadedAt} · Số/Chữ: {h.numConf}%/
                        {h.letterConf}%
                      </p>
                    </div>
                    {h.conflict > 0 && (
                      <span className="inline-flex items-center gap-1 rounded-full bg-[#f5e8c9] px-2.5 py-1 text-[10px] font-bold text-[#9a7222]">
                        <Icon name="alertTriangle" size={11} /> {h.conflict} ô
                        cần xác nhận
                      </span>
                    )}
                    <StatusBadge
                      status={
                        h.status === "Đã áp dụng" ? "Đã chốt" : "Chờ duyệt"
                      }
                    />
                  </Card>
                );
              })}
            </div>
          </>
        )}
      </div>
    );
  }

  // ── Step: tải lên ───────────────────────────────────────────────
  if (step === "upload" && sheet) {
    return (
      <div className="px-9 py-8">
        <button
          onClick={() => {
            setStep("select-sheet");
            setSelectedSheetId(null);
          }}
          className="flex items-center gap-2 text-xs font-bold text-[#196660] mb-6 hover:text-[#173f43]"
        >
          <Icon name="arrowLeft" size={15} /> Chọn lại bảng điểm
        </button>

        {/* Steps */}
        <div className="mb-8 flex items-start gap-0">
          {[
            { n: "1", label: "Chọn bảng điểm", done: true },
            { n: "2", label: "Tải lên ảnh", active: true },
            { n: "3", label: "Nhận dạng OCR" },
            { n: "4", label: "Xác nhận & áp dụng" },
          ].map((s, i) => (
            <div key={s.n} className="flex flex-1 items-center">
              <div className="flex flex-col items-center text-center flex-1">
                <div
                  className={`grid h-8 w-8 place-items-center rounded-full text-xs font-bold ${s.done ? "bg-[#4a8a68] text-white" : s.active ? "bg-[#173f43] text-white" : "border-2 border-[#d0ccc3] text-[#a0a49e]"}`}
                >
                  {s.done ? <Icon name="check" size={13} /> : s.n}
                </div>
                <p
                  className={`mt-1.5 text-[11px] font-semibold ${s.done || s.active ? "text-[#173f43]" : "text-[#a0a49e]"}`}
                >
                  {s.label}
                </p>
              </div>
              {i < 3 && (
                <div
                  className={`h-px w-8 shrink-0 mb-4 ${s.done ? "bg-[#4a8a68]" : "bg-[#d0ccc3]"}`}
                />
              )}
            </div>
          ))}
        </div>

        <div className="grid grid-cols-[1fr_300px] gap-6">
          <div>
            <div className="mb-4 flex items-center gap-3 rounded-xl border border-[#d8d4ca] bg-[#f7f6f1] px-4 py-3">
              <div className="grid h-9 w-9 place-items-center rounded-lg bg-[#173f43]/8 font-serif text-sm font-bold text-[#173f43]">
                {sheet.cls}
              </div>
              <div>
                <p className="font-semibold text-[#244749] text-sm">
                  {sheet.subject} — Lớp {sheet.cls}
                </p>
                <p className="text-[11px] text-[#7a7873]">
                  HK I 2024–2025 · {sheet.total} học sinh
                </p>
              </div>
            </div>

            <div
              onDragOver={(e) => {
                e.preventDefault();
                setDragging(true);
              }}
              onDragLeave={() => setDragging(false)}
              onDrop={(e) => {
                e.preventDefault();
                setDragging(false);
                startProcessing();
              }}
              onClick={() => fileRef.current?.click()}
              className={`flex flex-col items-center justify-center gap-5 rounded-2xl border-2 border-dashed py-16 cursor-pointer transition-colors ${dragging ? "border-[#173f43] bg-[#dfe8e2]" : "border-[#c5c0b4] bg-[#f7f6f1] hover:border-[#8aafa8] hover:bg-[#f0ede6]"}`}
            >
              <input
                ref={fileRef}
                type="file"
                accept="image/*,application/pdf"
                className="hidden"
                onChange={startProcessing}
              />
              <div className="grid h-20 w-20 place-items-center rounded-2xl bg-[#173f43]/10 text-[#173f43]">
                <Icon name="image" size={36} stroke={1.3} />
              </div>
              <div className="text-center">
                <p className="font-serif text-[22px] text-[#173f43]">
                  Kéo thả ảnh phiếu điểm vào đây
                </p>
                <p className="mt-2 text-sm text-[#7a7873]">
                  Hỗ trợ JPG, PNG, PDF · Tối đa 20 MB/file
                </p>
              </div>
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  startProcessing();
                }}
                className="flex items-center gap-2 rounded-lg bg-[#173f43] px-5 py-3 text-xs font-bold text-white hover:bg-[#24555a]"
              >
                <Icon name="upload" size={15} /> Chọn ảnh để tải lên
              </button>
            </div>
          </div>

          <div className="space-y-4">
            <Card className="p-4">
              <SectionLabel>HƯỚNG DẪN CHỤP ẢNH</SectionLabel>
              <div className="mt-3 space-y-3">
                {[
                  [
                    "Ánh sáng đủ",
                    "Chụp nơi đủ sáng, tránh bóng đổ lên tờ điểm",
                  ],
                  [
                    "Khung thẳng",
                    "Đặt phiếu phẳng, ống kính song song với mặt giấy",
                  ],
                  [
                    "Độ phân giải",
                    "Tối thiểu 1200×900 px để nhận dạng chính xác",
                  ],
                  [
                    "Không che khuất",
                    "Đảm bảo tất cả cột và hàng điểm đều nhìn thấy rõ",
                  ],
                ].map(([title, desc]) => (
                  <div key={title} className="flex gap-2.5">
                    <span className="mt-0.5 text-[#4a9e6a] shrink-0">
                      <Icon name="checkCircle" size={14} />
                    </span>
                    <div>
                      <p className="text-[11px] font-bold text-[#3a5050]">
                        {title}
                      </p>
                      <p className="text-[10px] text-[#7a7873] leading-4">
                        {desc}
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            </Card>
            <Card className="p-4">
              <SectionLabel>2 KÊNH NHẬN DẠNG SONG SONG</SectionLabel>
              <div className="mt-3 space-y-3">
                <div className="rounded-lg bg-[#dfe8e2] px-3 py-2.5">
                  <p className="text-[11px] font-bold text-[#1e4f4f]">
                    Kênh điểm số (chữ số)
                  </p>
                  <p className="text-[10px] text-[#4d6b65] leading-4 mt-0.5">
                    Nhận dạng trực tiếp các con số 0–10 trong ô điểm
                  </p>
                </div>
                <div className="rounded-lg bg-[#f5e8c9] px-3 py-2.5">
                  <p className="text-[11px] font-bold text-[#6b4f18]">
                    Kênh điểm chữ (G/K/Đ)
                  </p>
                  <p className="text-[10px] text-[#7a6030] leading-4 mt-0.5">
                    Nhận dạng ký tự xếp loại, đối chiếu chéo với kênh số
                  </p>
                </div>
                <p className="text-[10px] text-[#9a9590]">
                  Hai kết quả được so sánh để phân loại độ tin cậy Xanh/Vàng/Đỏ.
                </p>
              </div>
            </Card>
          </div>
        </div>
      </div>
    );
  }

  // ── Step: đang xử lý ────────────────────────────────────────────
  if (step === "processing") {
    return (
      <div className="px-9 py-8 flex flex-col items-center justify-center min-h-[60vh]">
        <div className="w-full max-w-md text-center">
          <div className="mx-auto mb-6 grid h-20 w-20 place-items-center rounded-2xl bg-[#173f43]/10 text-[#173f43]">
            <Icon name="scan" size={36} stroke={1.4} />
          </div>
          <h2 className="font-serif text-[26px] text-[#173f43]">
            Đang nhận dạng...
          </h2>
          <p className="mt-2 text-sm text-[#697472]">
            Hai kênh OCR đang xử lý song song. Vui lòng chờ trong giây lát.
          </p>

          <div className="mt-8 space-y-4">
            {[
              { label: "Kênh điểm số", prog: Math.min(progress * 1.05, 100) },
              { label: "Kênh điểm chữ", prog: Math.min(progress * 0.95, 100) },
            ].map((ch) => (
              <div key={ch.label}>
                <div className="flex justify-between text-[11px] mb-1.5">
                  <span className="font-semibold text-[#3a5050]">
                    {ch.label}
                  </span>
                  <span className="text-[#7a7873]">{Math.round(ch.prog)}%</span>
                </div>
                <div className="h-2 overflow-hidden rounded-full bg-[#d8d4ca]">
                  <div
                    className="h-full rounded-full bg-[#173f43] transition-all duration-300"
                    style={{ width: `${ch.prog}%` }}
                  />
                </div>
              </div>
            ))}
          </div>

          <div className="mt-6 flex justify-center gap-6 text-[11px] text-[#7a7873]">
            <span className="flex items-center gap-1.5">
              <span className="h-2 w-2 rounded-full bg-[#4a9e6a]" /> Đọc cấu
              trúc bảng
            </span>
            <span className="flex items-center gap-1.5">
              <span className="h-2 w-2 rounded-full bg-[#c69c3c]" /> Trích xuất
              ô điểm
            </span>
            <span className="flex items-center gap-1.5">
              <span className="h-2 w-2 rounded-full bg-[#173f43]" /> Đối chiếu 2
              kênh
            </span>
          </div>
        </div>
      </div>
    );
  }

  // ── Step: kết quả nhận dạng ─────────────────────────────────────
  const totalCells = ocrRawRows.length * 4;
  const redCells = ocrRawRows
    .flatMap((r) => [r.tx1, r.tx2, r.gk, r.ck])
    .filter((c) => c.conf === "Đỏ").length;
  const yellowCells = ocrRawRows
    .flatMap((r) => [r.tx1, r.tx2, r.gk, r.ck])
    .filter((c) => c.conf === "Vàng").length;
  const greenCells = totalCells - redCells - yellowCells;

  return (
    <div className="px-9 py-8">
      <div className="flex items-center justify-between mb-6">
        <div>
          <p className="text-[10px] font-bold tracking-[.16em] text-[#ad8840]">
            KẾT QUẢ NHẬN DẠNG · {sheet?.subject} — {sheet?.cls}
          </p>
          <h1 className="mt-2 font-serif text-[30px] leading-none tracking-tight text-[#173f43]">
            Máy đã đọc xong — hãy xem lại
          </h1>
          <p className="mt-1.5 text-sm text-[#697472]">
            {sheet?.total} học sinh · Nhận dạng lúc 09:14
          </p>
        </div>
        <div className="flex gap-2">
          <button
            onClick={() => setStep("upload")}
            className="rounded-lg border border-[#d0ccc3] px-4 py-2.5 text-xs font-semibold text-[#445350] hover:bg-[#ebe9e2]"
          >
            Chụp lại
          </button>
          <button className="flex items-center gap-2 rounded-lg bg-[#173f43] px-4 py-2.5 text-xs font-bold text-white hover:bg-[#24555a]">
            <Icon name="check" size={14} /> Xác nhận & áp dụng
          </button>
        </div>
      </div>

      {/* Summary bars */}
      <div className="grid grid-cols-3 gap-4 mb-6">
        {[
          {
            label: "Xanh — Tin cậy cao",
            count: greenCells,
            total: totalCells,
            cc: confidenceColor["Xanh"],
            desc: "Áp dụng ngay, không cần xem lại",
          },
          {
            label: "Vàng — Nghi ngờ",
            count: yellowCells,
            total: totalCells,
            cc: confidenceColor["Vàng"],
            desc: "Nên kiểm tra lại trước khi lưu",
          },
          {
            label: "Đỏ — Không đọc được",
            count: redCells,
            total: totalCells,
            cc: confidenceColor["Đỏ"],
            desc: "Bắt buộc nhập tay ô này",
          },
        ].map(({ label, count, total, cc, desc }) => (
          <div
            key={label}
            className={`rounded-xl border p-4 ${cc.bg} ${cc.border}`}
          >
            <div className="flex items-end gap-2">
              <p className={`font-serif text-[30px] leading-none ${cc.text}`}>
                {count}
              </p>
              <p className={`mb-1 text-[11px] ${cc.text} opacity-70`}>
                / {total} ô
              </p>
            </div>
            <p className={`mt-2 text-[11px] font-bold ${cc.text}`}>{label}</p>
            <p className={`mt-0.5 text-[10px] ${cc.text} opacity-70`}>{desc}</p>
          </div>
        ))}
      </div>

      {/* 2-channel accuracy */}
      <div className="grid grid-cols-2 gap-4 mb-6">
        {[
          ["Kênh điểm số (chữ số)", "Nhận dạng con số trong ô điểm", 92],
          ["Kênh điểm chữ (G/K/Đ/CĐ)", "Nhận dạng ký hiệu xếp loại", 89],
        ].map(([label, desc, pct]) => (
          <Card
            key={label as string}
            className="flex items-center gap-4 px-5 py-4"
          >
            <div className="flex-1">
              <p className="text-[11px] font-bold text-[#3e5656]">{label}</p>
              <p className="text-[10px] text-[#7a7873]">{desc}</p>
            </div>
            <div className="text-right">
              <p className="font-serif text-[24px] text-[#173f43]">{pct}%</p>
              <div className="mt-1 h-1.5 w-20 overflow-hidden rounded-full bg-[#dedbd2]">
                <div
                  className="h-full rounded-full bg-[#173f43]"
                  style={{ width: `${pct}%` }}
                />
              </div>
            </div>
          </Card>
        ))}
      </div>

      {/* Per-student OCR table */}
      <Card className="overflow-hidden">
        <div className="flex items-center justify-between px-5 py-4 border-b border-[#e5e0d7]">
          <h3 className="font-serif text-[18px] text-[#1b4143]">
            Kết quả theo từng học sinh
          </h3>
          <div className="flex gap-4 text-[10px]">
            {[
              ["Xanh", "#4a9e6a"],
              ["Vàng", "#c69c3c"],
              ["Đỏ", "#c87858"],
            ].map(([l, c]) => (
              <span
                key={l}
                className="flex items-center gap-1.5 text-[#62716e]"
              >
                <span
                  className="h-2.5 w-2.5 rounded-sm"
                  style={{ backgroundColor: c }}
                />
                {l}
              </span>
            ))}
          </div>
        </div>
        <table className="w-full text-xs">
          <thead className="bg-[#ece9e1] text-[10px] tracking-[.1em] text-[#817c71]">
            <tr>
              <th className="px-5 py-3 font-bold text-left">HỌ VÀ TÊN</th>
              <th className="px-4 py-3 font-bold text-center">TX1</th>
              <th className="px-4 py-3 font-bold text-center">TX2</th>
              <th className="px-4 py-3 font-bold text-center">GIỮA KỲ</th>
              <th className="px-4 py-3 font-bold text-center">CUỐI KỲ</th>
              <th className="px-4 py-3 font-bold text-center">ĐIỂM TB</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-[#e5e0d7]">
            {ocrRawRows.map((row) => {
              const cells = [row.tx1, row.tx2, row.gk, row.ck];
              const hasIssue = cells.some((c) => c.conf !== "Xanh");
              const validVals = cells
                .filter((c) => c.ocr !== null)
                .map((c) => c.ocr as number);
              const avg = validVals.length
                ? (
                    validVals.reduce((a, b) => a + b, 0) / validVals.length
                  ).toFixed(1)
                : "—";
              return (
                <tr
                  key={row.id}
                  className={hasIssue ? "bg-[#fffdf5]" : "hover:bg-[#fbfaf7]"}
                >
                  <td className="px-5 py-3.5 font-semibold text-[#244749]">
                    {row.name}
                  </td>
                  {cells.map((cell, ci) => {
                    const cc = confidenceColor[cell.conf];
                    return (
                      <td key={ci} className="px-4 py-3 text-center">
                        {cell.ocr === null ? (
                          <div className="inline-flex items-center gap-1">
                            <span className="text-[#c87858] text-[10px] font-bold">
                              —
                            </span>
                            <input
                              placeholder="nhập"
                              className="w-12 rounded border border-[#e8a992] bg-[#fff8f5] py-0.5 text-center text-[11px] outline-none focus:ring-1 ring-[#e8a992]"
                            />
                          </div>
                        ) : (
                          <span
                            className={`inline-block rounded px-2 py-0.5 text-[11px] font-bold ${cc.bg} ${cc.text}`}
                          >
                            {cell.ocr}
                          </span>
                        )}
                      </td>
                    );
                  })}
                  <td className="px-4 py-3 text-center font-bold text-[#173f43]">
                    {avg}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </Card>

      <div className="mt-5 flex items-center justify-between">
        <p className="text-[11px] text-[#9a9590]">
          Sau khi xác nhận, điểm sẽ được áp dụng vào bảng điểm {sheet?.subject}{" "}
          — {sheet?.cls}. Bạn vẫn có thể chỉnh sửa thủ công sau đó.
        </p>
        <div className="flex gap-3 ml-6 shrink-0">
          <button
            onClick={() => setStep("upload")}
            className="rounded-lg border border-[#d0ccc3] px-4 py-2.5 text-xs font-semibold text-[#445350] hover:bg-[#ebe9e2]"
          >
            Chụp lại ảnh khác
          </button>
          <button className="flex items-center gap-2 rounded-lg bg-[#173f43] px-5 py-2.5 text-xs font-bold text-white hover:bg-[#24555a]">
            <Icon name="checkCircle" size={14} /> Xác nhận & áp dụng vào bảng
            điểm
          </button>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 5: ĐỐI CHIẾU & XÁC NHẬN (giáo viên tự kiểm tra kết quả OCR của mình)
// ─────────────────────────────────────────────────────────────────────────────

// Trạng thái lựa chọn của từng ô: "ocr" | "manual" | null (chưa quyết)
type CellChoice = "ocr" | "manual";

// Mỗi ô cần đối chiếu
type ConflictCell = {
  studentId: string;
  studentName: string;
  col: "TX1" | "TX2" | "GK" | "CK";
  ocrVal: number | null;
  conf: "Xanh" | "Vàng" | "Đỏ";
  manualVal: number | null; // giá trị hiện tại trong bảng (nếu có)
};

const conflictRows: ConflictCell[] = [
  {
    studentId: "HS002",
    studentName: "Trần Hoàng Minh",
    col: "GK",
    ocrVal: 7.0,
    conf: "Vàng",
    manualVal: 7.5,
  },
  {
    studentId: "HS002",
    studentName: "Trần Hoàng Minh",
    col: "CK",
    ocrVal: 7.1,
    conf: "Vàng",
    manualVal: 7.5,
  },
  {
    studentId: "HS006",
    studentName: "Vũ Đức Thành",
    col: "TX1",
    ocrVal: null,
    conf: "Đỏ",
    manualVal: null,
  },
  {
    studentId: "HS006",
    studentName: "Vũ Đức Thành",
    col: "TX2",
    ocrVal: 5.5,
    conf: "Vàng",
    manualVal: null,
  },
  {
    studentId: "HS006",
    studentName: "Vũ Đức Thành",
    col: "CK",
    ocrVal: null,
    conf: "Đỏ",
    manualVal: null,
  },
];

// Tất cả hàng (kể cả đã OK)
const allOcrRows = ocrRawRows.map((r) => {
  const cells: { col: "TX1" | "TX2" | "GK" | "CK"; cell: OcrCell }[] = [
    { col: "TX1", cell: r.tx1 },
    { col: "TX2", cell: r.tx2 },
    { col: "GK", cell: r.gk },
    { col: "CK", cell: r.ck },
  ];
  return { ...r, cells, hasIssue: cells.some((c) => c.cell.conf !== "Xanh") };
});

function ReconcileScreen() {
  const [view, setView] = useState<"list" | "detail">("list");
  const [choices, setChoices] = useState<Record<string, CellChoice>>({});
  const [manualInputs, setManualInputs] = useState<Record<string, string>>({});
  const [confirmedRows, setConfirmedRows] = useState<Set<string>>(new Set());

  const pendingCount = conflictRows.filter((c) => {
    const key = `${c.studentId}-${c.col}`;
    return !choices[key];
  }).length;

  const toggleChoice = (key: string, val: CellChoice) =>
    setChoices((prev) => ({ ...prev, [key]: prev[key] === val ? "ocr" : val }));

  const confirmRow = (sid: string) =>
    setConfirmedRows((prev) => {
      const n = new Set(prev);
      n.add(sid);
      return n;
    });

  // ── Danh sách bảng điểm chờ đối chiếu ──────────────────────────
  if (view === "list") {
    return (
      <div className="px-9 py-8">
        <div className="flex items-end justify-between mb-7">
          <div>
            <p className="text-[10px] font-bold tracking-[.18em] text-[#ad8840]">
              KẾT QUẢ OCR CỦA BẠN
            </p>
            <h1 className="mt-2 font-serif text-[34px] leading-none tracking-tight text-[#173f43]">
              Xem lại & xác nhận điểm
            </h1>
            <p className="mt-2.5 text-sm text-[#697472]">
              Hệ thống đã nhận dạng xong. Hãy kiểm tra các ô nghi ngờ rồi xác
              nhận để áp dụng vào bảng điểm.
            </p>
          </div>
        </div>

        {/* Banner hướng dẫn */}
        <div className="mb-6 flex items-start gap-3 rounded-xl border border-[#b8d9c8] bg-[#edf7f2] px-5 py-4">
          <span className="mt-0.5 text-[#256848] shrink-0">
            <Icon name="info" size={16} />
          </span>
          <div>
            <p className="text-xs font-bold text-[#256848]">
              Bạn là người quyết định cuối cùng
            </p>
            <p className="mt-0.5 text-[11px] leading-5 text-[#3d6b58]">
              Ô <span className="font-bold text-[#256848]">Xanh</span> — máy đọc
              chính xác, có thể chấp nhận ngay.&ensp; Ô{" "}
              <span className="font-bold text-[#9a7222]">Vàng</span> — máy không
              chắc, hãy so với phiếu gốc.&ensp; Ô{" "}
              <span className="font-bold text-[#9b4430]">Đỏ</span> — không đọc
              được, bạn phải nhập tay.
            </p>
          </div>
        </div>

        {/* Thống kê */}
        <div className="grid grid-cols-4 gap-4 mb-7">
          {[
            { v: "8", l: "Học sinh", h: "Toán học — 10A4", c: "#dfe8e2" },
            { v: "5", l: "Ô cần xem lại", h: "2 Vàng · 3 Đỏ", c: "#f5e8c9" },
            { v: "27", l: "Ô đã tin cậy", h: "Áp dụng ngay", c: "#dfe8e2" },
            {
              v: "3",
              l: "Ô chưa quyết",
              h: "Cần chọn Dùng OCR / Nhập tay",
              c: "#f2ded5",
            },
          ].map(({ v, l, h, c }) => (
            <Card key={l} className="p-4">
              <p className="font-serif text-[26px] text-[#173f43]">{v}</p>
              <p className="mt-3 text-xs font-bold text-[#3e5656]">{l}</p>
              <p className="mt-0.5 text-[11px] text-[#86847b]">{h}</p>
              <div
                className="mt-3 h-1 rounded-full"
                style={{ backgroundColor: c }}
              />
            </Card>
          ))}
        </div>

        <button onClick={() => setView("detail")} className="w-full mb-3">
          <Card className="flex items-center gap-4 p-4 hover:shadow-md transition cursor-pointer border-[#b8d9c8]">
            <div className="grid h-10 w-10 shrink-0 place-items-center rounded-lg bg-[#f5e8c9] text-[#9a7222]">
              <Icon name="clipboard" size={18} />
            </div>
            <div className="flex-1 text-left">
              <div className="flex items-center gap-2">
                <span className="font-semibold text-[#244749] text-sm">
                  Toán học — 10A4
                </span>
                <span className="inline-flex items-center gap-1 rounded-full bg-[#f5e8c9] px-2 py-0.5 text-[10px] font-bold text-[#9a7222]">
                  Vàng
                </span>
              </div>
              <p className="mt-0.5 text-[11px] text-[#7a7873]">
                Nhận dạng 12/11 09:14 · 8 học sinh · 5 ô cần xem lại
              </p>
            </div>
            <div className="text-right mr-2">
              <span className="inline-flex items-center gap-1.5 rounded-full bg-[#fbe4dc] px-2.5 py-1 text-[10px] font-bold text-[#9b4430]">
                <Icon name="alertTriangle" size={11} /> {pendingCount} ô chưa
                quyết
              </span>
            </div>
            <Icon name="arrow" size={16} />
          </Card>
        </button>

        <Card className="flex items-center gap-4 p-4 opacity-60">
          <div className="grid h-10 w-10 shrink-0 place-items-center rounded-lg bg-[#d5ede5] text-[#256848]">
            <Icon name="checkCircle" size={18} />
          </div>
          <div className="flex-1 text-left">
            <p className="font-semibold text-[#244749] text-sm">
              Tiếng Anh — 10A4
            </p>
            <p className="mt-0.5 text-[11px] text-[#7a7873]">
              Nhận dạng 10/11 14:20 · 34 học sinh · Không có ô nghi ngờ
            </p>
          </div>
          <StatusBadge status="Đã chốt" />
        </Card>
      </div>
    );
  }

  // ── Chi tiết đối chiếu từng ô ───────────────────────────────────
  const colLabels: Record<string, string> = {
    TX1: "Thường xét 1",
    TX2: "Thường xét 2",
    GK: "Giữa kỳ",
    CK: "Cuối kỳ",
  };

  return (
    <div className="px-9 py-8">
      <button
        onClick={() => setView("list")}
        className="flex items-center gap-2 text-xs font-bold text-[#196660] mb-6 hover:text-[#173f43]"
      >
        <Icon name="arrowLeft" size={15} /> Quay lại danh sách
      </button>

      <div className="flex items-start justify-between mb-6">
        <div>
          <p className="text-[10px] font-bold tracking-[.16em] text-[#ad8840]">
            ĐỐI CHIẾU KẾT QUẢ OCR · TOÁN HỌC — 10A4
          </p>
          <h1 className="mt-2 font-serif text-[30px] leading-none tracking-tight text-[#173f43]">
            Xem lại & xác nhận điểm của bạn
          </h1>
          <p className="mt-1.5 text-sm text-[#697472]">
            Nhận dạng lúc 09:14 · 8 học sinh · Ảnh:{" "}
            <span className="font-semibold">phieu_10A4_toan.jpg</span>
          </p>
        </div>
        <div className="flex gap-2">
          <button className="rounded-lg border border-[#d0ccc3] px-4 py-2.5 text-xs font-semibold text-[#445350] hover:bg-[#ebe9e2]">
            Chụp lại ảnh
          </button>
          <button
            disabled={pendingCount > 0}
            className={`flex items-center gap-2 rounded-lg px-5 py-2.5 text-xs font-bold transition ${pendingCount > 0 ? "bg-[#c5c0b4] text-white cursor-not-allowed" : "bg-[#173f43] text-white hover:bg-[#24555a]"}`}
          >
            <Icon name="checkCircle" size={14} />
            {pendingCount > 0
              ? `Còn ${pendingCount} ô chưa quyết`
              : "Áp dụng vào bảng điểm"}
          </button>
        </div>
      </div>

      {/* Ô có vấn đề — cần quyết định */}
      {conflictRows.filter((c) => !confirmedRows.has(c.studentId + c.col))
        .length > 0 && (
        <div className="mb-6">
          <div className="flex items-center gap-2 mb-3">
            <span className="text-[#9a7222]">
              <Icon name="alertTriangle" size={15} />
            </span>
            <h2 className="font-serif text-[18px] text-[#7a5c12]">
              Ô cần bạn quyết định
            </h2>
            <span className="ml-1 rounded-full bg-[#f5e8c9] px-2 py-0.5 text-[10px] font-bold text-[#9a7222]">
              {
                conflictRows.filter(
                  (c) => !confirmedRows.has(c.studentId + c.col),
                ).length
              }
            </span>
          </div>
          <div className="space-y-2">
            {conflictRows
              .filter((c) => !confirmedRows.has(c.studentId + c.col))
              .map((cell) => {
                const key = `${cell.studentId}-${cell.col}`;
                const choice = choices[key];
                const cc = confidenceColor[cell.conf];
                return (
                  <div
                    key={key}
                    className={`rounded-xl border px-5 py-4 ${cell.conf === "Đỏ" ? "border-[#e8a992] bg-[#fff8f5]" : "border-[#e8c96d] bg-[#fdfbef]"}`}
                  >
                    <div className="flex items-center gap-4 flex-wrap">
                      <div className="w-44 shrink-0">
                        <p className="font-semibold text-[#244749] text-sm">
                          {cell.studentName}
                        </p>
                        <p className="mt-0.5 text-[10px] text-[#9a9590]">
                          {colLabels[cell.col]}
                        </p>
                      </div>

                      {/* OCR result */}
                      <div
                        className={`flex-1 min-w-32 rounded-lg border px-4 py-3 ${cc.bg} ${cc.border}`}
                      >
                        <p
                          className={`text-[10px] font-bold tracking-[.12em] mb-1 ${cc.text}`}
                        >
                          KẾT QUẢ OCR
                        </p>
                        {cell.ocrVal !== null ? (
                          <p
                            className={`font-serif text-[22px] leading-none ${cc.text}`}
                          >
                            {cell.ocrVal}
                          </p>
                        ) : (
                          <p className="font-serif text-[16px] text-[#c87858]">
                            Không đọc được
                          </p>
                        )}
                        <p className={`mt-1 text-[10px] ${cc.text} opacity-70`}>
                          Độ tin cậy: {cell.conf}
                        </p>
                      </div>

                      {/* Existing value */}
                      <div className="flex-1 min-w-32 rounded-lg border border-[#d8d4ca] bg-[#f0ede6] px-4 py-3">
                        <p className="text-[10px] font-bold tracking-[.12em] text-[#9c9587] mb-1">
                          GIÁ TRỊ HIỆN TẠI
                        </p>
                        {cell.manualVal !== null ? (
                          <p className="font-serif text-[22px] leading-none text-[#173f43]">
                            {cell.manualVal}
                          </p>
                        ) : (
                          <p className="text-[13px] text-[#a0a49e]">Chưa có</p>
                        )}
                        <p className="mt-1 text-[10px] text-[#9a9590]">
                          Đã nhập trước đó
                        </p>
                      </div>

                      {/* Manual input */}
                      <div className="flex-1 min-w-36 rounded-lg border border-[#d8d4ca] bg-white px-4 py-3">
                        <p className="text-[10px] font-bold tracking-[.12em] text-[#9c9587] mb-2">
                          NHẬP TAY (nếu khác)
                        </p>
                        <input
                          value={manualInputs[key] ?? ""}
                          onChange={(e) => {
                            setManualInputs((p) => ({
                              ...p,
                              [key]: e.target.value,
                            }));
                            setChoices((p) => ({ ...p, [key]: "manual" }));
                          }}
                          placeholder="0–10"
                          className="w-full rounded border border-[#d0ccc3] py-1.5 text-center text-sm font-bold outline-none focus:ring-2 ring-[#aac4bc]"
                        />
                      </div>

                      {/* Buttons */}
                      <div className="flex flex-col gap-2 shrink-0 w-36">
                        <button
                          onClick={() => {
                            toggleChoice(key, "ocr");
                          }}
                          className={`rounded-lg px-3 py-2 text-[11px] font-bold border transition ${choice === "ocr" ? "bg-[#173f43] text-white border-[#173f43]" : "border-[#d0ccc3] text-[#445350] hover:bg-[#ebe9e2]"}`}
                        >
                          {choice === "ocr" ? (
                            <>
                              <Icon name="check" size={11} /> Dùng OCR
                            </>
                          ) : (
                            "Dùng giá trị OCR"
                          )}
                        </button>
                        <button
                          onClick={() => {
                            confirmRow(cell.studentId + cell.col);
                            if (!choices[key])
                              setChoices((p) => ({ ...p, [key]: "manual" }));
                          }}
                          className={`rounded-lg px-3 py-2 text-[11px] font-bold border transition ${choice === "manual" ? "bg-[#c69c3c] text-white border-[#c69c3c]" : "border-[#d0ccc3] text-[#445350] hover:bg-[#ebe9e2]"}`}
                        >
                          Giữ / Nhập tay
                        </button>
                      </div>
                    </div>
                  </div>
                );
              })}
          </div>
        </div>
      )}

      {/* Bảng toàn bộ học sinh */}
      <Card className="overflow-hidden">
        <div className="flex items-center justify-between px-5 py-4 border-b border-[#e5e0d7]">
          <h3 className="font-serif text-[18px] text-[#1b4143]">
            Toàn bộ kết quả nhận dạng
          </h3>
          <div className="flex gap-4 text-[10px]">
            {(
              [
                ["Xanh", "#4a9e6a"],
                ["Vàng", "#c69c3c"],
                ["Đỏ — Nhập tay", "#c87858"],
              ] as const
            ).map(([l, c]) => (
              <span
                key={l}
                className="flex items-center gap-1.5 text-[#62716e]"
              >
                <span
                  className="h-2.5 w-2.5 rounded-sm inline-block"
                  style={{ backgroundColor: c }}
                />
                {l}
              </span>
            ))}
          </div>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-xs">
            <thead className="bg-[#ece9e1] text-[10px] tracking-[.1em] text-[#817c71]">
              <tr>
                <th className="px-5 py-3 font-bold text-left">HỌ VÀ TÊN</th>
                <th className="px-4 py-3 font-bold text-center">TX1</th>
                <th className="px-4 py-3 font-bold text-center">TX2</th>
                <th className="px-4 py-3 font-bold text-center">GIỮA KỲ</th>
                <th className="px-4 py-3 font-bold text-center">CUỐI KỲ</th>
                <th className="px-4 py-3 font-bold text-center">ĐIỂM TB</th>
                <th className="px-4 py-3 font-bold text-center">TRẠNG THÁI</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#e5e0d7]">
              {allOcrRows.map((row) => {
                const rowConfirmed = confirmedRows.has(row.id);
                const validVals = row.cells
                  .map((c) => {
                    const key = `${row.id}-${c.col}`;
                    if (c.cell.ocr === null && manualInputs[key])
                      return parseFloat(manualInputs[key]);
                    return c.cell.ocr;
                  })
                  .filter((v) => v !== null) as number[];
                const avg =
                  validVals.length === 4
                    ? (validVals.reduce((a, b) => a + b, 0) / 4).toFixed(1)
                    : "—";
                return (
                  <tr
                    key={row.id}
                    className={`${row.hasIssue && !rowConfirmed ? "bg-[#fffdf5]" : "hover:bg-[#fbfaf7]"}`}
                  >
                    <td className="px-5 py-3.5 font-semibold text-[#244749]">
                      {row.name}
                    </td>
                    {row.cells.map(({ col, cell }) => {
                      const key = `${row.id}-${col}`;
                      const chosen = choices[key];
                      const cc = confidenceColor[cell.conf];
                      const displayVal =
                        chosen === "manual" && manualInputs[key]
                          ? manualInputs[key]
                          : cell.ocr !== null
                            ? cell.ocr
                            : null;
                      return (
                        <td key={col} className="px-4 py-3 text-center">
                          {cell.conf === "Đỏ" && displayVal === null ? (
                            <input
                              value={manualInputs[key] ?? ""}
                              onChange={(e) =>
                                setManualInputs((p) => ({
                                  ...p,
                                  [key]: e.target.value,
                                }))
                              }
                              placeholder="—"
                              className="w-12 rounded border border-[#e8a992] bg-[#fff8f5] py-0.5 text-center text-[11px] font-bold outline-none focus:ring-1 ring-[#e8a992] text-[#9b4430]"
                            />
                          ) : (
                            <span
                              className={`inline-block rounded px-2 py-0.5 text-[11px] font-bold ${chosen === "manual" ? "bg-[#e5e0d7] text-[#3a5050]" : `${cc.bg} ${cc.text}`}`}
                            >
                              {displayVal ?? "—"}
                            </span>
                          )}
                        </td>
                      );
                    })}
                    <td className="px-4 py-3 text-center font-bold text-[#173f43]">
                      {avg}
                    </td>
                    <td className="px-4 py-3 text-center">
                      {row.hasIssue ? (
                        rowConfirmed ? (
                          <span className="text-[#4a9e6a]">
                            <Icon name="checkCircle" size={14} />
                          </span>
                        ) : (
                          <span className="text-[#9a7222]">
                            <Icon name="alertTriangle" size={14} />
                          </span>
                        )
                      ) : (
                        <span className="text-[#4a9e6a]">
                          <Icon name="checkCircle" size={14} />
                        </span>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </Card>

      <div className="mt-5 flex items-center justify-between">
        <p className="text-[11px] text-[#9a9590]">
          Sau khi áp dụng, điểm sẽ được điền vào bảng điểm Toán học — 10A4. Bạn
          vẫn có thể chỉnh sửa thủ công bất cứ lúc nào.
        </p>
        <div className="flex gap-3 ml-6 shrink-0">
          <button
            onClick={() => setView("list")}
            className="rounded-lg border border-[#d0ccc3] px-4 py-2.5 text-xs font-semibold text-[#445350] hover:bg-[#ebe9e2]"
          >
            Quay lại
          </button>
          <button
            disabled={pendingCount > 0}
            className={`flex items-center gap-2 rounded-lg px-5 py-2.5 text-xs font-bold transition ${pendingCount > 0 ? "bg-[#c5c0b4] text-white cursor-not-allowed" : "bg-[#173f43] text-white hover:bg-[#24555a]"}`}
          >
            <Icon name="checkCircle" size={14} />
            {pendingCount > 0
              ? `Còn ${pendingCount} ô chưa quyết`
              : "Áp dụng vào bảng điểm"}
          </button>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 6: TỔNG KẾT KẾT QUẢ
// ─────────────────────────────────────────────────────────────────────────────
const summaryClasses = [
  {
    cls: "12A2",
    grade: "Khối 12",
    students: 38,
    gpa: 7.8,
    excellent: 14,
    good: 18,
    pass: 5,
    fail: 1,
    topStudent: "Đinh Thu Trang",
    topGpa: 9.1,
  },
  {
    cls: "11A3",
    grade: "Khối 11",
    students: 40,
    gpa: 7.4,
    excellent: 10,
    good: 22,
    pass: 7,
    fail: 1,
    topStudent: "Lê Bảo Châu",
    topGpa: 9.1,
  },
  {
    cls: "10A1",
    grade: "Khối 10",
    students: 36,
    gpa: 7.1,
    excellent: 8,
    good: 18,
    pass: 9,
    fail: 1,
    topStudent: "Nguyễn Thị Lan Anh",
    topGpa: 8.6,
  },
  {
    cls: "11B2",
    grade: "Khối 11",
    students: 36,
    gpa: 6.8,
    excellent: 6,
    good: 16,
    pass: 12,
    fail: 2,
    topStudent: "Phạm Gia Huy",
    topGpa: 7.9,
  },
  {
    cls: "10A4",
    grade: "Khối 10",
    students: 38,
    gpa: 6.5,
    excellent: 5,
    good: 17,
    pass: 14,
    fail: 2,
    topStudent: "Hoàng Ngọc Linh",
    topGpa: 7.8,
  },
];

function SummaryScreen() {
  const [selectedCls, setSelectedCls] = useState<string | null>(null);
  const cls = summaryClasses.find((c) => c.cls === selectedCls);

  if (cls) {
    return (
      <div className="px-9 py-8">
        <button
          onClick={() => setSelectedCls(null)}
          className="flex items-center gap-2 text-xs font-bold text-[#196660] mb-6 hover:text-[#173f43]"
        >
          <Icon name="arrowLeft" size={15} /> Quay lại tổng kết
        </button>
        <div className="flex items-start justify-between mb-7">
          <div>
            <p className="text-[10px] font-bold tracking-[.16em] text-[#ad8840]">
              TỔNG KẾT HỌC KỲ I, 2024–2025
            </p>
            <h1 className="mt-2 font-serif text-[32px] leading-none tracking-tight text-[#173f43]">
              Lớp {cls.cls}
            </h1>
            <p className="mt-2 text-sm text-[#697472]">
              {cls.grade} · {cls.students} học sinh · Điểm trung bình:{" "}
              <span className="font-bold text-[#173f43]">{cls.gpa}</span>
            </p>
          </div>
          <div className="flex gap-2">
            <button className="flex items-center gap-1.5 rounded-lg border border-[#d0ccc3] bg-[#f7f6f1] px-3 py-2.5 text-xs font-semibold text-[#445350] hover:bg-[#ebe9e2]">
              <Icon name="printer" size={14} /> In học bạ
            </button>
            <button className="flex items-center gap-2 rounded-lg bg-[#173f43] px-4 py-2.5 text-xs font-bold text-white hover:bg-[#24555a]">
              <Icon name="download" size={14} /> Xuất danh sách
            </button>
          </div>
        </div>

        <div className="grid grid-cols-4 gap-4 mb-7">
          {[
            ["Giỏi", cls.excellent, "#276e68", "#d4f0e4"],
            ["Khá", cls.good, "#527b99", "#dbe7f1"],
            ["Đạt", cls.pass, "#b8863d", "#f5e8c9"],
            ["Chưa đạt", cls.fail, "#c87858", "#fbe4dc"],
          ].map(([l, v, c, bg]) => (
            <div
              key={l as string}
              className="rounded-xl border border-[#d8d4ca] p-4"
              style={{ backgroundColor: bg as string }}
            >
              <p
                className="font-serif text-[28px]"
                style={{ color: c as string }}
              >
                {v}
              </p>
              <p
                className="mt-2 text-xs font-bold"
                style={{ color: c as string }}
              >
                {l}
              </p>
              <p className="mt-0.5 text-[11px] text-[#86847b]">
                {Math.round((Number(v) / cls.students) * 100)}% tổng số
              </p>
            </div>
          ))}
        </div>

        <div className="grid grid-cols-[1fr_300px] gap-6">
          <Card>
            <table className="w-full text-xs">
              <thead className="bg-[#ece9e1] text-[10px] tracking-[.1em] text-[#817c71]">
                <tr>
                  <th className="px-4 py-3 font-bold text-left">XẾP HẠNG</th>
                  <th className="px-4 py-3 font-bold text-left">HỌC SINH</th>
                  <th className="px-3 py-3 font-bold text-center">ĐTB</th>
                  <th className="px-3 py-3 font-bold text-center">XẾP LOẠI</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#e5e0d7]">
                {sheetStudents
                  .sort((a, b) => b.avg - a.avg)
                  .map((s, i) => (
                    <tr
                      key={s.id}
                      className={`hover:bg-[#fbfaf7] ${i === 0 ? "bg-[#f8f4e3]" : ""}`}
                    >
                      <td className="px-4 py-3">
                        {i === 0 ? (
                          <span className="text-[#c69c3c]">
                            <Icon name="star" size={14} stroke={2} />
                          </span>
                        ) : (
                          <span className="text-[#9a9590] font-mono">
                            {i + 1}
                          </span>
                        )}
                      </td>
                      <td className="px-4 py-3 font-semibold text-[#244749]">
                        {s.name}
                      </td>
                      <td className="px-3 py-3 text-center font-bold text-[#173f43]">
                        {s.avg}
                      </td>
                      <td className="px-3 py-3 text-center">
                        <StatusBadge
                          status={
                            s.letter === "G"
                              ? "Giỏi"
                              : s.letter === "K"
                                ? "Khá"
                                : s.letter === "Đ"
                                  ? "Đạt"
                                  : "Chưa đạt"
                          }
                        />
                      </td>
                    </tr>
                  ))}
              </tbody>
            </table>
          </Card>
          <Card className="p-5">
            <SectionLabel>PHÂN BỐ KẾT QUẢ</SectionLabel>
            <h3 className="mt-1 font-serif text-[18px] text-[#1b4143] mb-5">
              Biểu đồ lớp {cls.cls}
            </h3>
            {[
              ["Giỏi", cls.excellent, cls.students, "#276e68"],
              ["Khá", cls.good, cls.students, "#527b99"],
              ["Đạt", cls.pass, cls.students, "#d3ae54"],
              ["Chưa đạt", cls.fail, cls.students, "#c87858"],
            ].map(([l, v, t, c]) => (
              <div key={l as string} className="mb-4">
                <div className="flex justify-between text-[11px] mb-1.5">
                  <span className="font-semibold text-[#3e5656]">{l}</span>
                  <span className="text-[#7a7873]">
                    {v} · {Math.round((Number(v) / Number(t)) * 100)}%
                  </span>
                </div>
                <div className="h-2 overflow-hidden rounded-full bg-[#e5e4dd]">
                  <div
                    className="h-full rounded-full"
                    style={{
                      width: `${Math.round((Number(v) / Number(t)) * 100)}%`,
                      backgroundColor: c as string,
                    }}
                  />
                </div>
              </div>
            ))}
            <div className="mt-5 rounded-lg bg-[#173f43]/5 p-3">
              <p className="text-[10px] font-bold tracking-[.12em] text-[#9c9587]">
                HỌC SINH XUẤT SẮC NHẤT
              </p>
              <p className="mt-1.5 font-serif text-[16px] text-[#173f43]">
                {cls.topStudent}
              </p>
              <p className="text-xs text-[#697472]">
                ĐTB:{" "}
                <span className="font-bold text-[#276e68]">{cls.topGpa}</span>
              </p>
            </div>
          </Card>
        </div>
      </div>
    );
  }

  return (
    <div className="px-9 py-8">
      <PageHeader
        title="Tổng kết kết quả"
        subtitle="Kết quả học tập tổng hợp theo lớp cho Học kỳ I, 2024–2025."
        action={
          <div className="flex gap-2">
            <button className="flex items-center gap-1.5 rounded-lg border border-[#d0ccc3] bg-[#f7f6f1] px-3 py-2.5 text-xs font-semibold text-[#445350] hover:bg-[#ebe9e2]">
              <Icon name="printer" size={14} /> In tổng kết
            </button>
            <button className="flex items-center gap-2 rounded-lg bg-[#173f43] px-4 py-2.5 text-xs font-bold text-white hover:bg-[#24555a]">
              <Icon name="download" size={14} /> Xuất báo cáo
            </button>
          </div>
        }
      />

      <div className="grid grid-cols-4 gap-4 mb-7">
        {[
          ["38%", "Học sinh Giỏi", "474 / 1.248 em", "#276e68"],
          ["42%", "Học sinh Khá", "524 / 1.248 em", "#527b99"],
          ["16%", "Học sinh Đạt", "200 / 1.248 em", "#d3ae54"],
          ["4%", "Chưa đạt", "50 / 1.248 em", "#c87858"],
        ].map(([v, l, h, c]) => (
          <Card key={l} className="p-4">
            <p className="font-serif text-[26px]" style={{ color: c }}>
              {v}
            </p>
            <p className="mt-3 text-xs font-bold text-[#3e5656]">{l}</p>
            <p className="mt-1 text-[11px] text-[#86847b]">{h}</p>
          </Card>
        ))}
      </div>

      <Card>
        <div className="px-5 py-4 border-b border-[#e5e0d7] flex items-center justify-between">
          <h2 className="font-serif text-[20px] text-[#1b4143]">
            Kết quả từng lớp
          </h2>
          <button className="rounded-md border border-[#d0ccc3] px-2.5 py-1.5 text-[11px] text-[#586b68] flex items-center gap-1">
            Khối 10–12 <Icon name="chevron" size={12} />
          </button>
        </div>
        <table className="w-full text-xs">
          <thead className="bg-[#ece9e1] text-[10px] tracking-[.1em] text-[#817c71]">
            <tr>
              <th className="px-5 py-3 font-bold text-left">LỚP</th>
              <th className="px-4 py-3 font-bold text-left">KHỐI</th>
              <th className="px-4 py-3 font-bold text-center">SĨ SỐ</th>
              <th className="px-4 py-3 font-bold text-center">ĐTB LỚP</th>
              <th className="px-4 py-3 font-bold text-center">GIỎI</th>
              <th className="px-4 py-3 font-bold text-center">KHÁ</th>
              <th className="px-4 py-3 font-bold text-center">ĐẠT</th>
              <th className="px-4 py-3 font-bold text-center">CHƯA ĐẠT</th>
              <th className="px-4 py-3 font-bold text-left">
                HỌC SINH XUẤT SẮC
              </th>
              <th />
            </tr>
          </thead>
          <tbody className="divide-y divide-[#e5e0d7]">
            {summaryClasses.map((c, i) => (
              <tr
                key={c.cls}
                className={`hover:bg-[#fbfaf7] cursor-pointer ${i === 0 ? "bg-[#f8f6ef]" : ""}`}
                onClick={() => setSelectedCls(c.cls)}
              >
                <td className="px-5 py-3.5 font-bold text-[#244749]">
                  {c.cls}
                </td>
                <td className="px-4 py-3.5 text-[#62716e]">{c.grade}</td>
                <td className="px-4 py-3.5 text-center">{c.students}</td>
                <td className="px-4 py-3.5 text-center font-bold text-[#173f43]">
                  {c.gpa}
                </td>
                <td className="px-4 py-3.5 text-center text-[#276e68] font-semibold">
                  {c.excellent}
                </td>
                <td className="px-4 py-3.5 text-center text-[#527b99] font-semibold">
                  {c.good}
                </td>
                <td className="px-4 py-3.5 text-center text-[#b8863d] font-semibold">
                  {c.pass}
                </td>
                <td className="px-4 py-3.5 text-center text-[#c87858] font-semibold">
                  {c.fail}
                </td>
                <td className="px-4 py-3.5 text-[#52615e]">
                  {c.topStudent}{" "}
                  <span className="text-[#9a9590]">({c.topGpa})</span>
                </td>
                <td className="px-3 py-3.5 text-[#8d8b82]">
                  <Icon name="arrow" size={15} />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </Card>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 7: BÁO CÁO & THỐNG KÊ
// ─────────────────────────────────────────────────────────────────────────────
function ReportScreen() {
  const [reportTab, setReportTab] = useState("Phân bố điểm");

  const barData = [
    { label: "Toán học", excellent: 35, good: 42, pass: 18, fail: 5 },
    { label: "Ngữ văn", excellent: 32, good: 45, pass: 19, fail: 4 },
    { label: "Vật lý", excellent: 28, good: 38, pass: 26, fail: 8 },
    { label: "Tiếng Anh", excellent: 40, good: 36, pass: 18, fail: 6 },
    { label: "Hóa học", excellent: 25, good: 40, pass: 28, fail: 7 },
    { label: "Sinh học", excellent: 30, good: 44, pass: 22, fail: 4 },
  ];

  const monthlyData = [
    { month: "T9", count: 24 },
    { month: "T10", count: 38 },
    { month: "T11", count: 52 },
    { month: "T12", count: 15 },
  ];

  return (
    <div className="px-9 py-8">
      <PageHeader
        title="Báo cáo & thống kê"
        subtitle="Phân tích học tập toàn trường — Học kỳ I, 2024–2025."
        action={
          <div className="flex gap-2">
            <button className="flex items-center gap-1.5 rounded-lg border border-[#d0ccc3] bg-[#f7f6f1] px-3 py-2.5 text-xs font-semibold text-[#445350] hover:bg-[#ebe9e2]">
              <Icon name="printer" size={14} /> In báo cáo
            </button>
            <button className="flex items-center gap-2 rounded-lg bg-[#173f43] px-4 py-2.5 text-xs font-bold text-white hover:bg-[#24555a]">
              <Icon name="download" size={14} /> Xuất PDF
            </button>
          </div>
        }
      />

      <div className="flex gap-1 border-b border-[#d8d4ca] mb-6">
        {[
          "Phân bố điểm",
          "Tiến độ nhập điểm",
          "So sánh môn học",
          "Danh sách báo cáo",
        ].map((t) => (
          <button
            key={t}
            onClick={() => setReportTab(t)}
            className={`px-4 py-2.5 text-xs font-bold transition border-b-2 -mb-px ${reportTab === t ? "border-[#173f43] text-[#173f43]" : "border-transparent text-[#7a7670] hover:text-[#3a5050]"}`}
          >
            {t}
          </button>
        ))}
      </div>

      {reportTab === "Phân bố điểm" && (
        <>
          <div className="grid grid-cols-4 gap-4 mb-7">
            {[
              ["1.248", "Tổng học sinh", "Khối 10–12"],
              ["8.06", "Điểm TB toàn trường", "Học kỳ I 2024–2025"],
              ["38%", "Tỷ lệ học sinh Giỏi", "474 em xuất sắc"],
              ["4%", "Tỷ lệ chưa đạt", "50 em cần hỗ trợ"],
            ].map(([v, l, h]) => (
              <Card key={l} className="p-4">
                <p className="font-serif text-[26px] text-[#173f43]">{v}</p>
                <p className="mt-3 text-xs font-bold text-[#3e5656]">{l}</p>
                <p className="mt-1 text-[11px] text-[#86847b]">{h}</p>
              </Card>
            ))}
          </div>
          <Card className="p-5 mb-6">
            <div className="flex items-center justify-between mb-6">
              <div>
                <SectionLabel>PHÂN BỐ KẾT QUẢ THEO MÔN</SectionLabel>
                <h2 className="mt-1 font-serif text-[22px] text-[#1b4143]">
                  Biểu đồ xếp loại tất cả môn học
                </h2>
              </div>
              <div className="flex gap-4 text-[11px]">
                {[
                  ["#276e68", "Giỏi"],
                  ["#78a79d", "Khá"],
                  ["#d3ae54", "Đạt"],
                  ["#c87858", "Chưa đạt"],
                ].map(([c, l]) => (
                  <span key={l} className="flex items-center gap-1.5">
                    <span
                      className="h-2.5 w-2.5 rounded-sm inline-block"
                      style={{ backgroundColor: c }}
                    />
                    <span className="text-[#62716e]">{l}</span>
                  </span>
                ))}
              </div>
            </div>
            <div className="space-y-4">
              {barData.map((d) => {
                const total = d.excellent + d.good + d.pass + d.fail;
                return (
                  <div key={d.label} className="flex items-center gap-4">
                    <div className="w-24 text-right text-[11px] font-semibold text-[#52615e] shrink-0">
                      {d.label}
                    </div>
                    <div className="flex-1 flex h-6 rounded-md overflow-hidden">
                      <div
                        className="h-full transition-all"
                        style={{
                          width: `${(d.excellent / total) * 100}%`,
                          backgroundColor: "#276e68",
                        }}
                      />
                      <div
                        className="h-full transition-all"
                        style={{
                          width: `${(d.good / total) * 100}%`,
                          backgroundColor: "#78a79d",
                        }}
                      />
                      <div
                        className="h-full transition-all"
                        style={{
                          width: `${(d.pass / total) * 100}%`,
                          backgroundColor: "#d3ae54",
                        }}
                      />
                      <div
                        className="h-full transition-all"
                        style={{
                          width: `${(d.fail / total) * 100}%`,
                          backgroundColor: "#c87858",
                        }}
                      />
                    </div>
                    <div className="text-[11px] text-[#7a7873] w-28 shrink-0">
                      {d.excellent}% · {d.good}% · {d.pass}% · {d.fail}%
                    </div>
                  </div>
                );
              })}
            </div>
          </Card>
        </>
      )}

      {reportTab === "Tiến độ nhập điểm" && (
        <div className="grid grid-cols-[1fr_320px] gap-6">
          <Card className="p-5">
            <SectionLabel>LƯỢNG BẢNG ĐIỂM ĐÃ HOÀN TẤT THEO THÁNG</SectionLabel>
            <h2 className="mt-1 font-serif text-[22px] text-[#1b4143] mb-6">
              Tiến độ nhập trong học kỳ
            </h2>
            <div className="flex items-end gap-6 h-48">
              {monthlyData.map((d) => (
                <div
                  key={d.month}
                  className="flex-1 flex flex-col items-center gap-2"
                >
                  <span className="text-[11px] font-bold text-[#173f43]">
                    {d.count}
                  </span>
                  <div
                    className="w-full rounded-t"
                    style={{
                      height: `${(d.count / 52) * 100}%`,
                      backgroundColor: "#173f43",
                      minHeight: "4px",
                    }}
                  />
                  <span className="text-[11px] text-[#7a7873]">{d.month}</span>
                </div>
              ))}
            </div>
          </Card>
          <Card className="p-5">
            <SectionLabel>TRẠNG THÁI BẢNG ĐIỂM</SectionLabel>
            <h2 className="mt-1 font-serif text-[22px] text-[#1b4143] mb-5">
              131 bảng điểm
            </h2>
            {[
              ["Đã chốt", "108", "83%", "#276e68"],
              ["Chờ duyệt", "12", "9%", "#527b99"],
              ["Đang nhập", "11", "8%", "#c69c3c"],
            ].map(([l, v, pct, c]) => (
              <div key={l} className="mb-5">
                <div className="flex justify-between text-[11px] mb-1.5">
                  <span className="font-semibold text-[#3e5656]">{l}</span>
                  <span className="text-[#7a7873]">
                    {v} bảng · {pct}
                  </span>
                </div>
                <div className="h-2.5 overflow-hidden rounded-full bg-[#e5e4dd]">
                  <div
                    className="h-full rounded-full"
                    style={{ width: pct, backgroundColor: c }}
                  />
                </div>
              </div>
            ))}
          </Card>
        </div>
      )}

      {reportTab === "So sánh môn học" && (
        <Card className="p-5">
          <SectionLabel>SO SÁNH ĐIỂM TRUNG BÌNH THEO MÔN HỌC</SectionLabel>
          <h2 className="mt-1 font-serif text-[22px] text-[#1b4143] mb-6">
            Xếp hạng môn học
          </h2>
          <div className="space-y-4">
            {[
              ["Tiếng Anh", 8.2],
              ["Toán học", 7.8],
              ["Ngữ văn", 7.6],
              ["Sinh học", 7.4],
              ["Hóa học", 7.1],
              ["Vật lý", 6.9],
            ].map(([sub, avg], i) => (
              <div key={sub as string} className="flex items-center gap-4">
                <span className="w-5 text-right text-[11px] text-[#9a9590] font-mono">
                  {i + 1}
                </span>
                <span className="w-28 text-[11px] font-semibold text-[#3e5656]">
                  {sub}
                </span>
                <div className="flex-1 h-2 overflow-hidden rounded-full bg-[#e5e4dd]">
                  <div
                    className="h-full rounded-full bg-[#173f43]"
                    style={{ width: `${(Number(avg) / 10) * 100}%` }}
                  />
                </div>
                <span className="w-10 text-right text-[11px] font-bold text-[#173f43]">
                  {avg}
                </span>
              </div>
            ))}
          </div>
        </Card>
      )}

      {reportTab === "Danh sách báo cáo" && (
        <div className="space-y-3">
          {[
            {
              name: "Báo cáo tổng kết HK I 2024–2025",
              desc: "Kết quả học tập toàn trường, phân tích theo khối và lớp",
              date: "12/11/2024",
              type: "PDF",
            },
            {
              name: "Danh sách học sinh Giỏi HK I",
              desc: "474 học sinh xếp loại Giỏi — đính kèm điểm chi tiết",
              date: "12/11/2024",
              type: "Excel",
            },
            {
              name: "Báo cáo tiến độ nhập điểm",
              desc: "Trạng thái 131 bảng điểm, tiến độ theo giáo viên",
              date: "11/11/2024",
              type: "PDF",
            },
            {
              name: "Thống kê phân bố điểm theo môn",
              desc: "Biểu đồ và bảng số liệu từng môn học",
              date: "10/11/2024",
              type: "PDF",
            },
            {
              name: "Danh sách học sinh cần hỗ trợ",
              desc: "50 em xếp loại Chưa đạt cần theo dõi đặc biệt",
              date: "10/11/2024",
              type: "Excel",
            },
          ].map((r) => (
            <Card key={r.name} className="flex items-center gap-4 p-4">
              <div
                className={`grid h-10 w-10 shrink-0 place-items-center rounded-lg text-xs font-bold ${r.type === "PDF" ? "bg-[#fbe4dc] text-[#9b4430]" : "bg-[#d5ede5] text-[#256848]"}`}
              >
                {r.type}
              </div>
              <div className="flex-1">
                <p className="text-sm font-semibold text-[#244749]">{r.name}</p>
                <p className="mt-0.5 text-[11px] text-[#7a7873]">
                  {r.desc} · Tạo ngày {r.date}
                </p>
              </div>
              <button className="flex items-center gap-1.5 rounded-lg border border-[#d0ccc3] px-3 py-2 text-xs font-semibold text-[#445350] hover:bg-[#ebe9e2]">
                <Icon name="download" size={13} /> Tải về
              </button>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 8: TRA CỨU HỌC SINH
// ─────────────────────────────────────────────────────────────────────────────
const studentDetail = {
  id: "HS003",
  name: "Lê Bảo Châu",
  cls: "11A3",
  grade: "Khối 11",
  dob: "22/11/2008",
  gender: "Nữ",
  address: "45 Nguyễn Trãi, Q.1, TP.HCM",
  phone: "0901234567",
  gpa: "9.1",
  rank: "Giỏi",
  subjects: [
    {
      name: "Ngữ văn",
      tx1: 9.5,
      tx2: 9.0,
      gk: 9.0,
      ck: 9.5,
      avg: 9.3,
      letter: "G",
    },
    {
      name: "Toán học",
      tx1: 8.5,
      tx2: 9.0,
      gk: 9.0,
      ck: 9.0,
      avg: 9.0,
      letter: "G",
    },
    {
      name: "Vật lý",
      tx1: 9.0,
      tx2: 8.5,
      gk: 8.5,
      ck: 9.0,
      avg: 8.9,
      letter: "G",
    },
    {
      name: "Tiếng Anh",
      tx1: 9.5,
      tx2: 9.0,
      gk: 9.5,
      ck: 9.0,
      avg: 9.2,
      letter: "G",
    },
    {
      name: "Hóa học",
      tx1: 8.0,
      tx2: 8.5,
      gk: 8.0,
      ck: 8.5,
      avg: 8.4,
      letter: "G",
    },
    {
      name: "Sinh học",
      tx1: 8.5,
      tx2: 9.0,
      gk: 8.5,
      ck: 9.0,
      avg: 8.8,
      letter: "G",
    },
  ],
  history: [
    { year: "2023–2024", semester: "HK I", gpa: 8.7, rank: "Giỏi" },
    { year: "2023–2024", semester: "HK II", gpa: 9.0, rank: "Giỏi" },
    { year: "2024–2025", semester: "HK I", gpa: 9.1, rank: "Giỏi" },
  ],
};

function LookupScreen() {
  const [query, setQuery] = useState("");
  const [searched, setSearched] = useState(false);
  const [selectedStudent, setSelectedStudent] = useState<string | null>(null);

  const results = students.filter(
    (s) =>
      s.name.toLowerCase().includes(query.toLowerCase()) ||
      s.id.toLowerCase().includes(query.toLowerCase()) ||
      s.cls.toLowerCase().includes(query.toLowerCase()),
  );

  if (selectedStudent) {
    const s = studentDetail;
    return (
      <div className="px-9 py-8">
        <button
          onClick={() => setSelectedStudent(null)}
          className="flex items-center gap-2 text-xs font-bold text-[#196660] mb-6 hover:text-[#173f43]"
        >
          <Icon name="arrowLeft" size={15} /> Quay lại kết quả tìm kiếm
        </button>
        <div className="grid grid-cols-[280px_1fr] gap-6">
          <div className="space-y-4">
            <Card className="p-5">
              <div className="flex flex-col items-center text-center">
                <div className="grid h-16 w-16 place-items-center rounded-full bg-[#dfe8e2] font-serif text-2xl font-bold text-[#173f43]">
                  {s.name.split(" ").slice(-1)[0][0]}
                </div>
                <h2 className="mt-3 font-serif text-[20px] text-[#173f43]">
                  {s.name}
                </h2>
                <p className="text-xs text-[#697472]">
                  Lớp {s.cls} · {s.grade}
                </p>
                <div className="mt-2">
                  <StatusBadge status={s.rank} />
                </div>
              </div>
              <div className="mt-5 space-y-3 text-[11px]">
                {[
                  ["Mã học sinh", s.id],
                  ["Ngày sinh", s.dob],
                  ["Giới tính", s.gender],
                  ["Địa chỉ", s.address],
                  ["Điện thoại", s.phone],
                ].map(([k, v]) => (
                  <div key={k} className="flex justify-between gap-2">
                    <span className="text-[#9a9590]">{k}</span>
                    <span className="font-semibold text-[#3a5050] text-right">
                      {v}
                    </span>
                  </div>
                ))}
              </div>
            </Card>
            <Card className="p-4">
              <SectionLabel>LỊCH SỬ HỌC TẬP</SectionLabel>
              <div className="mt-3 space-y-2">
                {s.history.map((h) => (
                  <div
                    key={h.semester + h.year}
                    className="flex items-center justify-between"
                  >
                    <div>
                      <p className="text-[11px] font-semibold text-[#3a5050]">
                        {h.semester}
                      </p>
                      <p className="text-[10px] text-[#9a9590]">{h.year}</p>
                    </div>
                    <div className="text-right">
                      <p className="text-[11px] font-bold text-[#173f43]">
                        {h.gpa}
                      </p>
                      <StatusBadge status={h.rank} />
                    </div>
                  </div>
                ))}
              </div>
            </Card>
          </div>
          <div>
            <div className="flex items-center justify-between mb-4">
              <h2 className="font-serif text-[24px] text-[#173f43]">
                Bảng điểm chi tiết
              </h2>
              <button className="flex items-center gap-1.5 rounded-lg border border-[#d0ccc3] bg-[#f7f6f1] px-3 py-2.5 text-xs font-semibold text-[#445350] hover:bg-[#ebe9e2]">
                <Icon name="printer" size={14} /> In học bạ
              </button>
            </div>
            <Card className="mb-4 flex items-center gap-6 p-4">
              <div className="text-center">
                <p className="font-serif text-[32px] text-[#276e68]">{s.gpa}</p>
                <p className="text-[11px] text-[#697472]">Điểm trung bình</p>
              </div>
              <div className="h-10 w-px bg-[#d8d4ca]" />
              <div className="flex-1">
                <div className="h-2 overflow-hidden rounded-full bg-[#e5e4dd] mb-2">
                  <div
                    className="h-full rounded-full bg-[#276e68]"
                    style={{ width: `${(Number(s.gpa) / 10) * 100}%` }}
                  />
                </div>
                <p className="text-[11px] text-[#697472]">
                  Xếp hạng{" "}
                  <span className="font-bold text-[#173f43]">2/40</span> trong
                  lớp {s.cls}
                </p>
              </div>
            </Card>
            <Card>
              <table className="w-full text-xs">
                <thead className="bg-[#ece9e1] text-[10px] tracking-[.1em] text-[#817c71]">
                  <tr>
                    <th className="px-5 py-3 font-bold text-left">MÔN HỌC</th>
                    <th className="px-4 py-3 font-bold text-center">TX1</th>
                    <th className="px-4 py-3 font-bold text-center">TX2</th>
                    <th className="px-4 py-3 font-bold text-center">GIỮA KỲ</th>
                    <th className="px-4 py-3 font-bold text-center">CUỐI KỲ</th>
                    <th className="px-4 py-3 font-bold text-center">ĐIỂM TB</th>
                    <th className="px-4 py-3 font-bold text-center">
                      XẾP LOẠI
                    </th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#e5e0d7]">
                  {s.subjects.map((sub) => (
                    <tr key={sub.name} className="hover:bg-[#fbfaf7]">
                      <td className="px-5 py-3.5 font-semibold text-[#244749]">
                        {sub.name}
                      </td>
                      {[sub.tx1, sub.tx2, sub.gk, sub.ck].map((v, i) => (
                        <td
                          key={i}
                          className="px-4 py-3.5 text-center text-[#52615e]"
                        >
                          {v}
                        </td>
                      ))}
                      <td className="px-4 py-3.5 text-center font-bold text-[#276e68]">
                        {sub.avg}
                      </td>
                      <td className="px-4 py-3.5 text-center">
                        <StatusBadge status="Giỏi" />
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </Card>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="px-9 py-8">
      <PageHeader
        title="Tra cứu học sinh"
        subtitle="Tìm kiếm thông tin học sinh và xem bảng điểm chi tiết."
      />

      <div className="max-w-2xl mx-auto mb-8">
        <div className="relative">
          <span className="absolute left-4 top-1/2 -translate-y-1/2 text-[#9a9590]">
            <Icon name="search" size={18} />
          </span>
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Enter") setSearched(true);
            }}
            placeholder="Nhập tên, mã số học sinh hoặc tên lớp..."
            className="w-full rounded-xl border border-[#d0ccc3] bg-white py-3.5 pl-12 pr-4 text-sm shadow-sm outline-none focus:ring-2 ring-[#aac4bc]"
          />
          <button
            onClick={() => setSearched(true)}
            className="absolute right-2.5 top-1/2 -translate-y-1/2 rounded-lg bg-[#173f43] px-4 py-2 text-xs font-bold text-white hover:bg-[#24555a]"
          >
            Tìm kiếm
          </button>
        </div>
        {!searched && (
          <div className="flex gap-3 mt-3 justify-center">
            {["10A1", "11A3", "12A2", "Lê Bảo", "Nguyễn"].map((hint) => (
              <button
                key={hint}
                onClick={() => {
                  setQuery(hint);
                  setSearched(true);
                }}
                className="rounded-full border border-[#d0ccc3] px-3 py-1 text-[11px] text-[#62716e] hover:bg-[#ebe9e2]"
              >
                {hint}
              </button>
            ))}
          </div>
        )}
      </div>

      {(searched || query) && (
        <>
          <div className="flex items-center justify-between mb-4">
            <p className="text-xs text-[#7a7873]">
              Tìm thấy{" "}
              <span className="font-bold text-[#244749]">{results.length}</span>{" "}
              học sinh khớp với{" "}
              <span className="font-bold">&ldquo;{query}&rdquo;</span>
            </p>
          </div>
          <div className="space-y-2">
            {results.map((s) => (
              <Card
                key={s.id}
                className="flex items-center gap-4 p-4 hover:shadow-md transition cursor-pointer"
                onClick={() => setSelectedStudent(s.id)}
              >
                <div className="grid h-10 w-10 shrink-0 place-items-center rounded-full bg-[#dfe8e2] font-serif text-sm font-bold text-[#173f43]">
                  {s.name.split(" ").slice(-1)[0][0]}
                </div>
                <div className="flex-1">
                  <p className="font-semibold text-[#244749]">{s.name}</p>
                  <p className="mt-0.5 text-[11px] text-[#7a7873]">
                    {s.id} · Lớp {s.cls} · Sinh {s.dob}
                  </p>
                </div>
                <div className="text-right mr-4">
                  <p className="font-bold text-[#173f43]">{s.gpa}</p>
                  <p className="text-[11px] text-[#7a7873]">Điểm TB</p>
                </div>
                <StatusBadge status={s.rank} />
                <Icon name="arrow" size={16} />
              </Card>
            ))}
            {results.length === 0 && (
              <div className="py-16 text-center text-[#9a9590]">
                <Icon name="search" size={32} />
                <p className="mt-3 font-serif text-[18px] text-[#3a5050]">
                  Không tìm thấy kết quả
                </p>
                <p className="mt-1 text-sm">
                  Thử tìm kiếm bằng mã số hoặc tên lớp
                </p>
              </div>
            )}
          </div>
        </>
      )}

      {!searched && !query && (
        <div className="mt-4">
          <SectionLabel>TÌM KIẾM GẦN ĐÂY</SectionLabel>
          <div className="mt-3 space-y-2">
            {students.slice(0, 4).map((s) => (
              <Card
                key={s.id}
                className="flex items-center gap-4 p-4 hover:shadow-md transition cursor-pointer"
                onClick={() => setSelectedStudent(s.id)}
              >
                <div className="grid h-9 w-9 shrink-0 place-items-center rounded-full bg-[#dfe8e2] font-serif text-sm font-bold text-[#173f43]">
                  {s.name.split(" ").slice(-1)[0][0]}
                </div>
                <div className="flex-1">
                  <p className="font-semibold text-[#244749] text-sm">
                    {s.name}
                  </p>
                  <p className="mt-0.5 text-[11px] text-[#7a7873]">
                    {s.id} · Lớp {s.cls}
                  </p>
                </div>
                <StatusBadge status={s.rank} />
                <Icon name="arrow" size={15} />
              </Card>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 9: QUẢN LÝ TÀI KHOẢN
// ─────────────────────────────────────────────────────────────────────────────
const accounts = [
  {
    id: "ACC001",
    name: "Lan Nguyễn",
    email: "lan.nguyen@truong.edu.vn",
    role: "Quản trị",
    lastLogin: "12/11/2024 09:15",
    status: "Hoạt động",
  },
  {
    id: "ACC002",
    name: "Nguyễn Hoàng Phúc",
    email: "phuc.nguyen@truong.edu.vn",
    role: "Giáo viên",
    lastLogin: "12/11/2024 08:42",
    status: "Hoạt động",
  },
  {
    id: "ACC003",
    name: "Trần Minh Anh",
    email: "anh.tran@truong.edu.vn",
    role: "Giáo viên",
    lastLogin: "11/11/2024 16:20",
    status: "Hoạt động",
  },
  {
    id: "ACC004",
    name: "Lê Quốc Bảo",
    email: "bao.le@truong.edu.vn",
    role: "Giáo viên",
    lastLogin: "09/11/2024 14:10",
    status: "Hoạt động",
  },
  {
    id: "ACC005",
    name: "Phạm Thu Hà",
    email: "ha.pham@truong.edu.vn",
    role: "Giáo viên",
    lastLogin: "12/11/2024 10:05",
    status: "Hoạt động",
  },
  {
    id: "ACC006",
    name: "Đinh Văn Thắng",
    email: "thang.dinh@truong.edu.vn",
    role: "Giáo viên",
    lastLogin: "05/11/2024 08:00",
    status: "Khóa",
  },
  {
    id: "ACC007",
    name: "Cao Thị Mỹ Linh",
    email: "linh.cao@truong.edu.vn",
    role: "Giáo viên",
    lastLogin: "10/11/2024 13:30",
    status: "Hoạt động",
  },
];

function AccountScreen() {
  const [accTab, setAccTab] = useState("Tài khoản");

  return (
    <div className="px-9 py-8">
      <PageHeader
        title="Tài khoản & xác thực"
        subtitle="Quản lý quyền truy cập, vai trò và bảo mật hệ thống."
        action={
          <button className="flex items-center gap-2 rounded-lg bg-[#173f43] px-4 py-2.5 text-xs font-bold text-[#f8f6ef] shadow-[0_4px_10px_rgba(22,59,63,.15)] hover:bg-[#24555a] transition">
            <Icon name="plus" size={15} /> Tạo tài khoản
          </button>
        }
      />

      <div className="flex gap-1 border-b border-[#d8d4ca] mb-6">
        {["Tài khoản", "Vai trò & quyền", "Nhật ký đăng nhập"].map((t) => (
          <button
            key={t}
            onClick={() => setAccTab(t)}
            className={`px-4 py-2.5 text-xs font-bold transition border-b-2 -mb-px ${accTab === t ? "border-[#173f43] text-[#173f43]" : "border-transparent text-[#7a7670] hover:text-[#3a5050]"}`}
          >
            {t}
          </button>
        ))}
      </div>

      {accTab === "Tài khoản" && (
        <>
          <div className="grid grid-cols-3 gap-4 mb-6">
            {[
              ["7", "Tổng tài khoản", "6 hoạt động · 1 khóa", "#dfe8e2"],
              ["2", "Phiên đăng nhập", "Đang hoạt động", "#f2e8cb"],
              ["0", "Cảnh báo bảo mật", "Không có vấn đề", "#dfe8e2"],
            ].map(([v, l, h, c]) => (
              <Card key={l} className="p-4">
                <p className="font-serif text-[26px] text-[#173f43]">{v}</p>
                <p className="mt-3 text-xs font-bold text-[#3e5656]">{l}</p>
                <p className="mt-1 text-[11px] text-[#86847b]">{h}</p>
              </Card>
            ))}
          </div>
          <Card>
            <table className="w-full text-xs">
              <thead className="bg-[#ece9e1] text-[10px] tracking-[.1em] text-[#817c71]">
                <tr>
                  <th className="px-5 py-3 font-bold text-left">TÊN</th>
                  <th className="px-4 py-3 font-bold">EMAIL</th>
                  <th className="px-4 py-3 font-bold">VAI TRÒ</th>
                  <th className="px-4 py-3 font-bold">ĐĂNG NHẬP CUỐI</th>
                  <th className="px-4 py-3 font-bold">TRẠNG THÁI</th>
                  <th className="px-4 py-3 font-bold">THAO TÁC</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#e5e0d7]">
                {accounts.map((a) => (
                  <tr key={a.id} className="hover:bg-[#fbfaf7]">
                    <td className="px-5 py-3.5">
                      <div className="flex items-center gap-2.5">
                        <div className="grid h-7 w-7 place-items-center rounded-full bg-[#c3d4cd] font-serif text-xs font-bold text-[#23464a]">
                          {a.name.split(" ").slice(-1)[0][0]}
                        </div>
                        <span className="font-semibold text-[#244749]">
                          {a.name}
                        </span>
                      </div>
                    </td>
                    <td className="px-4 py-3.5 text-[#62716e]">{a.email}</td>
                    <td className="px-4 py-3.5">
                      <StatusBadge status={a.role} />
                    </td>
                    <td className="px-4 py-3.5 text-[#62716e]">
                      {a.lastLogin}
                    </td>
                    <td className="px-4 py-3.5">
                      <StatusBadge status={a.status} />
                    </td>
                    <td className="px-4 py-3.5">
                      <div className="flex gap-2">
                        <button className="text-[#62716e] hover:text-[#173f43]">
                          <Icon name="edit" size={14} />
                        </button>
                        <button className="text-[#62716e] hover:text-[#173f43]">
                          <Icon name="lock" size={14} />
                        </button>
                        <button className="text-[#62716e] hover:text-[#b34040]">
                          <Icon name="trash" size={14} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </Card>
        </>
      )}

      {accTab === "Vai trò & quyền" && (
        <div className="grid grid-cols-3 gap-4">
          {[
            {
              role: "Quản trị",
              desc: "Toàn quyền hệ thống",
              users: 1,
              perms: [
                "Quản lý tài khoản",
                "Quản lý danh mục",
                "Tạo/xóa bảng điểm",
                "Phê duyệt điểm",
                "Xem tất cả báo cáo",
                "Cài đặt hệ thống",
              ],
            },
            {
              role: "Giáo viên",
              desc: "Nhập và quản lý điểm",
              users: 6,
              perms: [
                "Nhập điểm lớp phụ trách",
                "Xem bảng điểm của mình",
                "Tải lên ảnh OCR",
                "Xem báo cáo lớp mình",
                "Tra cứu học sinh lớp mình",
              ],
            },
            {
              role: "Học sinh",
              desc: "Chỉ tra cứu điểm cá nhân",
              users: 1248,
              perms: [
                "Xem điểm cá nhân",
                "Xem lịch sử học tập",
                "Xem xếp hạng lớp",
              ],
            },
          ].map((r) => (
            <Card key={r.role} className="p-5">
              <div className="flex items-start justify-between mb-4">
                <div>
                  <StatusBadge status={r.role} />
                  <p className="mt-2 font-serif text-[18px] text-[#173f43]">
                    {r.role}
                  </p>
                  <p className="text-[11px] text-[#7a7873]">
                    {r.desc} · {r.users} người dùng
                  </p>
                </div>
                <button className="text-[#7a7873] hover:text-[#173f43]">
                  <Icon name="edit" size={15} />
                </button>
              </div>
              <div className="space-y-1.5">
                {r.perms.map((p) => (
                  <div
                    key={p}
                    className="flex items-center gap-2 text-[11px] text-[#52615e]"
                  >
                    <span className="text-[#4a9e6a]">
                      <Icon name="checkCircle" size={13} />
                    </span>
                    {p}
                  </div>
                ))}
              </div>
            </Card>
          ))}
        </div>
      )}

      {accTab === "Nhật ký đăng nhập" && (
        <Card>
          <table className="w-full text-xs">
            <thead className="bg-[#ece9e1] text-[10px] tracking-[.1em] text-[#817c71]">
              <tr>
                <th className="px-5 py-3 font-bold text-left">THỜI GIAN</th>
                <th className="px-4 py-3 font-bold">NGƯỜI DÙNG</th>
                <th className="px-4 py-3 font-bold">HÀNH ĐỘNG</th>
                <th className="px-4 py-3 font-bold">ĐỊA CHỈ IP</th>
                <th className="px-4 py-3 font-bold">TRẠNG THÁI</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#e5e0d7]">
              {[
                [
                  "12/11/2024 10:05",
                  "Phạm Thu Hà",
                  "Đăng nhập",
                  "192.168.1.25",
                  "Hoạt động",
                ],
                [
                  "12/11/2024 09:42",
                  "Phạm Thu Hà",
                  "Nhập điểm 10A4",
                  "192.168.1.25",
                  "Hoạt động",
                ],
                [
                  "12/11/2024 09:15",
                  "Lan Nguyễn",
                  "Đăng nhập",
                  "192.168.1.10",
                  "Hoạt động",
                ],
                [
                  "12/11/2024 08:42",
                  "Nguyễn Hoàng Phúc",
                  "Đăng nhập",
                  "192.168.1.18",
                  "Hoạt động",
                ],
                [
                  "11/11/2024 16:20",
                  "Trần Minh Anh",
                  "Chốt bảng điểm 11A3",
                  "192.168.1.22",
                  "Hoạt động",
                ],
                [
                  "11/11/2024 15:30",
                  "Đinh Văn Thắng",
                  "Đăng nhập thất bại",
                  "10.0.0.5",
                  "Khóa",
                ],
              ].map(([time, user, action, ip, status]) => (
                <tr
                  key={time + user}
                  className={`hover:bg-[#fbfaf7] ${status === "Khóa" ? "bg-[#fff8f5]" : ""}`}
                >
                  <td className="px-5 py-3.5 font-mono text-[11px] text-[#7a7873]">
                    {time}
                  </td>
                  <td className="px-4 py-3.5 font-semibold text-[#244749]">
                    {user}
                  </td>
                  <td className="px-4 py-3.5 text-[#52615e]">{action}</td>
                  <td className="px-4 py-3.5 font-mono text-[11px] text-[#7a7873]">
                    {ip}
                  </td>
                  <td className="px-4 py-3.5">
                    <StatusBadge status={status} />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </Card>
      )}
    </div>
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// TEACHER INTERFACE
// ═════════════════════════════════════════════════════════════════════════════

const teacherInfo = {
  name: "Phạm Thu Hà",
  initials: "TH",
  subject: "Tiếng Anh",
  classes: ["10A4", "11B1"],
  avatar: "#c3cfd4",
};
const teacherNavItems = [
  { label: "Tổng quan", icon: "grid" as IconName },
  { label: "Bảng điểm của tôi", icon: "score" as IconName },
  { label: "Nhập điểm", icon: "edit" as IconName, badge: "Mới" },
  { label: "Xem lại OCR", icon: "scan" as IconName, count: "1" },
  { label: "Kết quả lớp", icon: "chart" as IconName },
];

// ── Teacher Dashboard ────────────────────────────────────────────────────────
function TeacherDashboard({ onNavigate }: { onNavigate: (s: string) => void }) {
  const myPendingSheets = allSheets.filter(
    (s) => s.teacher === teacherInfo.name && s.status === "Đang nhập",
  );
  return (
    <div className="px-8 py-8">
      <div className="mb-8">
        <p className="text-[11px] font-bold tracking-[.18em] text-[#ad8840]">
          THỨ BA, 12 THÁNG 11, 2024
        </p>
        <h1 className="mt-2 font-serif text-[34px] leading-none tracking-tight text-[#173f43]">
          Xin chào, cô {teacherInfo.name.split(" ").slice(-1)[0]}.
        </h1>
        <p className="mt-2.5 text-sm text-[#697472]">
          Môn Tiếng Anh — Lớp {teacherInfo.classes.join(", ")} · Học kỳ I,
          2024–2025
        </p>
      </div>

      {/* Quick stats */}
      <div className="grid grid-cols-3 gap-4 mb-7">
        {[
          { v: "2", l: "Bảng điểm đang nhập", h: "10A4 · 11B1", c: "#f5e8c9" },
          {
            v: "68",
            l: "Học sinh đã có điểm",
            h: "trên 76 tổng số",
            c: "#dfe8e2",
          },
          {
            v: "1",
            l: "Ảnh OCR chờ xác nhận",
            h: "Toán 10A4 · 09:14",
            c: "#fbe4dc",
          },
        ].map(({ v, l, h, c }) => (
          <Card key={l} className="p-5">
            <p className="font-serif text-[32px] leading-none text-[#173f43]">
              {v}
            </p>
            <p className="mt-3.5 text-xs font-bold text-[#3e5656]">{l}</p>
            <p className="mt-1 text-[11px] text-[#86847b]">{h}</p>
            <div
              className="mt-3 h-1 w-full rounded-full"
              style={{ backgroundColor: c }}
            />
          </Card>
        ))}
      </div>

      {/* My sheets */}
      <div className="grid grid-cols-[1fr_280px] gap-6 mb-6">
        <Card className="p-5">
          <div className="flex items-center justify-between mb-4">
            <div>
              <SectionLabel>BẢNG ĐIỂM CỦA TÔI</SectionLabel>
              <h2 className="mt-1 font-serif text-[20px] text-[#1b4143]">
                Tiến độ nhập điểm
              </h2>
            </div>
            <button
              onClick={() => onNavigate("Bảng điểm của tôi")}
              className="flex items-center gap-1 text-xs font-bold text-[#196660]"
            >
              Xem tất cả <Icon name="arrow" size={14} />
            </button>
          </div>
          <div className="space-y-3">
            {allSheets
              .filter((s) => s.teacher === teacherInfo.name)
              .map((s) => (
                <div
                  key={s.id}
                  className="flex items-center gap-4 rounded-xl border border-[#e5e0d7] bg-[#faf9f5] px-4 py-3"
                >
                  <div className="grid h-10 w-10 shrink-0 place-items-center rounded-lg bg-[#173f43]/10 font-serif text-sm font-bold text-[#173f43]">
                    {s.cls}
                  </div>
                  <div className="flex-1">
                    <div className="flex items-center justify-between mb-1.5">
                      <span className="text-sm font-semibold text-[#244749]">
                        {s.subject} — {s.cls}
                      </span>
                      <StatusBadge status={s.status} />
                    </div>
                    <div className="flex items-center gap-2">
                      <div className="flex-1 h-1.5 overflow-hidden rounded-full bg-[#dedbd2]">
                        <div
                          className="h-full rounded-full bg-[#4a8a68]"
                          style={{ width: `${s.progress}%` }}
                        />
                      </div>
                      <span className="text-[11px] text-[#7a7873] shrink-0">
                        {s.filled}/{s.total} học sinh
                      </span>
                    </div>
                  </div>
                  {s.status === "Đang nhập" && (
                    <button
                      onClick={() => onNavigate("Nhập điểm")}
                      className="shrink-0 rounded-lg bg-[#173f43] px-3 py-1.5 text-[11px] font-bold text-white hover:bg-[#24555a]"
                    >
                      Nhập
                    </button>
                  )}
                </div>
              ))}
          </div>
        </Card>

        <div className="space-y-4">
          {/* OCR alert */}
          <div className="rounded-xl border border-[#e8c96d] bg-[#fdfbef] p-4">
            <div className="flex items-start gap-2 mb-3">
              <span className="text-[#9a7222] mt-0.5">
                <Icon name="alertTriangle" size={15} />
              </span>
              <div>
                <p className="text-xs font-bold text-[#9a7222]">
                  1 ảnh OCR cần xác nhận
                </p>
                <p className="mt-0.5 text-[11px] text-[#7a6030] leading-4">
                  Tiếng Anh 10A4 · 5 ô cần xem lại trước khi áp dụng
                </p>
              </div>
            </div>
            <button
              onClick={() => onNavigate("Xem lại OCR")}
              className="w-full rounded-lg bg-[#c69c3c] py-2 text-[11px] font-bold text-white hover:bg-[#a07c2a]"
            >
              Xem lại & xác nhận ngay
            </button>
          </div>

          {/* Deadline */}
          <Card className="p-4">
            <SectionLabel>THỜI HẠN NỘP ĐIỂM</SectionLabel>
            <p className="mt-2 font-serif text-[18px] text-[#173f43]">
              30 tháng 11, 2024
            </p>
            <p className="mt-1 text-[11px] text-[#7a7873]">
              Còn 18 ngày · Học kỳ I 2024–2025
            </p>
            <div className="mt-3 h-1.5 overflow-hidden rounded-full bg-[#d7d4cc]">
              <div className="h-full w-[68%] rounded-full bg-[#c69c3c]" />
            </div>
            <p className="mt-2 text-[10px] text-[#9a9590]">
              68% thời gian đã trôi qua
            </p>
          </Card>

          {/* Today activity */}
          <Card className="p-4">
            <SectionLabel>HOẠT ĐỘNG HÔM NAY</SectionLabel>
            <div className="mt-3 space-y-2.5">
              {[
                ["09:42", "Nhập điểm Tiếng Anh 10A4 (4 em)"],
                ["09:12", "Tải lên ảnh phiếu điểm 10A4"],
                ["08:30", "Đăng nhập hệ thống"],
              ].map(([t, d]) => (
                <div key={t} className="flex gap-2.5">
                  <span className="mt-1 h-1.5 w-1.5 shrink-0 rounded-full bg-[#c69c3c]" />
                  <p className="text-[11px] leading-4 text-[#5c6965]">
                    <b className="text-[#9a9386]">{t}</b> {d}
                  </p>
                </div>
              ))}
            </div>
          </Card>
        </div>
      </div>
    </div>
  );
}

// ── Teacher: Bảng điểm của tôi ───────────────────────────────────────────────
function TeacherMySheets({ onNavigate }: { onNavigate: (s: string) => void }) {
  const mySheetsList = allSheets.filter((s) => s.teacher === teacherInfo.name);
  return (
    <div className="px-8 py-8">
      <PageHeader
        title="Bảng điểm của tôi"
        subtitle={`Môn ${teacherInfo.subject} — Lớp ${teacherInfo.classes.join(", ")} · Học kỳ I, 2024–2025`}
        action={
          <button
            onClick={() => onNavigate("Nhập điểm")}
            className="flex items-center gap-2 rounded-lg bg-[#173f43] px-4 py-2.5 text-xs font-bold text-white shadow-[0_4px_10px_rgba(22,59,63,.15)] hover:bg-[#24555a]"
          >
            <Icon name="edit" size={15} /> Nhập điểm
          </button>
        }
      />
      <div className="space-y-3">
        {mySheetsList.map((s) => (
          <Card key={s.id} className="p-5">
            <div className="flex items-start gap-5">
              <div className="grid h-14 w-14 shrink-0 place-items-center rounded-xl bg-[#173f43]/8">
                <span className="font-serif text-[20px] font-bold text-[#173f43]">
                  {s.cls}
                </span>
              </div>
              <div className="flex-1">
                <div className="flex items-start justify-between">
                  <div>
                    <p className="font-semibold text-[#244749]">
                      {s.subject} — Lớp {s.cls}
                    </p>
                    <p className="mt-0.5 text-[11px] text-[#7a7873]">
                      {s.semester} {s.year} · Cập nhật {s.updated}
                    </p>
                  </div>
                  <StatusBadge status={s.status} />
                </div>
                <div className="mt-3 flex items-center gap-4">
                  <div className="flex-1">
                    <div className="flex justify-between text-[11px] mb-1">
                      <span className="text-[#7a7873]">Tiến độ nhập điểm</span>
                      <span className="font-semibold text-[#3a5050]">
                        {s.filled}/{s.total} học sinh · {s.progress}%
                      </span>
                    </div>
                    <div className="h-2 overflow-hidden rounded-full bg-[#dedbd2]">
                      <div
                        className="h-full rounded-full bg-[#4a8a68]"
                        style={{ width: `${s.progress}%` }}
                      />
                    </div>
                  </div>
                  <div className="flex gap-2 shrink-0">
                    {s.status === "Đang nhập" && (
                      <>
                        <button
                          onClick={() => onNavigate("Nhập điểm")}
                          className="flex items-center gap-1.5 rounded-lg border border-[#d0ccc3] px-3 py-2 text-xs font-semibold text-[#445350] hover:bg-[#ebe9e2]"
                        >
                          <Icon name="edit" size={13} /> Nhập thủ công
                        </button>
                        <button
                          onClick={() => onNavigate("Nhập điểm")}
                          className="flex items-center gap-1.5 rounded-lg bg-[#173f43] px-3 py-2 text-xs font-bold text-white hover:bg-[#24555a]"
                        >
                          <Icon name="image" size={13} /> Nhập từ ảnh
                        </button>
                      </>
                    )}
                    {s.status === "Chờ duyệt" && (
                      <button className="flex items-center gap-1.5 rounded-lg border border-[#d0ccc3] px-3 py-2 text-xs font-semibold text-[#445350] hover:bg-[#ebe9e2]">
                        <Icon name="eye" size={13} /> Xem
                      </button>
                    )}
                    {s.status === "Đã chốt" && (
                      <button className="flex items-center gap-1.5 rounded-lg border border-[#d0ccc3] px-3 py-2 text-xs font-semibold text-[#445350] hover:bg-[#ebe9e2]">
                        <Icon name="printer" size={13} /> In bảng điểm
                      </button>
                    )}
                  </div>
                </div>
              </div>
            </div>
          </Card>
        ))}
      </div>
    </div>
  );
}

// ── Teacher: Nhập điểm (chọn phương thức) ───────────────────────────────────
function TeacherGradeEntry() {
  const [method, setMethod] = useState<"choose" | "manual" | "ocr">("choose");
  const [selectedSid, setSelectedSid] = useState("BD004");
  const sheet = allSheets.find((s) => s.id === selectedSid)!;

  if (method === "ocr") return <OcrScreen />;

  if (method === "manual") {
    return (
      <div className="px-8 py-8">
        <div className="flex items-center gap-4 mb-6">
          <button
            onClick={() => setMethod("choose")}
            className="flex items-center gap-2 text-xs font-bold text-[#196660] hover:text-[#173f43]"
          >
            <Icon name="arrowLeft" size={15} /> Chọn lại
          </button>
          <span className="text-[#c5c0b9]">/</span>
          <span className="text-xs font-semibold text-[#355658]">
            Nhập thủ công — {sheet.subject} {sheet.cls}
          </span>
        </div>
        <div className="flex items-start justify-between mb-6">
          <div>
            <p className="text-[10px] font-bold tracking-[.16em] text-[#ad8840]">
              NHẬP ĐIỂM THỦ CÔNG · {sheet.semester} {sheet.year}
            </p>
            <h1 className="mt-2 font-serif text-[30px] leading-none tracking-tight text-[#173f43]">
              {sheet.subject} — Lớp {sheet.cls}
            </h1>
          </div>
          <div className="flex gap-2">
            <button className="flex items-center gap-1.5 rounded-lg border border-[#d0ccc3] bg-[#f7f6f1] px-3 py-2.5 text-xs font-semibold text-[#445350] hover:bg-[#ebe9e2]">
              <Icon name="download" size={14} /> Tải mẫu Excel
            </button>
            <button className="flex items-center gap-2 rounded-lg bg-[#173f43] px-4 py-2.5 text-xs font-bold text-white hover:bg-[#24555a]">
              <Icon name="check" size={14} /> Lưu & chốt
            </button>
          </div>
        </div>
        <Card className="overflow-hidden">
          <table className="w-full text-xs">
            <thead className="bg-[#ece9e1] text-[10px] tracking-[.1em] text-[#817c71]">
              <tr>
                <th className="px-4 py-3 font-bold text-left">STT</th>
                <th className="px-4 py-3 font-bold text-left">HỌ VÀ TÊN</th>
                <th className="px-3 py-3 font-bold text-center">MÃ HS</th>
                <th className="px-3 py-3 font-bold text-center">TX1</th>
                <th className="px-3 py-3 font-bold text-center">TX2</th>
                <th className="px-3 py-3 font-bold text-center">GIỮA KỲ</th>
                <th className="px-3 py-3 font-bold text-center">CUỐI KỲ</th>
                <th className="px-3 py-3 font-bold text-center">ĐIỂM TB</th>
                <th className="px-3 py-3 font-bold text-center">XẾP LOẠI</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#e5e0d7]">
              {sheetStudents.map((s) => (
                <tr key={s.id} className="hover:bg-[#fbfaf7]">
                  <td className="px-4 py-3 text-[#908c84]">{s.rank}</td>
                  <td className="px-4 py-3 font-semibold text-[#244749]">
                    {s.name}
                  </td>
                  <td className="px-3 py-3 text-center font-mono text-[10px] text-[#7a7873]">
                    {s.id}
                  </td>
                  {[s.tx1, s.tx2, s.gk, s.ck].map((v, i) => (
                    <td key={i} className="px-3 py-2.5 text-center">
                      <input
                        defaultValue={v}
                        className="w-14 rounded border border-[#d0ccc3] py-1.5 text-center text-xs font-bold outline-none focus:ring-2 ring-[#aac4bc] bg-white text-[#173f43]"
                      />
                    </td>
                  ))}
                  <td className="px-3 py-3 text-center font-bold text-[#173f43]">
                    {s.avg}
                  </td>
                  <td className="px-3 py-3 text-center">
                    <span
                      className={`inline-block rounded-full px-2 py-0.5 text-[10px] font-bold ${s.letter === "G" ? "bg-[#d4f0e4] text-[#1e6645]" : s.letter === "K" ? "bg-[#dbe7f1] text-[#3c6685]" : s.letter === "Đ" ? "bg-[#f5e8c9] text-[#9a7222]" : "bg-[#fbe4dc] text-[#9b4430]"}`}
                    >
                      {s.letter}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </Card>
      </div>
    );
  }

  // Method chooser
  return (
    <div className="px-8 py-8">
      <PageHeader
        title="Nhập điểm"
        subtitle="Chọn bảng điểm và phương thức nhập liệu."
      />

      {/* Sheet selector */}
      <div className="mb-7">
        <SectionLabel>CHỌN BẢNG ĐIỂM</SectionLabel>
        <div className="mt-3 flex gap-3 flex-wrap">
          {allSheets
            .filter(
              (s) => s.teacher === teacherInfo.name && s.status === "Đang nhập",
            )
            .map((s) => (
              <button
                key={s.id}
                onClick={() => setSelectedSid(s.id)}
                className={`flex items-center gap-2.5 rounded-xl border-2 px-4 py-3 text-left transition ${selectedSid === s.id ? "border-[#173f43] bg-[#dfe8e2]" : "border-[#d8d4ca] bg-[#f7f6f1] hover:border-[#8aafa8]"}`}
              >
                <span
                  className={`font-serif text-[15px] font-bold ${selectedSid === s.id ? "text-[#173f43]" : "text-[#3a5050]"}`}
                >
                  {s.cls}
                </span>
                <div>
                  <p
                    className={`text-xs font-semibold ${selectedSid === s.id ? "text-[#173f43]" : "text-[#3a5050]"}`}
                  >
                    {s.subject}
                  </p>
                  <p className="text-[10px] text-[#9a9590]">
                    {s.filled}/{s.total} em đã có điểm
                  </p>
                </div>
              </button>
            ))}
        </div>
      </div>

      {/* Method cards */}
      <SectionLabel>CHỌN PHƯƠNG THỨC NHẬP</SectionLabel>
      <div className="mt-3 grid grid-cols-2 gap-5">
        <button
          onClick={() => setMethod("manual")}
          className="group flex flex-col items-start gap-4 rounded-2xl border-2 border-[#d8d4ca] bg-[#f7f6f1] p-6 text-left hover:border-[#173f43] hover:bg-[#f0ede6] transition-all"
        >
          <div className="grid h-12 w-12 place-items-center rounded-xl bg-[#173f43]/10 text-[#173f43] group-hover:bg-[#173f43]/16">
            <Icon name="edit" size={22} stroke={1.6} />
          </div>
          <div>
            <p className="font-serif text-[20px] text-[#173f43]">
              Nhập thủ công
            </p>
            <p className="mt-1.5 text-[12px] leading-5 text-[#697472]">
              Điền từng ô điểm trực tiếp vào bảng. Phù hợp khi bạn có danh sách
              điểm sẵn trên giấy hoặc Excel.
            </p>
          </div>
          <div className="flex flex-wrap gap-2 text-[10px]">
            {["Nhập trực tiếp", "Kiểm tra ngay", "Tính TB tự động"].map((t) => (
              <span
                key={t}
                className="rounded-full border border-[#d0ccc3] px-2.5 py-1 text-[#5a6e6b]"
              >
                {t}
              </span>
            ))}
          </div>
          <span className="flex items-center gap-1 text-xs font-bold text-[#196660] group-hover:gap-2 transition-all">
            Bắt đầu nhập <Icon name="arrow" size={14} />
          </span>
        </button>

        <button
          onClick={() => setMethod("ocr")}
          className="group flex flex-col items-start gap-4 rounded-2xl border-2 border-[#d8d4ca] bg-[#f7f6f1] p-6 text-left hover:border-[#173f43] hover:bg-[#f0ede6] transition-all"
        >
          <div className="grid h-12 w-12 place-items-center rounded-xl bg-[#173f43]/10 text-[#173f43] group-hover:bg-[#173f43]/16">
            <Icon name="image" size={22} stroke={1.6} />
          </div>
          <div>
            <p className="font-serif text-[20px] text-[#173f43]">
              Nhập từ ảnh chụp
            </p>
            <p className="mt-1.5 text-[12px] leading-5 text-[#697472]">
              Chụp ảnh phiếu điểm giấy, hệ thống OCR nhận dạng tự động qua 2
              kênh song song và điền vào bảng.
            </p>
          </div>
          <div className="flex flex-wrap gap-2 text-[10px]">
            {["OCR 2 kênh", "Phân loại Xanh/Vàng/Đỏ", "Bạn xác nhận cuối"].map(
              (t) => (
                <span
                  key={t}
                  className="rounded-full border border-[#d0ccc3] px-2.5 py-1 text-[#5a6e6b]"
                >
                  {t}
                </span>
              ),
            )}
          </div>
          <div className="flex items-center gap-2">
            <span className="flex items-center gap-1 text-xs font-bold text-[#196660] group-hover:gap-2 transition-all">
              Tải ảnh lên <Icon name="arrow" size={14} />
            </span>
            <span className="rounded bg-[#e8c96d] px-1.5 py-0.5 text-[9px] font-bold text-[#5b4a18]">
              Nhanh hơn
            </span>
          </div>
        </button>
      </div>

      {/* Sheet preview */}
      {sheet && (
        <div className="mt-7">
          <SectionLabel>
            XEM TRƯỚC — {sheet.subject.toUpperCase()} {sheet.cls}
          </SectionLabel>
          <Card className="mt-3 overflow-hidden">
            <table className="w-full text-xs">
              <thead className="bg-[#ece9e1] text-[10px] tracking-[.1em] text-[#817c71]">
                <tr>
                  <th className="px-5 py-3 font-bold text-left">HỌ VÀ TÊN</th>
                  <th className="px-4 py-3 font-bold text-center">TX1</th>
                  <th className="px-4 py-3 font-bold text-center">TX2</th>
                  <th className="px-4 py-3 font-bold text-center">GK</th>
                  <th className="px-4 py-3 font-bold text-center">CK</th>
                  <th className="px-4 py-3 font-bold text-center">TB</th>
                  <th className="px-4 py-3 font-bold text-center">
                    TRẠNG THÁI
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#e5e0d7]">
                {sheetStudents.slice(0, 4).map((s, i) => (
                  <tr key={s.id} className="hover:bg-[#fbfaf7]">
                    <td className="px-5 py-3 font-semibold text-[#244749]">
                      {s.name}
                    </td>
                    {[s.tx1, s.tx2, s.gk, s.ck].map((v, j) => (
                      <td
                        key={j}
                        className="px-4 py-3 text-center text-[#52615e]"
                      >
                        {i < 2 ? v : <span className="text-[#c5c0b9]">—</span>}
                      </td>
                    ))}
                    <td className="px-4 py-3 text-center font-bold text-[#173f43]">
                      {i < 2 ? (
                        s.avg
                      ) : (
                        <span className="text-[#c5c0b9]">—</span>
                      )}
                    </td>
                    <td className="px-4 py-3 text-center">
                      {i < 2 ? (
                        <StatusBadge
                          status={
                            s.letter === "G"
                              ? "Giỏi"
                              : s.letter === "K"
                                ? "Khá"
                                : "Đạt"
                          }
                        />
                      ) : (
                        <span className="text-[11px] text-[#c5c0b9]">
                          Chưa nhập
                        </span>
                      )}
                    </td>
                  </tr>
                ))}
                <tr className="bg-[#f4f2ec]">
                  <td
                    colSpan={7}
                    className="px-5 py-2.5 text-[11px] text-center text-[#9a9590]"
                  >
                    ... và {sheet.total - 4} học sinh khác chưa hiển thị
                  </td>
                </tr>
              </tbody>
            </table>
          </Card>
        </div>
      )}
    </div>
  );
}

// ── Teacher: Kết quả lớp học ─────────────────────────────────────────────────
function TeacherResults() {
  const [selectedCls, setSelectedCls] = useState<string | null>(null);
  const myCls = summaryClasses.filter((c) =>
    teacherInfo.classes.includes(c.cls),
  );

  if (selectedCls) {
    const cls = summaryClasses.find((c) => c.cls === selectedCls)!;
    return (
      <div className="px-8 py-8">
        <button
          onClick={() => setSelectedCls(null)}
          className="flex items-center gap-2 text-xs font-bold text-[#196660] mb-6 hover:text-[#173f43]"
        >
          <Icon name="arrowLeft" size={15} /> Quay lại
        </button>
        <p className="text-[10px] font-bold tracking-[.16em] text-[#ad8840]">
          KẾT QUẢ {teacherInfo.subject.toUpperCase()} · HK I 2024–2025
        </p>
        <h1 className="mt-2 font-serif text-[30px] leading-none tracking-tight text-[#173f43] mb-6">
          Lớp {cls.cls}
        </h1>
        <div className="grid grid-cols-4 gap-4 mb-6">
          {[
            ["Giỏi", cls.excellent, "#d4f0e4", "#1e6645"],
            ["Khá", cls.good, "#dbe7f1", "#3c6685"],
            ["Đạt", cls.pass, "#f5e8c9", "#9a7222"],
            ["Chưa đạt", cls.fail, "#fbe4dc", "#9b4430"],
          ].map(([l, v, bg, c]) => (
            <div
              key={l as string}
              className="rounded-xl border p-4"
              style={{ backgroundColor: bg as string }}
            >
              <p
                className="font-serif text-[28px]"
                style={{ color: c as string }}
              >
                {v}
              </p>
              <p
                className="mt-2 text-xs font-bold"
                style={{ color: c as string }}
              >
                {l}
              </p>
            </div>
          ))}
        </div>
        <Card>
          <table className="w-full text-xs">
            <thead className="bg-[#ece9e1] text-[10px] tracking-[.1em] text-[#817c71]">
              <tr>
                <th className="px-5 py-3 font-bold text-left">XH</th>
                <th className="px-4 py-3 font-bold text-left">HỌC SINH</th>
                <th className="px-4 py-3 font-bold text-center">ĐIỂM TB</th>
                <th className="px-4 py-3 font-bold text-center">XẾP LOẠI</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#e5e0d7]">
              {sheetStudents
                .sort((a, b) => b.avg - a.avg)
                .map((s, i) => (
                  <tr
                    key={s.id}
                    className={`hover:bg-[#fbfaf7] ${i === 0 ? "bg-[#f8f4e3]" : ""}`}
                  >
                    <td className="px-5 py-3">
                      {i === 0 ? (
                        <span className="text-[#c69c3c]">
                          <Icon name="star" size={14} />
                        </span>
                      ) : (
                        <span className="text-[#9a9590] font-mono">
                          {i + 1}
                        </span>
                      )}
                    </td>
                    <td className="px-4 py-3 font-semibold text-[#244749]">
                      {s.name}
                    </td>
                    <td className="px-4 py-3 text-center font-bold text-[#173f43]">
                      {s.avg}
                    </td>
                    <td className="px-4 py-3 text-center">
                      <StatusBadge
                        status={
                          s.letter === "G"
                            ? "Giỏi"
                            : s.letter === "K"
                              ? "Khá"
                              : s.letter === "Đ"
                                ? "Đạt"
                                : "Chưa đạt"
                        }
                      />
                    </td>
                  </tr>
                ))}
            </tbody>
          </table>
        </Card>
      </div>
    );
  }

  return (
    <div className="px-8 py-8">
      <PageHeader
        title="Kết quả lớp học"
        subtitle={`${teacherInfo.subject} — Học kỳ I, 2024–2025`}
        action={
          <button className="flex items-center gap-1.5 rounded-lg border border-[#d0ccc3] bg-[#f7f6f1] px-3 py-2.5 text-xs font-semibold text-[#445350] hover:bg-[#ebe9e2]">
            <Icon name="printer" size={14} /> In bảng điểm
          </button>
        }
      />
      <div className="grid grid-cols-2 gap-4">
        {myCls.map((c) => (
          <Card
            key={c.cls}
            className="p-5 cursor-pointer hover:shadow-md transition"
            onClick={() => setSelectedCls(c.cls)}
          >
            <div className="flex items-start justify-between mb-4">
              <div>
                <p className="font-serif text-[24px] text-[#173f43]">
                  Lớp {c.cls}
                </p>
                <p className="text-[11px] text-[#7a7873] mt-0.5">
                  {c.students} học sinh · {c.grade}
                </p>
              </div>
              <div className="text-right">
                <p className="font-serif text-[22px] text-[#276e68]">{c.gpa}</p>
                <p className="text-[10px] text-[#7a7873]">ĐTB lớp</p>
              </div>
            </div>
            <div className="space-y-2">
              {[
                ["Giỏi", c.excellent, "#276e68"],
                ["Khá", c.good, "#527b99"],
                ["Đạt", c.pass, "#d3ae54"],
                ["Chưa đạt", c.fail, "#c87858"],
              ].map(([l, v, col]) => (
                <div key={l as string} className="flex items-center gap-3">
                  <span className="w-16 text-[11px] text-[#5a6e6b]">{l}</span>
                  <div className="flex-1 h-1.5 overflow-hidden rounded-full bg-[#e5e4dd]">
                    <div
                      className="h-full rounded-full"
                      style={{
                        width: `${Math.round((Number(v) / c.students) * 100)}%`,
                        backgroundColor: col as string,
                      }}
                    />
                  </div>
                  <span className="w-6 text-right text-[11px] font-bold text-[#3a5050]">
                    {v}
                  </span>
                </div>
              ))}
            </div>
            <div className="mt-4 flex items-center justify-between">
              <p className="text-[11px] text-[#7a7873]">
                Xuất sắc:{" "}
                <span className="font-semibold text-[#244749]">
                  {c.topStudent}
                </span>
              </p>
              <span className="text-[#9a9590]">
                <Icon name="arrow" size={14} />
              </span>
            </div>
          </Card>
        ))}
      </div>
    </div>
  );
}

// ── Teacher App Shell ─────────────────────────────────────────────────────────
function TeacherApp({ onLogout }: { onLogout: () => void }) {
  const [active, setActive] = useState("Tổng quan");

  const renderScreen = () => {
    switch (active) {
      case "Tổng quan":
        return <TeacherDashboard onNavigate={setActive} />;
      case "Bảng điểm của tôi":
        return <TeacherMySheets onNavigate={setActive} />;
      case "Nhập điểm":
        return <TeacherGradeEntry />;
      case "Xem lại OCR":
        return <ReconcileScreen />;
      case "Kết quả lớp":
        return <TeacherResults />;
      default:
        return <TeacherDashboard onNavigate={setActive} />;
    }
  };

  return (
    <main className="min-h-screen bg-[#ece9e1] text-[#20383a]">
      <aside className="fixed inset-y-0 left-0 z-20 flex w-[242px] flex-col border-r border-[#d5d0c5] bg-[#f6f4ee] px-4 py-6">
        <div className="flex items-center gap-3 px-2 mb-8">
          <div className="grid h-9 w-9 place-items-center rounded-xl bg-[#173f43] text-[#f2d775] shadow-[0_4px_12px_rgba(23,63,67,.18)]">
            <span className="font-serif text-lg font-semibold">S</span>
          </div>
          <div>
            <p className="font-serif text-[17px] leading-5 tracking-tight text-[#163b3f]">
              Sổ Điểm
            </p>
            <p className="mt-0.5 text-[9px] font-bold tracking-[.16em] text-[#8b8578]">
              HỌC ĐƯỜNG SỐ
            </p>
          </div>
        </div>

        {/* Teacher profile card */}
        <div className="mx-1 mb-6 rounded-xl bg-[#173f43] p-4 text-white">
          <div className="flex items-center gap-3">
            <div className="grid h-10 w-10 shrink-0 place-items-center rounded-full bg-white/20 font-serif text-base font-bold">
              {teacherInfo.initials}
            </div>
            <div className="min-w-0">
              <p className="font-semibold text-sm leading-tight truncate">
                {teacherInfo.name}
              </p>
              <p className="text-[10px] text-white/60 mt-0.5">
                Giáo viên {teacherInfo.subject}
              </p>
            </div>
          </div>
          <div className="mt-3 flex gap-1.5">
            {teacherInfo.classes.map((c) => (
              <span
                key={c}
                className="rounded bg-white/15 px-1.5 py-0.5 text-[10px] font-bold"
              >
                {c}
              </span>
            ))}
          </div>
        </div>

        <p className="px-3 text-[10px] font-bold tracking-[.16em] text-[#9b9588] mb-2">
          MENU
        </p>
        <nav className="space-y-0.5 flex-1">
          {teacherNavItems.map((item) => (
            <button
              key={item.label}
              onClick={() => setActive(item.label)}
              className={`group flex w-full items-center gap-3 rounded-lg px-3 py-2.5 text-left text-[12.5px] transition ${active === item.label ? "bg-[#dfe8e2] font-semibold text-[#173f43] shadow-[inset_3px_0_0_#173f43]" : "text-[#606966] hover:bg-[#ebe9e2] hover:text-[#173f43]"}`}
            >
              <span
                className={
                  active === item.label ? "text-[#17706c]" : "text-[#74817d]"
                }
              >
                <Icon name={item.icon} size={16} />
              </span>
              <span className="flex-1">{item.label}</span>
              {item.count && (
                <span className="rounded-full bg-[#ebe6dc] px-1.5 py-0.5 text-[10px] font-bold text-[#746f64]">
                  {item.count}
                </span>
              )}
              {item.badge && (
                <span className="rounded bg-[#e8c96d] px-1.5 py-0.5 text-[9px] font-bold text-[#5b4a18]">
                  {item.badge}
                </span>
              )}
            </button>
          ))}
        </nav>

        <div className="mt-4 space-y-1">
          <div className="rounded-xl border border-[#ddd8ce] bg-[#eeece6] p-3">
            <p className="text-[10px] font-bold text-[#6b6860]">HẠN NỘP ĐIỂM</p>
            <p className="mt-1 font-serif text-sm text-[#23484a]">
              30 / 11 / 2024
            </p>
            <div className="mt-2 h-1.5 overflow-hidden rounded-full bg-[#d7d4cc]">
              <div className="h-full w-[68%] rounded-full bg-[#c69c3c]" />
            </div>
          </div>
          <button
            onClick={onLogout}
            className="flex w-full items-center gap-2 rounded-lg px-3 py-2.5 text-[12px] text-[#7a7873] hover:bg-[#ebe9e2] hover:text-[#173f43]"
          >
            <Icon name="logout" size={15} /> Đăng xuất
          </button>
        </div>
      </aside>

      <section className="ml-[242px] min-h-screen">
        <header className="sticky top-0 z-10 flex h-[64px] items-center justify-between border-b border-[#d5d0c5] bg-[#f6f4ee]/90 px-8 backdrop-blur-sm">
          <div className="flex items-center gap-2 text-xs text-[#858176]">
            <span>Giáo viên</span>
            <span className="text-[#b7b0a2]">/</span>
            <span className="font-semibold text-[#355658]">{active}</span>
          </div>
          <div className="flex items-center gap-3">
            <button className="relative text-[#62716e] hover:text-[#173f43]">
              <Icon name="bell" />
              <span className="absolute -right-0.5 -top-1 h-2 w-2 rounded-full border border-[#f6f4ee] bg-[#ca714f]" />
            </button>
          </div>
        </header>
        <div key={active}>{renderScreen()}</div>
      </section>
    </main>
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// STUDENT INTERFACE
// ═════════════════════════════════════════════════════════════════════════════

const studentInfo = {
  name: "Lê Bảo Châu",
  initials: "BC",
  cls: "11A3",
  grade: "Khối 11",
  dob: "22/11/2008",
  gpa: 9.1,
  rank: "Giỏi",
  classRank: 2,
  classTotal: 40,
};

const studentSubjects = [
  {
    name: "Ngữ văn",
    icon: "book" as IconName,
    tx1: 9.5,
    tx2: 9.0,
    gk: 9.0,
    ck: 9.5,
    avg: 9.3,
    letter: "G",
    trend: +0.3,
  },
  {
    name: "Toán học",
    icon: "score" as IconName,
    tx1: 8.5,
    tx2: 9.0,
    gk: 9.0,
    ck: 9.0,
    avg: 9.0,
    letter: "G",
    trend: +0.5,
  },
  {
    name: "Tiếng Anh",
    icon: "zap" as IconName,
    tx1: 9.5,
    tx2: 9.0,
    gk: 9.5,
    ck: 9.0,
    avg: 9.2,
    letter: "G",
    trend: +0.1,
  },
  {
    name: "Vật lý",
    icon: "zap" as IconName,
    tx1: 9.0,
    tx2: 8.5,
    gk: 8.5,
    ck: 9.0,
    avg: 8.9,
    letter: "G",
    trend: -0.2,
  },
  {
    name: "Hóa học",
    icon: "zap" as IconName,
    tx1: 8.0,
    tx2: 8.5,
    gk: 8.0,
    ck: 8.5,
    avg: 8.4,
    letter: "G",
    trend: +0.0,
  },
  {
    name: "Sinh học",
    icon: "zap" as IconName,
    tx1: 8.5,
    tx2: 9.0,
    gk: 8.5,
    ck: 9.0,
    avg: 8.8,
    letter: "G",
    trend: +0.4,
  },
];

const gradeHistory = [
  { year: "2022–2023", semester: "HK I", gpa: 7.8, rank: "Khá", cls: "9A3" },
  { year: "2022–2023", semester: "HK II", gpa: 8.2, rank: "Giỏi", cls: "9A3" },
  { year: "2023–2024", semester: "HK I", gpa: 8.7, rank: "Giỏi", cls: "10A3" },
  { year: "2023–2024", semester: "HK II", gpa: 9.0, rank: "Giỏi", cls: "10A3" },
  { year: "2024–2025", semester: "HK I", gpa: 9.1, rank: "Giỏi", cls: "11A3" },
];

const classRankData = [
  { rank: 1, name: "Nguyễn Thị Lan Anh", gpa: 9.4, isMe: false },
  { rank: 2, name: "Lê Bảo Châu", gpa: 9.1, isMe: true },
  { rank: 3, name: "Phạm Minh Quân", gpa: 8.9, isMe: false },
  { rank: 4, name: "Trần Ngọc Hân", gpa: 8.8, isMe: false },
  { rank: 5, name: "Đỗ Thị Kim Anh", gpa: 8.7, isMe: false },
];

const studentNavItems = [
  { label: "Điểm học kỳ này", icon: "score" as IconName },
  { label: "Lịch sử học tập", icon: "calendar" as IconName },
  { label: "Xếp hạng lớp", icon: "star" as IconName },
];

// ── Student: Điểm học kỳ này ─────────────────────────────────────────────────
function StudentGrades() {
  const [expandedSubj, setExpandedSubj] = useState<string | null>(null);
  const letterColors: Record<string, string> = {
    G: "bg-[#d4f0e4] text-[#1e6645]",
    K: "bg-[#dbe7f1] text-[#3c6685]",
    Đ: "bg-[#f5e8c9] text-[#9a7222]",
    CĐ: "bg-[#fbe4dc] text-[#9b4430]",
  };

  return (
    <div className="px-8 py-8">
      {/* GPA hero card */}
      <div className="mb-7 rounded-2xl bg-[#173f43] px-8 py-6 text-white flex items-center gap-8">
        <div>
          <p className="text-[11px] font-bold tracking-[.18em] text-white/50">
            HỌC KỲ I, 2024–2025
          </p>
          <p className="mt-1 font-serif text-[56px] leading-none text-[#e7c864]">
            {studentInfo.gpa}
          </p>
          <p className="mt-1 text-sm text-white/70">Điểm trung bình chung</p>
        </div>
        <div className="h-20 w-px bg-white/15" />
        <div className="space-y-3">
          {[
            { l: "Xếp loại", v: "Học sinh Giỏi", c: "text-[#e7c864]" },
            {
              l: "Xếp hạng lớp",
              v: `${studentInfo.classRank}/${studentInfo.classTotal}`,
              c: "text-white",
            },
            {
              l: "Lớp",
              v: `${studentInfo.cls} · ${studentInfo.grade}`,
              c: "text-white",
            },
          ].map(({ l, v, c }) => (
            <div key={l} className="flex gap-6 items-baseline">
              <span className="text-[11px] text-white/50 w-24 shrink-0">
                {l}
              </span>
              <span className={`text-sm font-bold ${c}`}>{v}</span>
            </div>
          ))}
        </div>
        <div className="ml-auto">
          <div className="flex items-end gap-1 h-16">
            {gradeHistory.map((h, i) => (
              <div key={i} className="flex flex-col items-center gap-1">
                <div
                  className="w-5 rounded-t bg-white/30"
                  style={{ height: `${(h.gpa / 10) * 56}px` }}
                >
                  {i === gradeHistory.length - 1 && (
                    <div className="w-full h-full rounded-t bg-[#e7c864]" />
                  )}
                </div>
                <span className="text-[8px] text-white/40">
                  {h.semester.replace("Học kỳ ", "HK")}
                </span>
              </div>
            ))}
          </div>
          <p className="text-[10px] text-white/40 mt-1 text-center">
            Xu hướng GPA
          </p>
        </div>
      </div>

      {/* Subjects */}
      <div className="space-y-2">
        {studentSubjects.map((subj) => (
          <div key={subj.name}>
            <button
              onClick={() =>
                setExpandedSubj(expandedSubj === subj.name ? null : subj.name)
              }
              className="w-full text-left"
            >
              <Card
                className={`p-4 hover:shadow-sm transition ${expandedSubj === subj.name ? "border-[#173f43]/30" : ""}`}
              >
                <div className="flex items-center gap-4">
                  <div className="w-36 shrink-0">
                    <p className="font-semibold text-[#244749]">{subj.name}</p>
                  </div>
                  {/* Mini bar */}
                  <div className="flex-1 flex items-center gap-3">
                    <div className="flex-1 h-2 overflow-hidden rounded-full bg-[#e5e4dd]">
                      <div
                        className="h-full rounded-full bg-[#173f43]"
                        style={{ width: `${(subj.avg / 10) * 100}%` }}
                      />
                    </div>
                    <span className="font-bold text-[#173f43] w-8 text-right">
                      {subj.avg}
                    </span>
                  </div>
                  <span
                    className={`inline-block rounded-full px-2.5 py-0.5 text-[10px] font-bold ${letterColors[subj.letter]}`}
                  >
                    {subj.letter === "G"
                      ? "Giỏi"
                      : subj.letter === "K"
                        ? "Khá"
                        : subj.letter === "Đ"
                          ? "Đạt"
                          : "Chưa đạt"}
                  </span>
                  <span
                    className={`text-[11px] font-bold w-12 text-right ${subj.trend > 0 ? "text-[#276e68]" : subj.trend < 0 ? "text-[#b34040]" : "text-[#9a9590]"}`}
                  >
                    {subj.trend > 0
                      ? `+${subj.trend}`
                      : subj.trend < 0
                        ? `${subj.trend}`
                        : "–"}
                  </span>
                  <span
                    className={`text-[#9a9590] transition-transform duration-200 ${expandedSubj === subj.name ? "rotate-180" : ""}`}
                  >
                    <Icon name="chevron" size={15} />
                  </span>
                </div>
              </Card>
            </button>

            {expandedSubj === subj.name && (
              <div className="mx-1 mb-1 rounded-b-xl border border-t-0 border-[#d8d4ca] bg-[#f0ede6] px-5 py-4">
                <div className="grid grid-cols-4 gap-4 mb-3">
                  {[
                    ["Thường xét 1", subj.tx1],
                    ["Thường xét 2", subj.tx2],
                    ["Giữa kỳ", subj.gk],
                    ["Cuối kỳ", subj.ck],
                  ].map(([l, v]) => (
                    <div
                      key={l as string}
                      className="rounded-lg border border-[#d8d4ca] bg-white px-3 py-2.5 text-center"
                    >
                      <p className="text-[10px] text-[#9a9590] mb-1">{l}</p>
                      <p
                        className={`font-serif text-[20px] font-bold ${Number(v) >= 8 ? "text-[#276e68]" : Number(v) < 5 ? "text-[#b34040]" : "text-[#173f43]"}`}
                      >
                        {v}
                      </p>
                    </div>
                  ))}
                </div>
                <div className="flex items-center gap-2 text-[11px] text-[#5c6965]">
                  <span
                    className={`${subj.trend > 0 ? "text-[#276e68]" : "text-[#b34040]"}`}
                  >
                    {subj.trend > 0 ? (
                      <Icon name="arrow" size={12} />
                    ) : (
                      <Icon name="arrowDown" size={12} />
                    )}
                  </span>
                  {subj.trend !== 0
                    ? `${Math.abs(subj.trend)} điểm so với học kỳ trước`
                    : "Ổn định so với học kỳ trước"}
                </div>
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}

// ── Student: Lịch sử học tập ─────────────────────────────────────────────────
function StudentHistory() {
  return (
    <div className="px-8 py-8">
      <PageHeader
        title="Lịch sử học tập"
        subtitle="Toàn bộ kết quả từ khi nhập trường đến nay."
      />

      {/* GPA trend */}
      <Card className="p-5 mb-6">
        <SectionLabel>XU HƯỚNG ĐIỂM TRUNG BÌNH</SectionLabel>
        <h2 className="mt-1 font-serif text-[20px] text-[#1b4143] mb-5">
          Tiến bộ qua các học kỳ
        </h2>
        <div className="flex items-end gap-5 h-36">
          {gradeHistory.map((h, i) => {
            const isLatest = i === gradeHistory.length - 1;
            const barH = (h.gpa / 10) * 120;
            return (
              <div key={i} className="flex flex-col items-center gap-2 flex-1">
                <span
                  className={`text-[11px] font-bold ${isLatest ? "text-[#173f43]" : "text-[#7a7873]"}`}
                >
                  {h.gpa}
                </span>
                <div
                  className="w-full rounded-t"
                  style={{
                    height: `${barH}px`,
                    backgroundColor: isLatest ? "#173f43" : "#b8d0c8",
                  }}
                />
                <div className="text-center">
                  <p
                    className={`text-[10px] font-bold ${isLatest ? "text-[#173f43]" : "text-[#7a7873]"}`}
                  >
                    {h.semester.replace("Học kỳ ", "HK")}
                  </p>
                  <p className="text-[9px] text-[#9a9590]">
                    {h.year.split("–")[0]}
                  </p>
                </div>
              </div>
            );
          })}
        </div>
      </Card>

      {/* Semester cards */}
      <div className="space-y-3">
        {[...gradeHistory].reverse().map((h, i) => {
          const isLatest = i === 0;
          const rankColor =
            h.rank === "Giỏi"
              ? { bg: "#d4f0e4", text: "#1e6645" }
              : { bg: "#dbe7f1", text: "#3c6685" };
          return (
            <Card
              key={i}
              className={`p-5 ${isLatest ? "border-[#173f43]/30" : ""}`}
            >
              <div className="flex items-center gap-5">
                {isLatest && (
                  <div className="grid h-9 w-9 shrink-0 place-items-center rounded-lg bg-[#173f43] text-white">
                    <Icon name="star" size={16} />
                  </div>
                )}
                <div className="flex-1">
                  <div className="flex items-center gap-2">
                    <p className="font-semibold text-[#244749]">
                      {h.semester}, {h.year}
                    </p>
                    {isLatest && (
                      <span className="rounded bg-[#173f43] px-1.5 py-0.5 text-[9px] font-bold text-white">
                        Hiện tại
                      </span>
                    )}
                  </div>
                  <p className="mt-0.5 text-[11px] text-[#7a7873]">
                    Lớp {h.cls}
                  </p>
                </div>
                <div className="text-right">
                  <p className="font-serif text-[26px] text-[#173f43]">
                    {h.gpa}
                  </p>
                  <span
                    className="inline-block rounded-full px-2.5 py-0.5 text-[10px] font-bold"
                    style={{
                      backgroundColor: rankColor.bg,
                      color: rankColor.text,
                    }}
                  >
                    {h.rank}
                  </span>
                </div>
                <div className="w-24">
                  <div className="h-2 overflow-hidden rounded-full bg-[#e5e4dd]">
                    <div
                      className="h-full rounded-full bg-[#173f43]"
                      style={{ width: `${(h.gpa / 10) * 100}%` }}
                    />
                  </div>
                </div>
              </div>
            </Card>
          );
        })}
      </div>
    </div>
  );
}

// ── Student: Xếp hạng lớp ────────────────────────────────────────────────────
function StudentRanking() {
  return (
    <div className="px-8 py-8">
      <PageHeader
        title="Xếp hạng lớp"
        subtitle={`Lớp ${studentInfo.cls} · Học kỳ I, 2024–2025 · ${studentInfo.classTotal} học sinh`}
      />

      {/* My position highlight */}
      <div className="mb-6 rounded-2xl bg-[#173f43] px-6 py-5 text-white flex items-center gap-6">
        <div className="grid h-16 w-16 place-items-center rounded-2xl bg-[#e7c864] shrink-0">
          <p className="font-serif text-[28px] font-bold text-[#173f43]">
            {studentInfo.classRank}
          </p>
        </div>
        <div>
          <p className="text-[11px] font-bold tracking-[.14em] text-white/50">
            VỊ TRÍ CỦA BẠN
          </p>
          <p className="mt-1 font-serif text-[22px]">{studentInfo.name}</p>
          <p className="text-sm text-white/60">
            Xếp hạng {studentInfo.classRank} / {studentInfo.classTotal} · ĐTB{" "}
            {studentInfo.gpa}
          </p>
        </div>
        <div className="ml-auto text-right">
          <p className="text-[11px] text-white/50">Cách hạng 1</p>
          <p className="font-serif text-[22px] text-[#e7c864]">–0.3</p>
          <p className="text-[11px] text-white/50">điểm</p>
        </div>
      </div>

      <Card>
        <div className="px-5 py-4 border-b border-[#e5e0d7]">
          <h2 className="font-serif text-[18px] text-[#1b4143]">
            Bảng xếp hạng
          </h2>
          <p className="mt-0.5 text-[11px] text-[#7a7873]">
            Tên các bạn khác được ẩn bớt để bảo mật.
          </p>
        </div>
        <div className="divide-y divide-[#e5e0d7]">
          {classRankData.map((s) => (
            <div
              key={s.rank}
              className={`flex items-center gap-4 px-5 py-3.5 ${s.isMe ? "bg-[#f0f5f2]" : "hover:bg-[#fbfaf7]"}`}
            >
              <div
                className={`grid h-8 w-8 shrink-0 place-items-center rounded-full text-xs font-bold ${s.rank === 1 ? "bg-[#e7c864] text-[#5b4a18]" : s.rank === 2 ? "bg-[#d0d8d5] text-[#3a4f4d]" : s.rank === 3 ? "bg-[#e8c08a] text-[#5b3d16]" : "bg-[#e8e6df] text-[#6b6760]"}`}
              >
                {s.rank}
              </div>
              <div className="flex-1">
                <p
                  className={`font-semibold ${s.isMe ? "text-[#173f43]" : "text-[#244749]"}`}
                >
                  {s.isMe
                    ? s.name
                    : `${s.name.split(" ")[0]} ${s.name
                        .split(" ")
                        .slice(1)
                        .map((n) => n[0] + ".")
                        .join(" ")}`}
                  {s.isMe && (
                    <span className="ml-2 rounded bg-[#173f43] px-1.5 py-0.5 text-[9px] font-bold text-white">
                      Bạn
                    </span>
                  )}
                </p>
              </div>
              <div className="text-right">
                <p
                  className={`font-bold text-sm ${s.isMe ? "text-[#173f43]" : "text-[#244749]"}`}
                >
                  {s.gpa}
                </p>
              </div>
              <div className="w-28">
                <div className="h-1.5 overflow-hidden rounded-full bg-[#e5e4dd]">
                  <div
                    className={`h-full rounded-full ${s.isMe ? "bg-[#173f43]" : "bg-[#a8c4bc]"}`}
                    style={{ width: `${(s.gpa / 10) * 100}%` }}
                  />
                </div>
              </div>
            </div>
          ))}
          {/* More rows anonymized */}
          {[6, 7, 8].map((r) => (
            <div
              key={r}
              className="flex items-center gap-4 px-5 py-3 opacity-40"
            >
              <div className="grid h-8 w-8 shrink-0 place-items-center rounded-full bg-[#e8e6df] text-xs font-bold text-[#6b6760]">
                {r}
              </div>
              <div className="flex-1">
                <p className="font-semibold text-[#244749]">N.T. ****</p>
              </div>
              <p className="text-sm font-bold text-[#244749]">
                {(8.8 - (r - 5) * 0.2).toFixed(1)}
              </p>
              <div className="w-28">
                <div className="h-1.5 overflow-hidden rounded-full bg-[#e5e4dd]">
                  <div
                    className="h-full rounded-full bg-[#a8c4bc]"
                    style={{ width: `${((8.8 - (r - 5) * 0.2) / 10) * 100}%` }}
                  />
                </div>
              </div>
            </div>
          ))}
          <div className="px-5 py-3 text-center text-[11px] text-[#9a9590]">
            — và {studentInfo.classTotal - 8} học sinh khác —
          </div>
        </div>
      </Card>
    </div>
  );
}

// ── Student App Shell ─────────────────────────────────────────────────────────
function StudentApp({ onLogout }: { onLogout: () => void }) {
  const [active, setActive] = useState("Điểm học kỳ này");

  const renderScreen = () => {
    switch (active) {
      case "Điểm học kỳ này":
        return <StudentGrades />;
      case "Lịch sử học tập":
        return <StudentHistory />;
      case "Xếp hạng lớp":
        return <StudentRanking />;
      default:
        return <StudentGrades />;
    }
  };

  return (
    <main className="min-h-screen bg-[#ece9e1] text-[#20383a]">
      <aside className="fixed inset-y-0 left-0 z-20 flex w-[232px] flex-col border-r border-[#d5d0c5] bg-[#f6f4ee] px-4 py-6">
        <div className="flex items-center gap-3 px-2 mb-8">
          <div className="grid h-9 w-9 place-items-center rounded-xl bg-[#173f43] text-[#f2d775]">
            <span className="font-serif text-lg font-semibold">S</span>
          </div>
          <div>
            <p className="font-serif text-[17px] leading-5 tracking-tight text-[#163b3f]">
              Sổ Điểm
            </p>
            <p className="mt-0.5 text-[9px] font-bold tracking-[.16em] text-[#8b8578]">
              HỌC ĐƯỜNG SỐ
            </p>
          </div>
        </div>

        {/* Student profile */}
        <div className="mx-1 mb-6 rounded-xl overflow-hidden">
          <div className="bg-[#173f43] p-4">
            <div className="flex flex-col items-center text-center">
              <div className="grid h-14 w-14 place-items-center rounded-full bg-[#e7c864] font-serif text-xl font-bold text-[#173f43]">
                {studentInfo.initials}
              </div>
              <p className="mt-2.5 font-serif text-[16px] text-white leading-tight">
                {studentInfo.name}
              </p>
              <p className="mt-0.5 text-[11px] text-white/50">
                Lớp {studentInfo.cls}
              </p>
            </div>
          </div>
          <div className="bg-[#1b4a4e] px-4 py-3 flex justify-between">
            <div className="text-center">
              <p className="font-serif text-[20px] text-[#e7c864]">
                {studentInfo.gpa}
              </p>
              <p className="text-[9px] text-white/50">ĐTB</p>
            </div>
            <div className="text-center">
              <p className="font-serif text-[20px] text-white">
                {studentInfo.classRank}
              </p>
              <p className="text-[9px] text-white/50">Xếp hạng</p>
            </div>
            <div className="text-center">
              <p className="font-serif text-[20px] text-white">
                {studentInfo.classTotal}
              </p>
              <p className="text-[9px] text-white/50">HS lớp</p>
            </div>
          </div>
        </div>

        <p className="px-3 text-[10px] font-bold tracking-[.16em] text-[#9b9588] mb-2">
          MENU
        </p>
        <nav className="space-y-0.5 flex-1">
          {studentNavItems.map((item) => (
            <button
              key={item.label}
              onClick={() => setActive(item.label)}
              className={`flex w-full items-center gap-3 rounded-lg px-3 py-2.5 text-left text-[12.5px] transition ${active === item.label ? "bg-[#dfe8e2] font-semibold text-[#173f43] shadow-[inset_3px_0_0_#173f43]" : "text-[#606966] hover:bg-[#ebe9e2] hover:text-[#173f43]"}`}
            >
              <span
                className={
                  active === item.label ? "text-[#17706c]" : "text-[#74817d]"
                }
              >
                <Icon name={item.icon} size={16} />
              </span>
              <span>{item.label}</span>
            </button>
          ))}
        </nav>

        <div className="mt-4 space-y-2">
          <div className="rounded-xl border border-[#ddd8ce] bg-[#eeece6] px-4 py-3">
            <p className="text-[10px] font-bold text-[#6b6860]">
              HỌC KỲ HIỆN TẠI
            </p>
            <p className="mt-1 text-[11px] font-semibold text-[#23484a]">
              Học kỳ I, 2024–2025
            </p>
            <div className="mt-2 flex items-center gap-2">
              <div className="flex-1 h-1.5 overflow-hidden rounded-full bg-[#d7d4cc]">
                <div className="h-full w-[68%] rounded-full bg-[#c69c3c]" />
              </div>
              <span className="text-[9px] text-[#9a9590]">68%</span>
            </div>
          </div>
          <button
            onClick={onLogout}
            className="flex w-full items-center gap-2 rounded-lg px-3 py-2.5 text-[12px] text-[#7a7873] hover:bg-[#ebe9e2] hover:text-[#173f43]"
          >
            <Icon name="logout" size={15} /> Đăng xuất
          </button>
        </div>
      </aside>

      <section className="ml-[232px] min-h-screen">
        <header className="sticky top-0 z-10 flex h-[64px] items-center justify-between border-b border-[#d5d0c5] bg-[#f6f4ee]/90 px-8 backdrop-blur-sm">
          <div className="flex items-center gap-2 text-xs text-[#858176]">
            <span>Học sinh</span>
            <span className="text-[#b7b0a2]">/</span>
            <span className="font-semibold text-[#355658]">{active}</span>
          </div>
          <button className="relative text-[#62716e] hover:text-[#173f43]">
            <Icon name="bell" />
          </button>
        </header>
        <div key={active}>{renderScreen()}</div>
      </section>
    </main>
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// LOGIN / ROLE SELECTION SCREEN
// ═════════════════════════════════════════════════════════════════════════════

type Role = "admin" | "teacher" | "student";

function LoginScreen({ onLogin }: { onLogin: (r: Role) => void }) {
  const roles: {
    id: Role;
    title: string;
    subtitle: string;
    name: string;
    description: string;
    initials: string;
    avatarBg: string;
    avatarText: string;
    accent: string;
    features: string[];
  }[] = [
    {
      id: "admin",
      title: "Quản trị viên",
      subtitle: "Toàn quyền hệ thống",
      name: "Lan Nguyễn",
      description:
        "Quản lý toàn trường, phê duyệt bảng điểm và xem báo cáo tổng hợp.",
      initials: "LN",
      avatarBg: "#c3cfd4",
      avatarText: "#23464a",
      accent: "#173f43",
      features: [
        "Quản lý tài khoản & danh mục",
        "Xem tất cả bảng điểm",
        "Phê duyệt & tổng kết",
        "Báo cáo & thống kê",
        "Tra cứu học sinh",
      ],
    },
    {
      id: "teacher",
      title: "Giáo viên",
      subtitle: "Nhập và quản lý điểm lớp mình",
      name: "Phạm Thu Hà",
      description:
        "Nhập điểm thủ công hoặc từ ảnh chụp. Tự xem lại kết quả OCR và xác nhận.",
      initials: "TH",
      avatarBg: "#c9d9bf",
      avatarText: "#2b4a28",
      accent: "#3d6b38",
      features: [
        "Xem bảng điểm của mình",
        "Nhập điểm thủ công",
        "Nhập điểm từ ảnh OCR",
        "Tự đối chiếu & xác nhận",
        "Xem kết quả lớp",
      ],
    },
    {
      id: "student",
      title: "Học sinh",
      subtitle: "Tra cứu điểm cá nhân",
      name: "Lê Bảo Châu",
      description: "Xem điểm từng môn, lịch sử học tập và xếp hạng trong lớp.",
      initials: "BC",
      avatarBg: "#d4c9bf",
      avatarText: "#4a3828",
      accent: "#8b5e3c",
      features: [
        "Xem điểm học kỳ này",
        "Xem từng cột điểm",
        "Lịch sử các học kỳ",
        "Xếp hạng trong lớp",
      ],
    },
  ];

  return (
    <div className="min-h-screen bg-[#ece9e1] flex flex-col items-center justify-center px-6 py-12">
      <div className="text-center mb-10">
        <div className="mx-auto grid h-14 w-14 place-items-center rounded-2xl bg-[#173f43] text-[#f2d775] shadow-[0_6px_20px_rgba(23,63,67,.22)] mb-4">
          <span className="font-serif text-2xl font-semibold">S</span>
        </div>
        <h1 className="font-serif text-[38px] leading-none tracking-tight text-[#173f43]">
          Sổ Điểm
        </h1>
        <p className="mt-2 text-[12px] font-bold tracking-[.2em] text-[#9b9588]">
          HỌC ĐƯỜNG SỐ · THPT NGUYỄN DU
        </p>
        <p className="mt-4 text-sm text-[#697472]">
          Chọn vai trò để xem giao diện demo tương ứng
        </p>
      </div>

      <div className="grid grid-cols-3 gap-5 w-full max-w-4xl">
        {roles.map((r) => (
          <button
            key={r.id}
            onClick={() => onLogin(r.id)}
            className="group flex flex-col rounded-2xl border-2 border-[#d8d4ca] bg-[#f7f6f1] p-6 text-left transition-all hover:border-[#173f43] hover:shadow-lg hover:-translate-y-0.5"
          >
            {/* Avatar + role label */}
            <div className="flex items-start justify-between w-full mb-5">
              <div
                className="grid h-12 w-12 place-items-center rounded-full font-serif text-base font-bold"
                style={{ backgroundColor: r.avatarBg, color: r.avatarText }}
              >
                {r.initials}
              </div>
              <span className="rounded-full border border-[#d0ccc3] px-2.5 py-1 text-[10px] font-bold text-[#7a7873]">
                {r.subtitle}
              </span>
            </div>

            <p className="font-serif text-[22px] leading-tight text-[#173f43]">
              {r.title}
            </p>
            <p className="mt-1 text-xs font-bold text-[#9a9590]">
              Demo: {r.name}
            </p>
            <p className="mt-3 text-[12px] leading-5 text-[#697472]">
              {r.description}
            </p>

            <div className="mt-5 space-y-1.5 flex-1">
              {r.features.map((f) => (
                <div
                  key={f}
                  className="flex items-center gap-2 text-[11px] text-[#52615e]"
                >
                  <span className="h-1 w-1 rounded-full bg-[#a8c4bc] shrink-0" />
                  {f}
                </div>
              ))}
            </div>

            <div className="mt-5 flex items-center gap-1.5 text-xs font-bold text-[#196660] group-hover:gap-2.5 transition-all">
              Vào hệ thống <Icon name="arrow" size={14} />
            </div>
          </button>
        ))}
      </div>

      <p className="mt-8 text-[11px] text-[#a0a49e]">
        THPT Nguyễn Du · Hệ thống quản lý điểm số · Phiên bản demo 2024
      </p>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN NAV & ROOT
// ─────────────────────────────────────────────────────────────────────────────
const adminNavigation = [
  { label: "Tổng quan", icon: "grid" as IconName },
  { label: "Tài khoản & xác thực", icon: "shield" as IconName },
  { label: "Danh mục học tập", icon: "book" as IconName },
  { label: "Quản lý bảng điểm", icon: "score" as IconName, count: "08" },
  { label: "Nhận dạng từ ảnh", icon: "scan" as IconName, badge: "Mới" },
  { label: "Đối chiếu & duyệt", icon: "check" as IconName, count: "12" },
  { label: "Tổng kết kết quả", icon: "layers" as IconName },
  { label: "Báo cáo & thống kê", icon: "chart" as IconName },
  { label: "Tra cứu học sinh", icon: "users" as IconName },
];

function AdminApp({ onLogout }: { onLogout: () => void }) {
  const [active, setActive] = useState("Tổng quan");
  const [searchOpen, setSearchOpen] = useState(false);

  const renderScreen = () => {
    switch (active) {
      case "Tổng quan":
        return <DashboardScreen />;
      case "Tài khoản & xác thực":
        return <AccountScreen />;
      case "Danh mục học tập":
        return <CatalogScreen />;
      case "Quản lý bảng điểm":
        return <GradeManagementScreen />;
      case "Nhận dạng từ ảnh":
        return <OcrScreen />;
      case "Đối chiếu & duyệt":
        return <ReconcileScreen />;
      case "Tổng kết kết quả":
        return <SummaryScreen />;
      case "Báo cáo & thống kê":
        return <ReportScreen />;
      case "Tra cứu học sinh":
        return <LookupScreen />;
      default:
        return <DashboardScreen />;
    }
  };

  return (
    <main className="min-h-screen bg-[#ece9e1] text-[#20383a] selection:bg-[#d8b765] selection:text-[#20383a]">
      <aside className="fixed inset-y-0 left-0 z-20 flex w-[258px] flex-col border-r border-[#d5d0c5] bg-[#f6f4ee] px-5 py-6">
        <div className="flex items-center gap-3 px-2">
          <div className="grid h-10 w-10 place-items-center rounded-xl bg-[#173f43] text-[#f2d775] shadow-[0_4px_12px_rgba(23,63,67,.18)]">
            <span className="font-serif text-xl font-semibold">S</span>
          </div>
          <div>
            <p className="font-serif text-[19px] leading-5 tracking-tight text-[#163b3f]">
              Sổ Điểm
            </p>
            <p className="mt-0.5 text-[10px] font-bold tracking-[.16em] text-[#8b8578]">
              HỌC ĐƯỜNG SỐ
            </p>
          </div>
        </div>

        <div className="mt-9 px-3 text-[10px] font-bold tracking-[.16em] text-[#9b9588]">
          ĐIỀU HÀNH
        </div>
        <nav className="mt-3 space-y-0.5 overflow-y-auto flex-1">
          {adminNavigation.map((item) => (
            <button
              key={item.label}
              onClick={() => setActive(item.label)}
              className={`group flex w-full items-center gap-3 rounded-lg px-3 py-2.5 text-left text-[12.5px] transition ${active === item.label ? "bg-[#dfe8e2] font-semibold text-[#173f43] shadow-[inset_3px_0_0_#173f43]" : "text-[#606966] hover:bg-[#ebe9e2] hover:text-[#173f43]"}`}
            >
              <span
                className={
                  active === item.label ? "text-[#17706c]" : "text-[#74817d]"
                }
              >
                <Icon name={item.icon} size={16} />
              </span>
              <span className="flex-1 leading-5">{item.label}</span>
              {item.count && (
                <span className="rounded-full bg-[#ebe6dc] px-1.5 py-0.5 text-[10px] font-bold text-[#746f64] group-hover:bg-white">
                  {item.count}
                </span>
              )}
              {item.badge && (
                <span className="rounded bg-[#e8c96d] px-1.5 py-0.5 text-[9px] font-bold text-[#5b4a18]">
                  {item.badge}
                </span>
              )}
            </button>
          ))}
        </nav>

        <div className="mt-4 space-y-1">
          <div className="rounded-xl border border-[#ddd8ce] bg-[#eeece6] p-4">
            <p className="font-serif text-sm text-[#23484a]">
              Học kỳ I, 2024–2025
            </p>
            <p className="mt-1 text-[11px] leading-4 text-[#77776f]">
              Còn 18 ngày để hoàn tất nhập điểm.
            </p>
            <div className="mt-3 h-1.5 overflow-hidden rounded-full bg-[#d7d4cc]">
              <div className="h-full w-[68%] rounded-full bg-[#c69c3c]" />
            </div>
          </div>
          <button
            onClick={onLogout}
            className="flex w-full items-center gap-2 rounded-lg px-3 py-2.5 text-[12px] text-[#7a7873] hover:bg-[#ebe9e2] hover:text-[#173f43]"
          >
            <Icon name="logout" size={15} /> Đổi vai trò
          </button>
        </div>
      </aside>

      <section className="ml-[258px] min-h-screen">
        <header className="sticky top-0 z-10 flex h-[68px] items-center justify-between border-b border-[#d5d0c5] bg-[#f6f4ee]/90 px-9 backdrop-blur-sm">
          <div className="flex items-center gap-2 text-xs text-[#858176]">
            <span>Hệ thống</span>
            <span className="text-[#b7b0a2]">/</span>
            <span className="font-semibold text-[#355658]">{active}</span>
          </div>
          <div className="flex items-center gap-4">
            {searchOpen && (
              <input
                autoFocus
                placeholder="Tìm lớp, học sinh..."
                onBlur={() => setSearchOpen(false)}
                className="w-52 rounded-lg border border-[#c8c5ba] bg-white px-3 py-2 text-xs outline-none ring-[#aac8bf] focus:ring-2"
              />
            )}
            <button
              onClick={() => setSearchOpen(!searchOpen)}
              aria-label="Tìm kiếm"
              className="text-[#62716e] hover:text-[#173f43]"
            >
              <Icon name="search" />
            </button>
            <button
              aria-label="Thông báo"
              className="relative text-[#62716e] hover:text-[#173f43]"
            >
              <Icon name="bell" />
              <span className="absolute -right-0.5 -top-1 h-2 w-2 rounded-full border border-[#f6f4ee] bg-[#ca714f]" />
            </button>
            <div className="h-7 w-px bg-[#d8d4cb]" />
            <button className="flex items-center gap-2 text-left">
              <span className="grid h-8 w-8 place-items-center rounded-full bg-[#c3d4cd] font-serif text-sm font-semibold text-[#23464a]">
                LN
              </span>
              <span className="hidden text-xs font-semibold text-[#3b5050] xl:block">
                Lan Nguyễn
              </span>
              <Icon name="chevron" size={14} />
            </button>
          </div>
        </header>
        <div key={active}>{renderScreen()}</div>
      </section>
    </main>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ROOT — ROLE-BASED ROUTING
// ─────────────────────────────────────────────────────────────────────────────
export default function App() {
  const [role, setRole] = useState<Role | null>(null);

  if (!role) return <LoginScreen onLogin={setRole} />;
  if (role === "teacher") return <TeacherApp onLogout={() => setRole(null)} />;
  if (role === "student") return <StudentApp onLogout={() => setRole(null)} />;
  return <AdminApp onLogout={() => setRole(null)} />;
}
