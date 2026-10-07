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
  Put,
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
import { GradebooksService } from "../application/service.js";

/* ── DTO ── */

export class GradebookDto {
  @ApiProperty({ type: Number }) id!: number;
  @ApiProperty({ type: Number }) classId!: number;
  @ApiProperty({ type: Number }) subjectId!: number;
  @ApiProperty({ type: Number }) termId!: number;
  @ApiProperty({ type: String }) className!: string;
  @ApiProperty({ type: String }) subjectName!: string;
  @ApiProperty({ type: String }) termName!: string;
  @ApiProperty({ type: String, enum: ["DANG_NHAP_LIEU", "DA_CHOT"] })
  status!: string;
  @ApiProperty({ type: Number }) version!: number;
}

export class GradebookListDto {
  @ApiProperty({ type: [GradebookDto] }) items!: GradebookDto[];
  @ApiProperty({ type: Number, nullable: true }) nextCursor!: number | null;
}

export class GradeCellDto {
  @ApiProperty({ type: String }) id!: string;
  @ApiProperty({ type: Number }) studentId!: number;
  @ApiProperty({ type: String }) studentName!: string;
  @ApiProperty({
    type: Number,
    nullable: true,
    description: "STT trong lớp theo thứ tự tên; null khi học sinh đã nghỉ",
  })
  stt!: number | null;
  @ApiProperty({ type: Boolean }) active!: boolean;
  @ApiProperty({ type: Number }) componentId!: number;
  @ApiProperty({ type: String }) componentName!: string;
  @ApiProperty({ type: String }) coefficient!: string;
  @ApiProperty({ type: Boolean }) required!: boolean;
  @ApiProperty({ type: Number }) displayOrder!: number;
  @ApiProperty({ type: Boolean, required: false }) openForInput?: boolean;
  @ApiProperty({ type: Boolean, required: false }) columnLocked?: boolean;
  @ApiProperty({ type: Boolean, required: false }) passFail?: boolean;
  @ApiProperty({ type: String, required: false, nullable: true }) opensAt?:
    | string
    | null;
  @ApiProperty({ type: String, required: false, nullable: true }) closesAt?:
    | string
    | null;
  @ApiProperty({ type: Number, required: false }) deadlineVersion?: number;
  @ApiProperty({ type: String, nullable: true }) value!: string | null;
  @ApiProperty({
    type: String,
    enum: ["CHUA_CO", "CHO_DOI_CHIEU", "DA_DUYET"],
  })
  status!: string;
  @ApiProperty({ type: String, enum: ["NHAP_TAY", "NHAN_DIEN"] })
  source!: string;
}

export class CellsResponseDto {
  @ApiProperty({ type: GradebookDto }) book!: GradebookDto;
  @ApiProperty({ type: [GradeCellDto] }) items!: GradeCellDto[];
  @ApiProperty({ type: String, nullable: true }) nextCursor!: string | null;
}

export class CreateGradebookInput {
  @ApiProperty({ type: Number }) classId!: number;
  @ApiProperty({ type: Number }) subjectId!: number;
  @ApiProperty({ type: Number }) termId!: number;
}

export class GradeChangeInput {
  @ApiProperty({ type: String, description: "bigint cell ID" }) cellId!: string;
  @ApiProperty({
    type: String,
    nullable: true,
    pattern: "^(10[.]0|[0-9][.][0-9])$",
    description: "0.0–10.0 step 0.1, or null to clear",
  })
  value!: string | null;
  @ApiProperty({ type: String, maxLength: 500 }) reason!: string;
}

export class BatchUpdateInput {
  @ApiProperty({ type: Number, minimum: 0 }) expectedVersion!: number;
  @ApiProperty({ type: [GradeChangeInput], minItems: 1, maxItems: 100 })
  changes!: GradeChangeInput[];
}

export class UpdatedCellDto {
  @ApiProperty({ type: String }) id!: string;
  @ApiProperty({ type: String, nullable: true }) value!: string | null;
  @ApiProperty({ type: String, enum: ["CHUA_CO", "CHO_DOI_CHIEU", "DA_DUYET"] })
  status!: string;
  @ApiProperty({ type: String, enum: ["NHAP_TAY", "NHAN_DIEN"] })
  source!: string;
}
export class BatchUpdateResultDto {
  @ApiProperty({ type: [UpdatedCellDto] }) items!: UpdatedCellDto[];
  @ApiProperty({ type: Number }) bookId!: number;
  @ApiProperty({ type: Number }) version!: number;
}

export class GradeDeadlineInput {
  @ApiProperty({ type: String, format: "date-time" }) opensAt!: string;
  @ApiProperty({ type: String, format: "date-time" }) closesAt!: string;
  @ApiProperty({ type: Number, minimum: 0 }) expectedVersion!: number;
}

export class LockInput {
  @ApiProperty({ type: Number }) expectedVersion!: number;
}

export class GradeHistoryEntryDto {
  @ApiProperty({ type: String }) id!: string;
  @ApiProperty({ type: String }) cellId!: string;
  @ApiProperty({ type: Number }) editor!: number;
  @ApiProperty({ type: String, nullable: true }) oldValue!: string | null;
  @ApiProperty({ type: String, nullable: true }) newValue!: string | null;
  @ApiProperty({ type: String }) reason!: string;
  @ApiProperty({ type: String }) timestamp!: string;
}

