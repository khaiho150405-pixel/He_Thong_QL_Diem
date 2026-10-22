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
import { EnrollmentsService } from "../application/service.js";

const date = "^[0-9]{4}-[0-9]{2}-[0-9]{2}$";
const enrollmentStatuses = [
  "DANG_HOC",
  "LEN_LOP",
  "LUU_BAN",
  "DA_CHUYEN_LOP",
  "NGHI_HOC",
  "TOT_NGHIEP",
];

export class PromotionClassDto {
  @ApiProperty({ type: Number }) id!: number;
  @ApiProperty({ type: String }) name!: string;
  @ApiProperty({ type: Number }) grade!: number;
}

export class PromotionSourceClassDto extends PromotionClassDto {
  @ApiProperty({ type: Number }) yearId!: number;
  @ApiProperty({ type: String }) yearName!: string;
}

export class PromotionTargetYearDto {
  @ApiProperty({ type: Number }) id!: number;
  @ApiProperty({ type: String }) name!: string;
  @ApiProperty({ type: String, pattern: date }) startDate!: string;
}

export class PromotionPreviewItemDto {
  @ApiProperty({ type: Number }) studentId!: number;
  @ApiProperty({ type: String }) studentName!: string;
  @ApiProperty({ type: Number, description: "STT trong lớp nguồn" })
  order!: number;
  @ApiProperty({ type: String, enum: ["LEN_LOP", "TOT_NGHIEP"] })
  suggestedAction!: string;
  @ApiProperty({
    type: Number,
    nullable: true,
    description: "Lớp khối +1 cùng hậu tố (10A1 → 11A1); null nếu không có",
  })
  suggestedTargetClassId!: number | null;
  @ApiProperty({ type: Boolean }) alreadyEnrolledInTargetYear!: boolean;
}

export class PromotionPreviewDto {
  @ApiProperty({ type: PromotionSourceClassDto })
  sourceClass!: PromotionSourceClassDto;
  @ApiProperty({ type: PromotionTargetYearDto })
  targetYear!: PromotionTargetYearDto;
  @ApiProperty({ type: [PromotionClassDto] })
  targetClasses!: PromotionClassDto[];
  @ApiProperty({ type: [PromotionPreviewItemDto] })
  items!: PromotionPreviewItemDto[];
}

export class PromotionItemInput {
  @ApiProperty({ type: Number }) studentId!: number;
  @ApiProperty({
    type: String,
    enum: ["LEN_LOP", "LUU_BAN", "TOT_NGHIEP", "NGHI_HOC"],
  })
  action!: string;
  @ApiProperty({
    type: Number,
    required: false,
    nullable: true,
    description:
      "Bắt buộc với LEN_LOP/LUU_BAN; không được gửi với TOT_NGHIEP/NGHI_HOC",
  })
  targetClassId?: number | null;
  @ApiProperty({
    type: String,
    required: false,
    nullable: true,
    maxLength: 500,
  })
  reason?: string | null;
}

export class PromotionInput {
  @ApiProperty({ type: Number }) targetYearId!: number;
  @ApiProperty({ type: [PromotionItemInput], minItems: 1, maxItems: 100 })
  items!: PromotionItemInput[];
}

export class PromotionResultDto {
  @ApiProperty({ type: Number }) processed!: number;
  @ApiProperty({ type: Number }) promoted!: number;
  @ApiProperty({ type: Number }) retained!: number;
  @ApiProperty({ type: Number }) graduated!: number;
  @ApiProperty({ type: Number }) withdrawn!: number;
}

export class EnrollmentDto {
  @ApiProperty({ type: String }) id!: string;
  @ApiProperty({ type: Number }) classId!: number;
  @ApiProperty({ type: String }) className!: string;
  @ApiProperty({ type: Number }) grade!: number;
  @ApiProperty({ type: Number }) yearId!: number;
  @ApiProperty({ type: String }) yearName!: string;
  @ApiProperty({ type: String, pattern: date }) fromDate!: string;
  @ApiProperty({ type: String, pattern: date, nullable: true })
  toDate!: string | null;
  @ApiProperty({ type: String, enum: enrollmentStatuses }) status!: string;
  @ApiProperty({ type: String, nullable: true }) reason!: string | null;
  @ApiProperty({ type: String, nullable: true }) actorName!: string | null;
  @ApiProperty({ type: String, format: "date-time" }) createdAt!: string;
}

export class EnrollmentListDto {
  @ApiProperty({ type: [EnrollmentDto] }) items!: EnrollmentDto[];
}

export class TransferInput {
  @ApiProperty({ type: Number }) targetClassId!: number;
  @ApiProperty({ type: String, pattern: date }) effectiveDate!: string;
  @ApiProperty({ type: String, minLength: 1, maxLength: 500 }) reason!: string;
}

