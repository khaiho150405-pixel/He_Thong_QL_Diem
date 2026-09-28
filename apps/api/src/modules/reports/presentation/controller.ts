import {
  Controller,
  Get,
  Inject,
  Param,
  ParseIntPipe,
  Req,
  StreamableFile,
} from "@nestjs/common";
import {
  ApiOkResponse,
  ApiParam,
  ApiProduces,
  ApiProperty,
  ApiTags,
} from "@nestjs/swagger";
import type { Request } from "express";
import type { Actor } from "../../authorization/application/policy.js";
import { ReportsService } from "../application/service.js";

export class DistributionItemDto {
  @ApiProperty({ type: String }) classification!: string;
  @ApiProperty({ type: Number }) students!: number;
}

export class GradebookSummaryDto {
  @ApiProperty({ type: Number }) gradebookId!: number;
  @ApiProperty({ type: Number }) students!: number;
  @ApiProperty({ type: String, nullable: true }) average!: string | null;
  @ApiProperty({ type: String, nullable: true }) highest!: string | null;
  @ApiProperty({ type: String, nullable: true }) lowest!: string | null;
  @ApiProperty({ type: Number }) passed!: number;
  @ApiProperty({ type: Number }) failed!: number;
  @ApiProperty({ type: [DistributionItemDto] })
  distribution!: DistributionItemDto[];
}

@ApiTags("reports")
@Controller("reports/gradebooks/:gradebookId")
export class ReportsController {
  constructor(
    @Inject(ReportsService) private readonly service: ReportsService,
  ) {}

  @Get("summary")
  @ApiParam({ name: "gradebookId", type: Number })
  @ApiOkResponse({ type: GradebookSummaryDto })
  summary(
    @Req() req: Request & { actor: Actor },
    @Param("gradebookId", ParseIntPipe) gradebookId: number,
  ) {
    return this.service.summary(req.actor, gradebookId);
  }

  @Get("export.xlsx")
  @ApiParam({ name: "gradebookId", type: Number })
  @ApiProduces(
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
  )
  @ApiOkResponse({
    schema: { type: "string", format: "binary" },
    description: "Excel workbook",
  })
  async export(
    @Req() req: Request & { actor: Actor },
    @Param("gradebookId", ParseIntPipe) gradebookId: number,
  ) {
    const file = await this.service.export(req.actor, gradebookId);
    return new StreamableFile(file.bytes, {
      type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      disposition: `attachment; filename="${file.filename}"`,
    });
  }
}

export class AdminKpiDto {
  @ApiProperty({ type: Number }) totalStudents!: number;
  @ApiProperty({ type: Number }) totalClasses!: number;
  @ApiProperty({ type: Number }) totalTeachers!: number;
  @ApiProperty({ type: Number }) lockedGradebooks!: number;
  @ApiProperty({ type: Number }) totalGradebooks!: number;
  @ApiProperty({ type: Number }) completionRate!: number;
  @ApiProperty({ type: Number }) pendingOcrTickets!: number;
}

export class AdminGradeDistributionDto {
  @ApiProperty({ type: String }) label!: string;
  @ApiProperty({ type: String }) code!: string;
  @ApiProperty({ type: Number }) count!: number;
  @ApiProperty({ type: Number }) percentage!: number;
  @ApiProperty({ type: String }) color!: string;
}

export class AdminGradeLevelProgressDto {
  @ApiProperty({ type: Number }) grade!: number;
  @ApiProperty({ type: String }) title!: string;
  @ApiProperty({ type: Number }) lockedClasses!: number;
  @ApiProperty({ type: Number }) totalClasses!: number;
  @ApiProperty({ type: Number }) percentage!: number;
}

export class AdminOcrAccuracyDto {
  @ApiProperty({ type: Number }) totalCells!: number;
  @ApiProperty({ type: Number }) greenCount!: number;
  @ApiProperty({ type: Number }) yellowCount!: number;
  @ApiProperty({ type: Number }) redCount!: number;
  @ApiProperty({ type: Number }) accuracyRate!: number;
}

export class AdminRecentActivityDto {
  @ApiProperty({ type: String }) className!: string;
  @ApiProperty({ type: String }) subjectName!: string;
  @ApiProperty({ type: String }) teacherName!: string;
  @ApiProperty({ type: String }) status!: string;
  @ApiProperty({ type: String }) updatedAt!: string;
}

export class AdminOverviewDto {
  @ApiProperty({ type: AdminKpiDto }) kpi!: AdminKpiDto;
  @ApiProperty({ type: [AdminGradeDistributionDto] })
  gradeDistribution!: AdminGradeDistributionDto[];
  @ApiProperty({ type: [AdminGradeLevelProgressDto] })
  gradeLevelProgress!: AdminGradeLevelProgressDto[];
  @ApiProperty({ type: AdminOcrAccuracyDto }) ocrAccuracy!: AdminOcrAccuracyDto;
  @ApiProperty({ type: [AdminRecentActivityDto] })
  recentActivities!: AdminRecentActivityDto[];
}

@ApiTags("reports")
@Controller("reports/admin")
export class AdminReportsController {
  constructor(
    @Inject(ReportsService) private readonly service: ReportsService,
  ) {}

  @Get("overview")
  @ApiOkResponse({ type: AdminOverviewDto })
  overview(@Req() req: Request & { actor: Actor }) {
    return this.service.adminOverview(req.actor);
  }
}
