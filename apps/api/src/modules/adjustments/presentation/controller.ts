import {
  Body,
  Controller,
  Get,
  Headers,
  HttpCode,
  Inject,
  Param,
  ParseIntPipe,
  Post,
  Query,
  Req,
} from "@nestjs/common";
import {
  ApiBody,
  ApiHeader,
  ApiOkResponse,
  ApiParam,
  ApiProperty,
  ApiQuery,
  ApiTags,
} from "@nestjs/swagger";
import type { Request } from "express";
import type { Actor } from "../../authorization/application/policy.js";
import { AdjustmentsService } from "../application/service.js";

const statuses = ["CHO_DUYET", "DA_DUYET", "TU_CHOI", "DA_HUY"];
const cellStatuses = ["CHUA_CO", "CHO_DOI_CHIEU", "DA_DUYET", "MIEN"];

export class AdjustmentPersonDto {
  @ApiProperty({ type: Number }) id!: number;
  @ApiProperty({ type: String }) name!: string;
}

export class AdjustmentLineDto {
  @ApiProperty({ type: String }) cellId!: string;
  @ApiProperty({ type: Number }) studentId!: number;
  @ApiProperty({ type: String }) studentName!: string;
  @ApiProperty({ type: Number }) componentId!: number;
  @ApiProperty({ type: String }) componentName!: string;
  @ApiProperty({ type: String, nullable: true }) oldValue!: string | null;
  @ApiProperty({ type: String, enum: cellStatuses }) oldStatus!: string;
  @ApiProperty({ type: String, nullable: true }) newValue!: string | null;
  @ApiProperty({ type: Boolean }) newExempt!: boolean;
  @ApiProperty({ type: String, nullable: true }) note!: string | null;
}

export class AdjustmentDto {
  @ApiProperty({ type: String }) id!: string;
  @ApiProperty({ type: Number }) gradebookId!: number;
  @ApiProperty({ type: String }) className!: string;
  @ApiProperty({ type: String }) subjectName!: string;
  @ApiProperty({ type: String }) termName!: string;
  @ApiProperty({ type: String, enum: statuses }) status!: string;
  @ApiProperty({ type: String }) reason!: string;
  @ApiProperty({ type: AdjustmentPersonDto }) submittedBy!: AdjustmentPersonDto;
  @ApiProperty({ type: String, format: "date-time" }) submittedAt!: string;
  @ApiProperty({ type: AdjustmentPersonDto, nullable: true })
  decidedBy!: AdjustmentPersonDto | null;
  @ApiProperty({ type: String, format: "date-time", nullable: true })
  decidedAt!: string | null;
  @ApiProperty({ type: String, nullable: true }) decisionReason!: string | null;
  @ApiProperty({ type: Number }) lineCount!: number;
  @ApiProperty({ type: Number }) version!: number;
  @ApiProperty({
    type: [AdjustmentLineDto],
    required: false,
    description: "Chỉ có trong chi tiết một phiếu",
  })
  lines?: AdjustmentLineDto[];
}

export class AdjustmentListDto {
  @ApiProperty({ type: [AdjustmentDto] }) items!: AdjustmentDto[];
}

export class AdjustmentPageDto {
  @ApiProperty({ type: [AdjustmentDto] }) items!: AdjustmentDto[];
  @ApiProperty({ type: String, nullable: true }) nextCursor!: string | null;
}

export class AdjustmentChangeInput {
  @ApiProperty({ type: String, description: "bigint cell ID" }) cellId!: string;
  @ApiProperty({
    type: String,
    nullable: true,
    pattern: "^(10[.]0|[0-9][.][0-9])$",
    description: "Giá trị mới 0.0–10.0; null khi exempt = true",
  })
  value!: string | null;
  @ApiProperty({
    type: Boolean,
    description: "true = đặt Miễn (value = null); false = value bắt buộc",
  })
  exempt!: boolean;
  @ApiProperty({ type: String, nullable: true, maxLength: 200 })
  note!: string | null;
}

export class AdjustmentInput {
  @ApiProperty({ type: Number, minimum: 0 }) expectedVersion!: number;
  @ApiProperty({ type: String, minLength: 1, maxLength: 500 }) reason!: string;
  @ApiProperty({ type: [AdjustmentChangeInput], minItems: 1, maxItems: 100 })
  changes!: AdjustmentChangeInput[];
}

