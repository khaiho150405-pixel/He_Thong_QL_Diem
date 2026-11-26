import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Inject,
  Param,
  ParseIntPipe,
  Post,
  Put,
  Query,
  Req,
} from "@nestjs/common";
import {
  ApiBody,
  ApiOkResponse,
  ApiParam,
  ApiProperty,
  ApiQuery,
  ApiTags,
} from "@nestjs/swagger";
import type { Request } from "express";
import { allowQuery } from "../../../common/query.js";
import type { Actor } from "../../authorization/application/policy.js";
import { YearsService } from "../application/years.js";
import { YearClosingService } from "../application/closing.js";
export class YearsInput {
  @ApiProperty({ type: String }) ten!: string;
  @ApiProperty({ type: String, pattern: "^[0-9]{4}-[0-9]{2}-[0-9]{2}$" })
  ngay_bat_dau!: string;
  @ApiProperty({ type: String, pattern: "^[0-9]{4}-[0-9]{2}-[0-9]{2}$" })
  ngay_ket_thuc!: string;
  @ApiProperty({ type: Boolean }) hien_hanh!: boolean;
}
export class YearsDto extends YearsInput {
  @ApiProperty({ type: String }) label!: string;
  @ApiProperty({ type: Number }) ma_nam_hoc!: number;
  @ApiProperty({
    type: String,
    nullable: true,
    required: false,
    description: "Thời điểm đóng năm học; null khi năm còn mở",
  })
  da_dong_luc?: string | null;
}
export class YearClosingInput {
  @ApiProperty({ type: String, minLength: 1, maxLength: 500 }) reason!: string;
}
export class YearClosingIssueDto {
  @ApiProperty({ type: String }) code!: string;
  @ApiProperty({ type: String, description: "BLOCKING hoặc WARNING" })
  severity!: string;
  @ApiProperty({ type: String }) label!: string;
  @ApiProperty({ type: Number }) count!: number;
}
export class YearClosingEventDto {
  @ApiProperty({ type: String, description: "DONG hoặc MO_LAI" })
  action!: string;
  @ApiProperty({ type: String }) reason!: string;
  @ApiProperty({ type: String }) actor!: string;
  @ApiProperty({ type: String }) at!: string;
}
export class YearClosingDto {
  @ApiProperty({ type: Number }) yearId!: number;
  @ApiProperty({ type: String, nullable: true }) closedAt!: string | null;
  @ApiProperty({ type: Boolean }) ready!: boolean;
  @ApiProperty({ type: [YearClosingIssueDto] }) issues!: YearClosingIssueDto[];
  @ApiProperty({ type: [YearClosingEventDto] })
  history!: YearClosingEventDto[];
}
export class YearPendingSummaryDto {
  @ApiProperty({ type: Number, description: "Bảng điểm chưa khóa" })
  openGradebooks!: number;
  @ApiProperty({
    type: Number,
    description: "Phiếu nhận dạng đang xử lý hoặc chờ đối chiếu",
  })
  pendingRecognitionTickets!: number;
  @ApiProperty({ type: Number, description: "Học kỳ chưa công bố" })
  unpublishedSemesters!: number;
}
export class YearsPage {
  @ApiProperty({ type: [YearsDto] }) items!: YearsDto[];
  @ApiProperty({ type: String, nullable: true }) nextCursor!: string | null;
}
@ApiTags("years")
@Controller("catalog/years")
export class YearsController {
  constructor(
    @Inject(YearsService) private readonly service: YearsService,
    @Inject(YearClosingService)
    private readonly yearClosing: YearClosingService,
  ) {}
  @Get()
  @ApiQuery({ name: "cursor", required: false, type: String })
  @ApiQuery({ name: "q", required: false, type: String })
  @ApiQuery({
    name: "limit",
    required: false,
    type: Number,
    description: "Số dòng mỗi trang, từ 1 đến 500; vắng = 50",
  })
  @ApiOkResponse({ type: YearsPage })
  list(
    @Req() req: Request & { actor: Actor },
    @Query("cursor") cursor?: string,
    @Query("q") q?: string,
    @Query("limit") limit?: string,
  ) {
    allowQuery(req.query, ["cursor", "q", "limit"]);
    return this.service.list(req.actor, cursor, q, undefined, limit);
  }
  @Get(":id/pending-summary")
  @ApiParam({ name: "id", type: Number })
  @ApiOkResponse({ type: YearPendingSummaryDto })
  pendingSummary(
    @Req() req: Request & { actor: Actor },
    @Param("id", ParseIntPipe) id: number,
  ) {
    return this.service.pendingSummary(req.actor, id);
  }
  @Get(":id/closing")
  @ApiParam({ name: "id", type: Number })
  @ApiOkResponse({ type: YearClosingDto })
  closing(
    @Req() req: Request & { actor: Actor },
    @Param("id", ParseIntPipe) id: number,
  ) {
    return this.yearClosing.status(req.actor, id);
  }
  @Post(":id/close")
  @HttpCode(200)
  @ApiParam({ name: "id", type: Number })
  @ApiBody({ type: YearClosingInput })
  @ApiOkResponse({ type: YearClosingDto })
  close(
    @Req() req: Request & { actor: Actor },
    @Param("id", ParseIntPipe) id: number,
    @Body() input: unknown,
  ) {
    return this.yearClosing.change(req.actor, id, true, input);
  }
  @Post(":id/reopen")
  @HttpCode(200)
  @ApiParam({ name: "id", type: Number })
  @ApiBody({ type: YearClosingInput })
  @ApiOkResponse({ type: YearClosingDto })
  reopen(
    @Req() req: Request & { actor: Actor },
    @Param("id", ParseIntPipe) id: number,
    @Body() input: unknown,
  ) {
    return this.yearClosing.change(req.actor, id, false, input);
  }
  @Post()
  @HttpCode(200)
  @ApiBody({ type: YearsInput })
  @ApiOkResponse({ type: YearsDto })
  create(@Req() req: Request & { actor: Actor }, @Body() input: unknown) {
    return this.service.save(req.actor, input);
  }
  @Put(":id")
  @ApiBody({ type: YearsInput })
  @ApiOkResponse({ type: YearsDto })
  @ApiParam({ name: "id", type: Number })
  update(
    @Req() req: Request & { actor: Actor },
    @Param("id", ParseIntPipe) id: number,
    @Body() input: unknown,
  ) {
    return this.service.save(req.actor, input, id);
  }
  @Delete(":id")
  @HttpCode(204)
  @ApiParam({ name: "id", type: Number })
  remove(
    @Req() req: Request & { actor: Actor },
    @Param("id", ParseIntPipe) id: number,
  ) {
    return this.service.remove(req.actor, id);
  }
}