export class GradeHistoryDto {
  @ApiProperty({ type: [GradeHistoryEntryDto] }) items!: GradeHistoryEntryDto[];
  @ApiProperty({ type: String, nullable: true }) nextCursor!: string | null;
}
export class GradebookHistoryEntryDto extends GradeHistoryEntryDto {
  @ApiProperty({ type: String }) studentName!: string;
  @ApiProperty({ type: String }) componentName!: string;
}
export class GradebookHistoryDto {
  @ApiProperty({ type: [GradebookHistoryEntryDto] })
  items!: GradebookHistoryEntryDto[];
  @ApiProperty({ type: String, nullable: true }) nextCursor!: string | null;
}

/* ── Controller ── */

@ApiTags("gradebooks")
@Controller("gradebooks")
export class GradebooksController {
  constructor(
    @Inject(GradebooksService) private readonly service: GradebooksService,
  ) {}

  @Get()
  @ApiOkResponse({ type: GradebookListDto })
  @ApiQuery({ name: "cursor", type: Number, required: false })
  list(
    @Req() req: Request & { actor: Actor },
    @Query("cursor") cursor?: string,
  ) {
    return this.service.list(req.actor, cursor ? Number(cursor) : 0);
  }

  @Post()
  @HttpCode(200)
  @ApiBody({ type: CreateGradebookInput })
  @ApiOkResponse({ type: GradebookDto })
  create(@Req() req: Request & { actor: Actor }, @Body() body: unknown) {
    return this.service.create(req.actor, body);
  }

  @Get(":id/cells")
  @ApiOkResponse({ type: CellsResponseDto })
  @ApiParam({ name: "id", type: Number })
  @ApiQuery({ name: "cursor", type: String, required: false })
  cells(
    @Req() req: Request & { actor: Actor },
    @Param("id", ParseIntPipe) id: number,
    @Query("cursor") cursor?: string,
  ) {
    return this.service.cells(req.actor, id, cursor ?? "0");
  }

  @Put(":id/grades")
  @ApiBody({ type: BatchUpdateInput })
  @ApiOkResponse({ type: BatchUpdateResultDto })
  @ApiParam({ name: "id", type: Number })
  @ApiHeader({ name: "x-idempotency-key", required: true })
  batchUpdate(
    @Req() req: Request & { actor: Actor },
    @Param("id", ParseIntPipe) id: number,
    @Headers("x-idempotency-key") idemKey: string,
    @Body() body: unknown,
  ) {
    return this.service.batchUpdate(req.actor, id, idemKey, body);
  }

  @Put(":id/components/:componentId/deadline")
  @HttpCode(204)
  @ApiBody({ type: GradeDeadlineInput })
  @ApiParam({ name: "id", type: Number })
  @ApiParam({ name: "componentId", type: Number })
  setDeadline(
    @Req() req: Request & { actor: Actor },
    @Param("id", ParseIntPipe) id: number,
    @Param("componentId", ParseIntPipe) componentId: number,
    @Body() input: unknown,
  ) {
    return this.service.setDeadline(req.actor, id, componentId, input);
  }

  @Post(":id/components/:componentId/lock")
  @HttpCode(200)
  @ApiBody({ type: LockInput })
  @ApiOkResponse({ type: GradebookDto })
  @ApiParam({ name: "id", type: Number })
  @ApiParam({ name: "componentId", type: Number })
  @ApiHeader({ name: "x-idempotency-key", required: true })
  lockColumn(
    @Req() req: Request & { actor: Actor },
    @Param("id", ParseIntPipe) id: number,
    @Param("componentId", ParseIntPipe) componentId: number,
    @Headers("x-idempotency-key") key: string,
    @Body() body: unknown,
  ) {
    return this.service.lockColumn(req.actor, id, componentId, key, body);
  }
  @Post(":id/lock")
  @HttpCode(200)
  @ApiBody({ type: LockInput })
  @ApiOkResponse({ type: GradebookDto })
  @ApiParam({ name: "id", type: Number })
  @ApiHeader({ name: "x-idempotency-key", required: true })
  lock(
    @Req() req: Request & { actor: Actor },
    @Param("id", ParseIntPipe) id: number,
    @Headers("x-idempotency-key") idemKey: string,
    @Body() body: unknown,
  ) {
    return this.service.lock(req.actor, id, idemKey, body);
  }

  @Post(":id/sync-roster")
  @HttpCode(200)
  @ApiBody({ type: LockInput })
  @ApiOkResponse({ type: GradebookDto })
  @ApiParam({ name: "id", type: Number })
  @ApiHeader({ name: "x-idempotency-key", required: true })
  syncRoster(
    @Req() req: Request & { actor: Actor },
    @Param("id", ParseIntPipe) id: number,
    @Headers("x-idempotency-key") key: string,
    @Body() body: unknown,
  ) {
    return this.service.syncRoster(req.actor, id, key, body);
  }

  @Get(":id/history")
  @ApiOkResponse({ type: GradebookHistoryDto })
  @ApiParam({ name: "id", type: Number })
  @ApiQuery({ name: "cursor", type: String, required: false })
  historyAll(
    @Req() req: Request & { actor: Actor },
    @Param("id", ParseIntPipe) id: number,
    @Query("cursor") cursor?: string,
  ) {
    return this.service.historyAll(req.actor, id, cursor ?? "0");
  }

  @Get(":id/cells/:cellId/history")
  @ApiOkResponse({ type: GradeHistoryDto })
  @ApiParam({ name: "id", type: Number })
  @ApiParam({ name: "cellId", type: String })
  @ApiQuery({ name: "cursor", type: String, required: false })
  history(
    @Req() req: Request & { actor: Actor },
    @Param("id", ParseIntPipe) id: number,
    @Param("cellId") cellId: string,
    @Query("cursor") cursor?: string,
  ) {
    return this.service.history(req.actor, id, cellId, cursor ?? "0");
  }
}