export class WithdrawInput {
  @ApiProperty({ type: String, pattern: date }) effectiveDate!: string;
  @ApiProperty({ type: String, minLength: 1, maxLength: 500 }) reason!: string;
}

export class ReenrollInput {
  @ApiProperty({ type: Number }) classId!: number;
  @ApiProperty({ type: String, pattern: date }) effectiveDate!: string;
  @ApiProperty({ type: String, minLength: 1, maxLength: 500 }) reason!: string;
}

export class AffectedGradebookDto {
  @ApiProperty({ type: Number }) id!: number;
  @ApiProperty({ type: String }) subjectName!: string;
  @ApiProperty({ type: String }) termName!: string;
}

export class TransferResultDto {
  @ApiProperty({ type: EnrollmentDto }) enrollment!: EnrollmentDto;
  @ApiProperty({
    type: [AffectedGradebookDto],
    description:
      "Bảng điểm của lớp mới thuộc các học kỳ từ ngày hiệu lực; ô điểm không được tự tạo",
  })
  affectedGradebooks!: AffectedGradebookDto[];
}

export class EnrollmentResultDto {
  @ApiProperty({ type: EnrollmentDto }) enrollment!: EnrollmentDto;
}

@ApiTags("enrollments")
@Controller("classes/:id")
export class ClassPromotionController {
  constructor(
    @Inject(EnrollmentsService) private readonly service: EnrollmentsService,
  ) {}

  @Get("promotion-preview")
  @ApiParam({ name: "id", type: Number })
  @ApiQuery({ name: "targetYearId", type: Number, required: true })
  @ApiOkResponse({ type: PromotionPreviewDto })
  preview(
    @Req() req: Request & { actor: Actor },
    @Param("id", ParseIntPipe) id: number,
    @Query("targetYearId") targetYearId?: string,
  ) {
    return this.service.preview(req.actor, id, targetYearId);
  }

  @Post("promotion")
  @HttpCode(200)
  @ApiParam({ name: "id", type: Number })
  @ApiHeader({ name: "x-idempotency-key", required: true })
  @ApiBody({ type: PromotionInput })
  @ApiOkResponse({ type: PromotionResultDto })
  promote(
    @Req() req: Request & { actor: Actor },
    @Param("id", ParseIntPipe) id: number,
    @Headers("x-idempotency-key") key: string,
    @Body() body: unknown,
  ) {
    return this.service.promote(req.actor, id, key, body);
  }
}

@ApiTags("enrollments")
@Controller("students/:id")
export class StudentEnrollmentsController {
  constructor(
    @Inject(EnrollmentsService) private readonly service: EnrollmentsService,
  ) {}

  @Get("enrollments")
  @ApiParam({ name: "id", type: Number })
  @ApiOkResponse({ type: EnrollmentListDto })
  list(
    @Req() req: Request & { actor: Actor },
    @Param("id", ParseIntPipe) id: number,
  ) {
    return this.service.list(req.actor, id);
  }

  @Post("transfer")
  @HttpCode(200)
  @ApiParam({ name: "id", type: Number })
  @ApiHeader({ name: "x-idempotency-key", required: true })
  @ApiBody({ type: TransferInput })
  @ApiOkResponse({ type: TransferResultDto })
  transfer(
    @Req() req: Request & { actor: Actor },
    @Param("id", ParseIntPipe) id: number,
    @Headers("x-idempotency-key") key: string,
    @Body() body: unknown,
  ) {
    return this.service.transfer(req.actor, id, key, body);
  }

  @Post("withdraw")
  @HttpCode(200)
  @ApiParam({ name: "id", type: Number })
  @ApiHeader({ name: "x-idempotency-key", required: true })
  @ApiBody({ type: WithdrawInput })
  @ApiOkResponse({ type: EnrollmentResultDto })
  withdraw(
    @Req() req: Request & { actor: Actor },
    @Param("id", ParseIntPipe) id: number,
    @Headers("x-idempotency-key") key: string,
    @Body() body: unknown,
  ) {
    return this.service.withdraw(req.actor, id, key, body);
  }

  @Post("reenroll")
  @HttpCode(200)
  @ApiParam({ name: "id", type: Number })
  @ApiHeader({ name: "x-idempotency-key", required: true })
  @ApiBody({ type: ReenrollInput })
  @ApiOkResponse({ type: EnrollmentResultDto })
  reenroll(
    @Req() req: Request & { actor: Actor },
    @Param("id", ParseIntPipe) id: number,
    @Headers("x-idempotency-key") key: string,
    @Body() body: unknown,
  ) {
    return this.service.reenroll(req.actor, id, key, body);
  }
}
