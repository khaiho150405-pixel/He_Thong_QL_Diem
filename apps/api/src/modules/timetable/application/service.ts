import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import type { PrismaClient } from "../../../generated/prisma/client.js";
import type { Actor } from "../../authorization/application/policy.js";
import type {
  CreateTimetableItemInput,
  TimetableItemDto,
  TimetableListDto,
} from "../presentation/dto.js";
import { validateClassDaySchedule } from "../domain/schedule-policy.js";

@Injectable()
export class TimetableService {
  constructor(@Inject("DATABASE") private readonly db: PrismaClient) {}

  private enforceClassDay(slots: Array<{ ma_mon: number; tiet: number }>) {
    try {
      validateClassDaySchedule(slots);
    } catch (error) {
      throw new ConflictException(
        error instanceof Error ? error.message : "Thời khóa biểu không hợp lệ.",
      );
    }
  }

  private async validateProspectiveClassDay(
    input: CreateTimetableItemInput,
    excludedId?: number,
  ): Promise<void> {
    const existing = await this.db.thoi_khoa_bieu.findMany({
      where: {
        ma_lop: input.ma_lop,
        ma_hoc_ky: input.ma_hoc_ky,
        thu: input.thu,
        ...(excludedId ? { ma_tiet_hoc: { not: excludedId } } : {}),
      },
      select: { ma_mon: true, tiet: true },
    });
    this.enforceClassDay([
      ...existing,
      { ma_mon: input.ma_mon, tiet: input.tiet },
    ]);
  }

  async getTimetable(
    actor: Actor,
    filter: {
      classId?: number;
      teacherId?: number;
      semesterId?: number;
      dayOfWeek?: number;
    },
  ): Promise<TimetableListDto> {
    let targetClassId = filter.classId;
    let targetTeacherId = filter.teacherId;

    if (actor.role === "HOC_SINH") {
      // Học sinh chỉ xem thời khóa biểu của lớp mình
      const student = await this.db.hoc_sinh.findFirst({
        where: { ma_nguoi_dung: actor.id, dang_theo_hoc: true },
      });
      if (!student) {
        throw new NotFoundException(
          "Không tìm thấy thông tin học sinh của bạn.",
        );
      }
      targetClassId = student.ma_lop;
      targetTeacherId = undefined;
    } else if (actor.role === "GIAO_VIEN") {
      // Giáo viên mặc định xem các tiết mình dạy
      const teacher = await this.db.giao_vien.findUnique({
        where: { ma_giao_vien: actor.id },
      });
      if (!teacher) {
        throw new NotFoundException("Không tìm thấy hồ sơ giáo viên.");
      }
      targetTeacherId = teacher.ma_giao_vien;
    }

    // Determine current/default semester if not provided
    let semesterId = filter.semesterId;
    if (!semesterId) {
      const activeYear = await this.db.nam_hoc.findFirst({
        where: { hien_hanh: true },
        include: { hoc_ky_rows: { orderBy: { thu_tu: "asc" } } },
      });
      if (activeYear && activeYear.hoc_ky_rows.length > 0) {
        semesterId = activeYear.hoc_ky_rows[0]?.ma_hoc_ky;
      }
    }

    const rows = await this.db.thoi_khoa_bieu.findMany({
      where: {
        ...(targetClassId ? { ma_lop: targetClassId } : {}),
        ...(targetTeacherId ? { ma_giao_vien: targetTeacherId } : {}),
        ...(semesterId ? { ma_hoc_ky: semesterId } : {}),
        ...(filter.dayOfWeek ? { thu: filter.dayOfWeek } : {}),
      },
      include: {
        ma_lop_ref: true,
        ma_mon_ref: true,
        ma_giao_vien_ref: true,
        ma_hoc_ky_ref: true,
      },
      orderBy: [{ thu: "asc" }, { tiet: "asc" }],
    });

    const items: TimetableItemDto[] = rows.map((r) => ({
      ma_tiet_hoc: r.ma_tiet_hoc,
      ma_lop: r.ma_lop,
      ten_lop: r.ma_lop_ref.ten_lop,
      ma_mon: r.ma_mon,
      ten_mon: r.ma_mon_ref.ten_mon,
      ma_giao_vien: r.ma_giao_vien,
      ten_giao_vien: r.ma_giao_vien_ref.ho_ten,
      ma_hoc_ky: r.ma_hoc_ky,
      ten_hoc_ky: r.ma_hoc_ky_ref.ten,
      thu: r.thu,
      tiet: r.tiet,
      phong_hoc: r.phong_hoc,
      ghi_chu: r.ghi_chu,
    }));

    return { items, total: items.length };
  }

