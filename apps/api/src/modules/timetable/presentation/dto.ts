import { ApiProperty } from "@nestjs/swagger";

export class TimetableItemDto {
  @ApiProperty({ type: Number }) ma_tiet_hoc!: number;
  @ApiProperty({ type: Number }) ma_lop!: number;
  @ApiProperty({ type: String }) ten_lop!: string;
  @ApiProperty({ type: Number }) ma_mon!: number;
  @ApiProperty({ type: String }) ten_mon!: string;
  @ApiProperty({ type: Number }) ma_giao_vien!: number;
  @ApiProperty({ type: String }) ten_giao_vien!: string;
  @ApiProperty({ type: Number }) ma_hoc_ky!: number;
  @ApiProperty({ type: String }) ten_hoc_ky!: string;
  @ApiProperty({
    type: Number,
    description: "Ngày trong tuần (2 - 8, gồm Chủ nhật)",
  })
  thu!: number;
  @ApiProperty({ type: Number, description: "Tiết học (1 - 10)" })
  tiet!: number;
  @ApiProperty({ type: String, nullable: true }) phong_hoc!: string | null;
  @ApiProperty({ type: String, nullable: true }) ghi_chu!: string | null;
}

export class TimetableSemesterDto {
  @ApiProperty({ type: Number }) id!: number;
  @ApiProperty({ type: String }) name!: string;
  @ApiProperty({ type: String }) yearName!: string;
  @ApiProperty({ type: String, description: "YYYY-MM-DD" }) startDate!: string;
  @ApiProperty({ type: String, description: "YYYY-MM-DD" }) endDate!: string;
}

export class TimetableListDto {
  @ApiProperty({ type: [TimetableItemDto] }) items!: TimetableItemDto[];
  @ApiProperty({ type: Number }) total!: number;
  @ApiProperty({
    type: TimetableSemesterDto,
    nullable: true,
    description:
      "Học kỳ mà danh sách đang dùng (semesterId hoặc học kỳ mặc định); null nếu không xác định được.",
  })
  semester!: TimetableSemesterDto | null;
}

export class CreateTimetableItemInput {
  @ApiProperty({ type: Number }) ma_lop!: number;
  @ApiProperty({ type: Number }) ma_mon!: number;
  @ApiProperty({ type: Number }) ma_giao_vien!: number;
  @ApiProperty({ type: Number }) ma_hoc_ky!: number;
  @ApiProperty({ type: Number }) thu!: number;
  @ApiProperty({ type: Number }) tiet!: number;
  @ApiProperty({ type: String, required: false, nullable: true }) phong_hoc?:
    | string
    | null;
  @ApiProperty({ type: String, required: false, nullable: true }) ghi_chu?:
    | string
    | null;
}
