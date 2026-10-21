import {
  ArgumentsHost,
  Body,
  Catch,
  Controller,
  ExceptionFilter,
  Get,
  Headers,
  HttpCode,
  Inject,
  Param,
  ParseIntPipe,
  Post,
  Put,
  Req,
  UseFilters,
} from "@nestjs/common";
import {
  ApiBody,
  ApiHeader,
  ApiOkResponse,
  ApiParam,
  ApiProperty,
  ApiTags,
} from "@nestjs/swagger";
import type { Request, Response } from "express";
import type { Actor } from "../../authorization/application/policy.js";
import { DeadlineException } from "../application/deadline-errors.js";
import { GradebooksService } from "../application/service.js";

const types = ["TX", "GK", "CK"];

/** Envelope lỗi ổn định (`code`, `message`, `details`, `requestId`) với mã lỗi riêng của lịch nhập điểm. */
@Catch(DeadlineException)
export class DeadlineErrorFilter implements ExceptionFilter {
  catch(error: DeadlineException, host: ArgumentsHost): void {
    const response = host.switchToHttp().getResponse<Response>();
    response.status(error.getStatus()).json({
      code: error.code,
      message: error.message,
      details: error.details,
      requestId: response.getHeader("x-request-id"),
    });
  }
}

export class SemesterDeadlineDto {
  @ApiProperty({ type: String, enum: types }) type!: string;
  @ApiProperty({ type: String, format: "date-time", nullable: true })
  opensAt!: string | null;
  @ApiProperty({ type: String, format: "date-time", nullable: true })
  closesAt!: string | null;
  @ApiProperty({
    type: Number,
    minimum: 0,
    description: "0 khi học kỳ chưa đặt lịch cho loại điểm này",
  })
  version!: number;
  @ApiProperty({ type: Boolean, description: "Đã qua hạn đóng" })
  expired!: boolean;
}

export class SemesterDeadlinesDto {
  @ApiProperty({
    type: [SemesterDeadlineDto],
    description: "Luôn 3 phần tử theo thứ tự TX, GK, CK",
  })
  items!: SemesterDeadlineDto[];
}

export class SemesterDeadlineInput {
  @ApiProperty({ type: String, format: "date-time" }) opensAt!: string;
  @ApiProperty({ type: String, format: "date-time" }) closesAt!: string;
  @ApiProperty({ type: Number, minimum: 0 }) expectedVersion!: number;
}

export class InitializedGradebookDto {
  @ApiProperty({ type: Number }) gradebookId!: number;
  @ApiProperty({ type: Number }) classId!: number;
  @ApiProperty({ type: String }) className!: string;
  @ApiProperty({ type: Number }) subjectId!: number;
  @ApiProperty({ type: String }) subjectName!: string;
}

export class SkippedGradebookDto {
  @ApiProperty({ type: Number }) classId!: number;
  @ApiProperty({ type: String }) className!: string;
  @ApiProperty({ type: Number }) subjectId!: number;
  @ApiProperty({ type: String }) subjectName!: string;
  @ApiProperty({ type: String, enum: ["EMPTY_ROSTER", "NO_COMPONENTS"] })
  reason!: string;
}

export class InitializeGradebooksResultDto {
  @ApiProperty({ type: [InitializedGradebookDto] })
  created!: InitializedGradebookDto[];
  @ApiProperty({ type: [SkippedGradebookDto] })
  skipped!: SkippedGradebookDto[];
}

const issueCodes = [
  "GRADEBOOK_MISSING",
  "GRADEBOOK_NOT_LOCKED",
  "RECOGNITION_PENDING",
  "STUDENT_NOT_IN_GRADEBOOK",
  "RESULTS_MISSING",
  "COLUMNS_WITHOUT_DEADLINE",
];

export class PublishIssueDto {
  @ApiProperty({ type: String, enum: issueCodes }) code!: string;
  @ApiProperty({ type: String, enum: ["BLOCKING", "WARNING"] })
  severity!: string;
  @ApiProperty({ type: Number }) classId!: number;
  @ApiProperty({ type: String }) className!: string;
  @ApiProperty({ type: Number }) subjectId!: number;
  @ApiProperty({ type: String }) subjectName!: string;
  @ApiProperty({ type: Number, nullable: true }) gradebookId!: number | null;
  @ApiProperty({ type: [Number], nullable: true })
  studentIds!: number[] | null;
  @ApiProperty({ type: Number, nullable: true }) count!: number | null;
}

export class PublishReadinessDto {
  @ApiProperty({ type: Boolean }) ready!: boolean;
  @ApiProperty({ type: [PublishIssueDto] }) issues!: PublishIssueDto[];
}

@ApiTags("semesters")
@UseFilters(DeadlineErrorFilter)
@Controller("catalog/semesters/:id")
export class SemesterDeadlinesController {
  constructor(
    @Inject(GradebooksService) private readonly service: GradebooksService,
  ) {}

  @Get("deadlines")
  @ApiParam({ name: "id", type: Number })
  @ApiOkResponse({ type: SemesterDeadlinesDto })
  list(
    @Req() req: Request & { actor: Actor },
    @Param("id", ParseIntPipe) id: number,
  ) {
    return this.service.semesterDeadlines(req.actor, id);
  }

  @Put("deadlines/:type")
  @ApiParam({ name: "id", type: Number })
  @ApiParam({ name: "type", type: String, enum: types })
  @ApiBody({ type: SemesterDeadlineInput })
  @ApiOkResponse({ type: SemesterDeadlineDto })
  set(
    @Req() req: Request & { actor: Actor },
    @Param("id", ParseIntPipe) id: number,
    @Param("type") type: string,
    @Body() body: unknown,
  ) {
    return this.service.setSemesterDeadline(req.actor, id, type, body);
  }

  @Post("gradebooks/initialize")
  @HttpCode(200)
  @ApiParam({ name: "id", type: Number })
  @ApiHeader({ name: "x-idempotency-key", required: true })
  @ApiOkResponse({ type: InitializeGradebooksResultDto })
  initialize(
    @Req() req: Request & { actor: Actor },
    @Param("id", ParseIntPipe) id: number,
    @Headers("x-idempotency-key") key: string,
  ) {
    return this.service.initializeSemesterGradebooks(req.actor, id, key);
  }

  @Get("publish-readiness")
  @ApiParam({ name: "id", type: Number })
  @ApiOkResponse({ type: PublishReadinessDto })
  publishReadiness(
    @Req() req: Request & { actor: Actor },
    @Param("id", ParseIntPipe) id: number,
  ) {
    return this.service.publishReadiness(req.actor, id);
  }
}