  async createItem(
    actor: Actor,
    input: CreateTimetableItemInput,
  ): Promise<TimetableItemDto> {
    if (actor.role !== "QUAN_TRI_VIEN") {
      throw new ForbiddenException(
        "Chỉ Quản trị viên mới có quyền xếp thời khóa biểu.",
      );
    }

    if (input.thu < 2 || input.thu > 8) {
      throw new BadRequestException("Ngày học phải từ Thứ Hai đến Chủ nhật.");
    }
    if (input.tiet < 1 || input.tiet > 10) {
      throw new BadRequestException("Tiết học phải từ 1 đến 10.");
    }

    const [classroom, subject, teacher, semester, assignment] =
      await Promise.all([
        this.db.lop.findUnique({ where: { ma_lop: input.ma_lop } }),
        this.db.mon_hoc.findUnique({ where: { ma_mon: input.ma_mon } }),
        this.db.giao_vien.findUnique({
          where: { ma_giao_vien: input.ma_giao_vien },
        }),
        this.db.hoc_ky.findUnique({ where: { ma_hoc_ky: input.ma_hoc_ky } }),
        this.db.phan_cong_giang_day.findFirst({
          where: {
            ma_lop: input.ma_lop,
            ma_mon: input.ma_mon,
            ma_hoc_ky: input.ma_hoc_ky,
            ma_giao_vien: input.ma_giao_vien,
          },
        }),
      ]);
    if (!classroom || !subject || !teacher || !semester) {
      throw new BadRequestException(
        "Lớp, môn, giáo viên hoặc học kỳ không hợp lệ.",
      );
    }
    if (!assignment) {
      throw new ConflictException(
        "Chưa có phân công giảng dạy phù hợp cho lớp, môn, giáo viên và học kỳ này.",
      );
    }

    // Check duplicate class-period conflict
    const classConflict = await this.db.thoi_khoa_bieu.findFirst({
      where: {
        ma_lop: input.ma_lop,
        ma_hoc_ky: input.ma_hoc_ky,
        thu: input.thu,
        tiet: input.tiet,
      },
    });
    if (classConflict) {
      throw new ConflictException(
        "Lớp học này đã có tiết học vào thời điểm đã chọn.",
      );
    }

    // Check duplicate teacher-period conflict
    const teacherConflict = await this.db.thoi_khoa_bieu.findFirst({
      where: {
        ma_giao_vien: input.ma_giao_vien,
        ma_hoc_ky: input.ma_hoc_ky,
        thu: input.thu,
        tiet: input.tiet,
      },
    });
    if (teacherConflict) {
      throw new ConflictException(
        "Giáo viên này đã có tiết dạy lớp khác vào thời điểm đã chọn.",
      );
    }

    await this.validateProspectiveClassDay(input);

    const created = await this.db.thoi_khoa_bieu.create({
      data: {
        ma_lop: input.ma_lop,
        ma_mon: input.ma_mon,
        ma_giao_vien: input.ma_giao_vien,
        ma_hoc_ky: input.ma_hoc_ky,
        thu: input.thu,
        tiet: input.tiet,
        phong_hoc: input.phong_hoc ?? null,
        ghi_chu: input.ghi_chu ?? null,
      },
      include: {
        ma_lop_ref: true,
        ma_mon_ref: true,
        ma_giao_vien_ref: true,
        ma_hoc_ky_ref: true,
      },
    });

    return {
      ma_tiet_hoc: created.ma_tiet_hoc,
      ma_lop: created.ma_lop,
      ten_lop: created.ma_lop_ref.ten_lop,
      ma_mon: created.ma_mon,
      ten_mon: created.ma_mon_ref.ten_mon,
      ma_giao_vien: created.ma_giao_vien,
      ten_giao_vien: created.ma_giao_vien_ref.ho_ten,
      ma_hoc_ky: created.ma_hoc_ky,
      ten_hoc_ky: created.ma_hoc_ky_ref.ten,
      thu: created.thu,
      tiet: created.tiet,
      phong_hoc: created.phong_hoc,
      ghi_chu: created.ghi_chu,
    };
  }

