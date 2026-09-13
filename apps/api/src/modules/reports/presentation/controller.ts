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
