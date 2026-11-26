import {
  Controller,
  Get,
  Inject,
  Param,
  ParseIntPipe,
  Query,
  Req,
  StreamableFile,
} from "@nestjs/common";
import {
  ApiOkResponse,
  ApiParam,
  ApiProduces,
  ApiProperty,
  ApiQuery,
  ApiTags,
} from "@nestjs/swagger";
import type { Request } from "express";
import { allowQuery } from "../../../common/query.js";
import type { Actor } from "../../authorization/application/policy.js";
import { YearReportsService } from "../application/year-reports.js";

export class LevelCountsDto {
  @ApiProperty({ type: Number }) TOT!: number;
  @ApiProperty({ type: Number }) KHA!: number;
  @ApiProperty({ type: Number }) DAT!: number;
  @ApiProperty({ type: Number }) CHUA_DAT!: number;
  @ApiProperty({ type: Number }) CHUA_DU_MON!: number;
}

export class StatisticsGroupDto {
  @ApiProperty({ type: Number }) key!: number;
  @ApiProperty({ type: String }) label!: string;
  @ApiProperty({ type: Number }) students!: number;
  @ApiProperty({
    type: String,
    nullable: true,
    description: "Trung bình các điểm tổng kết môn tính điểm",
  })
  average!: string | null;
  @ApiProperty({ type: Number }) fromEight!: number;
  @ApiProperty({ type: Number }) fromSixHalf!: number;
  @ApiProperty({ type: Number }) fromFive!: number;
  @ApiProperty({ type: Number }) belowFive!: number;
  @ApiProperty({ type: Number }) passed!: number;
  @ApiProperty({ type: Number }) failed!: number;
  @ApiProperty({
    type: Number,
    description: "Lượt môn chưa có điểm tổng kết",
  })
  missing!: number;
  @ApiProperty({
    type: LevelCountsDto,
    nullable: true,
    description: "null ở nhóm theo môn",
  })
  levels!: LevelCountsDto | null;
}

export class YearStatisticsDto {
  @ApiProperty({ type: Number }) yearId!: number;
  @ApiProperty({ type: String }) yearName!: string;
  @ApiProperty({ type: String, description: "BAN_CHOT hoặc HIEN_TAI" })
  source!: string;
  @ApiProperty({ type: Number, nullable: true })
  snapshotVersion!: number | null;
  @ApiProperty({ type: String, nullable: true }) snapshotAt!: string | null;
  @ApiProperty({ type: StatisticsGroupDto, nullable: true })
  total!: StatisticsGroupDto | null;
  @ApiProperty({ type: [StatisticsGroupDto] }) grades!: StatisticsGroupDto[];
  @ApiProperty({ type: [StatisticsGroupDto] }) classes!: StatisticsGroupDto[];
  @ApiProperty({ type: [StatisticsGroupDto] }) subjects!: StatisticsGroupDto[];
}

export class YearComparisonItemDto extends StatisticsGroupDto {
  @ApiProperty({ type: Number }) yearId!: number;
  @ApiProperty({ type: String }) yearName!: string;
  @ApiProperty({ type: String, description: "BAN_CHOT hoặc HIEN_TAI" })
  source!: string;
}

export class YearComparisonDto {
  @ApiProperty({ type: [YearComparisonItemDto] })
  items!: YearComparisonItemDto[];
}

const XLSX =
  "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
const TERM_QUERY = {
  name: "term",
  required: true,
  type: Number,
  description: "Thứ tự học kỳ: 1, 2 hoặc 3",
} as const;

@ApiTags("reports")
@Controller("reports/admin/years")
export class YearReportsController {
  constructor(
    @Inject(YearReportsService) private readonly service: YearReportsService,
  ) {}

  @Get("comparison")
  @ApiQuery(TERM_QUERY)
  @ApiOkResponse({ type: YearComparisonDto })
  comparison(
    @Req() req: Request & { actor: Actor },
    @Query("term") term?: string,
  ) {
    allowQuery(req.query, ["term"]);
    return this.service.comparison(req.actor, term);
  }

  @Get(":yearId/statistics")
  @ApiParam({ name: "yearId", type: Number })
  @ApiQuery(TERM_QUERY)
  @ApiOkResponse({ type: YearStatisticsDto })
  statistics(
    @Req() req: Request & { actor: Actor },
    @Param("yearId", ParseIntPipe) yearId: number,
    @Query("term") term?: string,
  ) {
    allowQuery(req.query, ["term"]);
    return this.service.statistics(req.actor, yearId, term);
  }

  @Get(":yearId/export.xlsx")
  @ApiParam({ name: "yearId", type: Number })
  @ApiQuery(TERM_QUERY)
  @ApiProduces(XLSX)
  @ApiOkResponse({
    schema: { type: "string", format: "binary" },
    description: "Excel workbook",
  })
  async export(
    @Req() req: Request & { actor: Actor },
    @Param("yearId", ParseIntPipe) yearId: number,
    @Query("term") term?: string,
  ) {
    allowQuery(req.query, ["term"]);
    const file = await this.service.export(req.actor, yearId, term);
    return new StreamableFile(file.bytes, {
      type: XLSX,
      disposition: `attachment; filename="${file.filename}"`,
    });
  }
}