  async updateItem(
    actor: Actor,
    id: number,
    input: CreateTimetableItemInput,
  ): Promise<TimetableItemDto> {
    if (actor.role !== "QUAN_TRI_VIEN") {
      throw new ForbiddenException(
        "Chỉ Quản trị viên mới có quyền sửa thời khóa biểu.",
      );
    }
    if (input.thu < 2 || input.thu > 8) {
      throw new BadRequestException("Ngày học phải từ Thứ Hai đến Chủ nhật.");
    }
    if (input.tiet < 1 || input.tiet > 10) {
      throw new BadRequestException("Tiết học phải từ 1 đến 10.");
    }

    const [existing, classroom, subject, teacher, semester, assignment] =
      await Promise.all([
        this.db.thoi_khoa_bieu.findUnique({ where: { ma_tiet_hoc: id } }),
        this.db.lop.findUnique({ where: { ma_lop: input.ma_lop } }),
        this.db.mon_hoc.findUnique({ where: { ma_mon: input.ma_mon } }),
        this.db.giao_vien.findUnique({
          where: { ma_giao_vien: input.ma_giao_vien },
        }),
        this.db.hoc_ky.findUnique({ where: { ma_hoc_ky: input.ma_hoc_ky } }),
        this.db.phan_cong_giang_day.findFirst({
          where: {
            ma_lop: input.ma_lop,
            ma_mon: input.ma_mon,
            ma_hoc_ky: input.ma_hoc_ky,
            ma_giao_vien: input.ma_giao_vien,
          },
        }),
      ]);
    if (!existing) throw new NotFoundException("Không tìm thấy tiết học.");
    if (!classroom || !subject || !teacher || !semester) {
      throw new BadRequestException(
        "Lớp, môn, giáo viên hoặc học kỳ không hợp lệ.",
      );
    }
    if (!assignment) {
      throw new ConflictException(
        "Chưa có phân công giảng dạy phù hợp cho lớp, môn, giáo viên và học kỳ này.",
      );
    }

    const [classConflict, teacherConflict] = await Promise.all([
      this.db.thoi_khoa_bieu.findFirst({
        where: {
          ma_tiet_hoc: { not: id },
          ma_lop: input.ma_lop,
          ma_hoc_ky: input.ma_hoc_ky,
          thu: input.thu,
          tiet: input.tiet,
        },
      }),
      this.db.thoi_khoa_bieu.findFirst({
        where: {
          ma_tiet_hoc: { not: id },
          ma_giao_vien: input.ma_giao_vien,
          ma_hoc_ky: input.ma_hoc_ky,
          thu: input.thu,
          tiet: input.tiet,
        },
      }),
    ]);
    if (classConflict) {
      throw new ConflictException(
        "Lớp học này đã có tiết học vào thời điểm đã chọn.",
      );
    }
    if (teacherConflict) {
      throw new ConflictException(
        "Giáo viên này đã có tiết dạy lớp khác vào thời điểm đã chọn.",
      );
    }

    await this.validateProspectiveClassDay(input, id);

    const updated = await this.db.thoi_khoa_bieu.update({
      where: { ma_tiet_hoc: id },
      data: {
        ma_lop: input.ma_lop,
        ma_mon: input.ma_mon,
        ma_giao_vien: input.ma_giao_vien,
        ma_hoc_ky: input.ma_hoc_ky,
        thu: input.thu,
        tiet: input.tiet,
        phong_hoc: input.phong_hoc?.trim() || null,
        ghi_chu: input.ghi_chu?.trim() || null,
      },
      include: {
        ma_lop_ref: true,
        ma_mon_ref: true,
        ma_giao_vien_ref: true,
        ma_hoc_ky_ref: true,
      },
    });
    return {
      ma_tiet_hoc: updated.ma_tiet_hoc,
      ma_lop: updated.ma_lop,
      ten_lop: updated.ma_lop_ref.ten_lop,
      ma_mon: updated.ma_mon,
      ten_mon: updated.ma_mon_ref.ten_mon,
      ma_giao_vien: updated.ma_giao_vien,
      ten_giao_vien: updated.ma_giao_vien_ref.ho_ten,
      ma_hoc_ky: updated.ma_hoc_ky,
      ten_hoc_ky: updated.ma_hoc_ky_ref.ten,
      thu: updated.thu,
      tiet: updated.tiet,
      phong_hoc: updated.phong_hoc,
      ghi_chu: updated.ghi_chu,
    };
  }

  async deleteItem(actor: Actor, id: number): Promise<void> {
    if (actor.role !== "QUAN_TRI_VIEN") {
      throw new ForbiddenException(
        "Chỉ Quản trị viên mới có quyền xóa tiết học.",
      );
    }
    const existing = await this.db.thoi_khoa_bieu.findUnique({
      where: { ma_tiet_hoc: id },
    });
    if (!existing) throw new NotFoundException("Không tìm thấy tiết học.");

    const remaining = await this.db.thoi_khoa_bieu.findMany({
      where: {
        ma_tiet_hoc: { not: id },
        ma_lop: existing.ma_lop,
        ma_hoc_ky: existing.ma_hoc_ky,
        thu: existing.thu,
      },
      select: { ma_mon: true, tiet: true },
    });
    this.enforceClassDay(remaining);

    const deleted = await this.db.thoi_khoa_bieu.deleteMany({
      where: { ma_tiet_hoc: id },
    });
    if (deleted.count === 0)
      throw new NotFoundException("Không tìm thấy tiết học.");
  }
}