export class AdjustmentVersionInput {
  @ApiProperty({ type: Number, minimum: 0, description: "Version phiếu" })
  expectedVersion!: number;
}

export class AdjustmentRejectInput extends AdjustmentVersionInput {
  @ApiProperty({ type: String, minLength: 1, maxLength: 500 }) reason!: string;
}

@ApiTags("adjustments")
@Controller("gradebooks/:id/adjustments")
export class GradebookAdjustmentsController {
  constructor(
    @Inject(AdjustmentsService) private readonly service: AdjustmentsService,
  ) {}

  @Post()
  @HttpCode(200)
  @ApiParam({ name: "id", type: Number })
  @ApiHeader({ name: "x-idempotency-key", required: true })
  @ApiBody({ type: AdjustmentInput })
  @ApiOkResponse({ type: AdjustmentDto })
  submit(
    @Req() req: Request & { actor: Actor },
    @Param("id", ParseIntPipe) id: number,
    @Headers("x-idempotency-key") key: string,
    @Body() body: unknown,
  ) {
    return this.service.submit(req.actor, id, key, body);
  }

  @Get()
  @ApiParam({ name: "id", type: Number })
  @ApiOkResponse({ type: AdjustmentListDto })
  listForBook(
    @Req() req: Request & { actor: Actor },
    @Param("id", ParseIntPipe) id: number,
  ) {
    return this.service.listForBook(req.actor, id);
  }
}

@ApiTags("adjustments")
@Controller("adjustments")
export class AdjustmentsController {
  constructor(
    @Inject(AdjustmentsService) private readonly service: AdjustmentsService,
  ) {}

  @Get()
  @ApiQuery({ name: "status", enum: statuses, required: false })
  @ApiQuery({ name: "cursor", type: String, required: false })
  @ApiOkResponse({ type: AdjustmentPageDto })
  list(
    @Req() req: Request & { actor: Actor },
    @Query("status") status?: string,
    @Query("cursor") cursor?: string,
  ) {
    return this.service.list(req.actor, status, cursor);
  }

  @Get(":adjId")
  @ApiParam({ name: "adjId", type: String })
  @ApiOkResponse({ type: AdjustmentDto })
  detail(
    @Req() req: Request & { actor: Actor },
    @Param("adjId") adjId: string,
  ) {
    return this.service.detail(req.actor, adjId);
  }

  @Post(":adjId/approve")
  @HttpCode(200)
  @ApiParam({ name: "adjId", type: String })
  @ApiHeader({ name: "x-idempotency-key", required: true })
  @ApiBody({ type: AdjustmentVersionInput })
  @ApiOkResponse({ type: AdjustmentDto })
  approve(
    @Req() req: Request & { actor: Actor },
    @Param("adjId") adjId: string,
    @Headers("x-idempotency-key") key: string,
    @Body() body: unknown,
  ) {
    return this.service.approve(req.actor, adjId, key, body);
  }

  @Post(":adjId/reject")
  @HttpCode(200)
  @ApiParam({ name: "adjId", type: String })
  @ApiHeader({ name: "x-idempotency-key", required: true })
  @ApiBody({ type: AdjustmentRejectInput })
  @ApiOkResponse({ type: AdjustmentDto })
  reject(
    @Req() req: Request & { actor: Actor },
    @Param("adjId") adjId: string,
    @Headers("x-idempotency-key") key: string,
    @Body() body: unknown,
  ) {
    return this.service.reject(req.actor, adjId, key, body);
  }

  @Post(":adjId/cancel")
  @HttpCode(200)
  @ApiParam({ name: "adjId", type: String })
  @ApiHeader({ name: "x-idempotency-key", required: true })
  @ApiBody({ type: AdjustmentVersionInput })
  @ApiOkResponse({ type: AdjustmentDto })
  cancel(
    @Req() req: Request & { actor: Actor },
    @Param("adjId") adjId: string,
    @Headers("x-idempotency-key") key: string,
    @Body() body: unknown,
  ) {
    return this.service.cancel(req.actor, adjId, key, body);
  }
}
