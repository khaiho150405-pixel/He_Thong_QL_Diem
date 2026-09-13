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
import { FinalResultsService } from "../application/service.js";

export class FinalResultDto {
  @ApiProperty({ type: String }) id!: string;
  @ApiProperty({ type: Number }) studentId!: number;
  @ApiProperty({ type: String }) studentName!: string;
  @ApiProperty({ type: String, example: "8.5" }) finalScore!: string;
  @ApiProperty({ type: String, example: "GIOI" }) classification!: string;
  @ApiProperty({ type: String }) weightVersion!: string;
  @ApiProperty({ type: String }) policyVersion!: string;
  @ApiProperty({ type: String, format: "date-time" }) calculatedAt!: string;
}

export class FinalResultListDto {
  @ApiProperty({ type: [FinalResultDto] }) items!: FinalResultDto[];
  @ApiProperty({ type: String, nullable: true }) nextCursor!: string | null;
}

export class MissingComponentDto {
  @ApiProperty({ type: Number }) componentId!: number;
  @ApiProperty({ type: String }) name!: string;
}

export class SkippedStudentDto {
  @ApiProperty({ type: Number }) studentId!: number;
  @ApiProperty({ type: String }) studentName!: string;
  @ApiProperty({ type: [MissingComponentDto] })
  missingComponents!: MissingComponentDto[];
}

export class CalculateFinalResultsInput {
  @ApiProperty({ type: Number, minimum: 0 }) expectedVersion!: number;
  @ApiProperty({ type: String, minLength: 1, maxLength: 500 }) reason!: string;
}

export class CalculateFinalResultsDto {
  @ApiProperty({ type: Number }) gradebookId!: number;
  @ApiProperty({ type: Number }) gradebookVersion!: number;
  @ApiProperty({ type: String }) weightVersion!: string;
  @ApiProperty({ type: String }) policyVersion!: string;
  @ApiProperty({ type: Number }) calculatedStudents!: number;
  @ApiProperty({ type: Number }) skippedStudents!: number;
  @ApiProperty({ type: [FinalResultDto] }) results!: FinalResultDto[];
  @ApiProperty({ type: [SkippedStudentDto] }) skipped!: SkippedStudentDto[];
}

export class CalculationHistoryDto {
  @ApiProperty({ type: String }) id!: string;
  @ApiProperty({ type: String }) resultId!: string;
  @ApiProperty({ type: Number }) calculatorId!: number;
  @ApiProperty({ type: String, nullable: true }) oldScore!: string | null;
  @ApiProperty({ type: String, nullable: true })
  oldClassification!: string | null;
  @ApiProperty({ type: String }) newScore!: string;
  @ApiProperty({ type: String }) newClassification!: string;
  @ApiProperty({ type: String }) reason!: string;
  @ApiProperty({ type: String, format: "date-time" }) calculatedAt!: string;
}

export class CalculationHistoryListDto {
  @ApiProperty({ type: [CalculationHistoryDto] })
  items!: CalculationHistoryDto[];
  @ApiProperty({ type: String, nullable: true }) nextCursor!: string | null;
}

export class ClassificationCriterionDto {
  @ApiProperty({ type: String, example: "GIOI" }) code!: string;
  @ApiProperty({ type: String, example: "8.0" }) minimum!: string;
  @ApiProperty({ type: Boolean }) passing!: boolean;
  @ApiProperty({ type: Number }) order!: number;
}

export class ClassificationPolicyDto {
  @ApiProperty({ type: String }) version!: string;
  @ApiProperty({ type: String }) name!: string;
  @ApiProperty({ type: Number, minimum: 0, maximum: 1 })
  roundingDigits!: number;
  @ApiProperty({ type: Boolean }) active!: boolean;
  @ApiProperty({ type: [ClassificationCriterionDto] })
  criteria!: ClassificationCriterionDto[];
}

export class ActivateClassificationPolicyInput {
  @ApiProperty({ type: String, pattern: "^[A-Za-z0-9._-]{1,20}$" })
  version!: string;
  @ApiProperty({ type: String, minLength: 1, maxLength: 100 }) name!: string;
  @ApiProperty({ type: Number, minimum: 0, maximum: 1 })
  roundingDigits!: number;
  @ApiProperty({
    type: [ClassificationCriterionDto],
    minItems: 2,
    maxItems: 20,
  })
  criteria!: ClassificationCriterionDto[];
}

export class StudentApprovedComponentDto {
  @ApiProperty({ type: Number }) componentId!: number;
  @ApiProperty({ type: String }) componentName!: string;
  @ApiProperty({ type: String }) coefficient!: string;
  @ApiProperty({ type: String }) value!: string;
}

export class StudentSubjectResultDto {
  @ApiProperty({ type: Number }) gradebookId!: number;
  @ApiProperty({ type: Number }) subjectId!: number;
  @ApiProperty({ type: String }) subjectName!: string;
  @ApiProperty({ type: Number }) termId!: number;
  @ApiProperty({ type: String }) termName!: string;
  @ApiProperty({ type: [StudentApprovedComponentDto] })
  components!: StudentApprovedComponentDto[];
  @ApiProperty({ type: String, nullable: true }) finalScore!: string | null;
  @ApiProperty({ type: String, nullable: true })
  classification!: string | null;
  @ApiProperty({ type: String, format: "date-time", nullable: true })
  calculatedAt!: string | null;
}

export class StudentResultsDto {
  @ApiProperty({ type: [StudentSubjectResultDto] })
  items!: StudentSubjectResultDto[];
}

@ApiTags("final-results")
@Controller("gradebooks/:gradebookId/final-results")
export class FinalResultsController {
  constructor(
    @Inject(FinalResultsService) private readonly service: FinalResultsService,
  ) {}

  @Get()
  @ApiOkResponse({ type: FinalResultListDto })
  @ApiParam({ name: "gradebookId", type: Number })
  @ApiQuery({ name: "cursor", type: String, required: false })
  list(
    @Req() req: Request & { actor: Actor },
    @Param("gradebookId", ParseIntPipe) gradebookId: number,
    @Query("cursor") cursor?: string,
  ) {
    return this.service.list(req.actor, gradebookId, cursor ?? "0");
  }

  @Post("calculate")
  @HttpCode(200)
  @ApiBody({ type: CalculateFinalResultsInput })
  @ApiOkResponse({ type: CalculateFinalResultsDto })
  @ApiParam({ name: "gradebookId", type: Number })
  @ApiHeader({ name: "x-idempotency-key", required: true })
  calculate(
    @Req() req: Request & { actor: Actor },
    @Param("gradebookId", ParseIntPipe) gradebookId: number,
    @Headers("x-idempotency-key") idempotencyKey: string,
    @Body() body: unknown,
  ) {
    return this.service.calculate(req.actor, gradebookId, idempotencyKey, body);
  }

  @Get(":resultId/history")
  @ApiOkResponse({ type: CalculationHistoryListDto })
  @ApiParam({ name: "gradebookId", type: Number })
  @ApiParam({ name: "resultId", type: String })
  @ApiQuery({ name: "cursor", type: String, required: false })
  history(
    @Req() req: Request & { actor: Actor },
    @Param("gradebookId", ParseIntPipe) gradebookId: number,
    @Param("resultId") resultId: string,
    @Query("cursor") cursor?: string,
  ) {
    return this.service.history(
      req.actor,
      gradebookId,
      resultId,
      cursor ?? "0",
    );
  }
}

@ApiTags("classification-policies")
@Controller("classification-policies")
export class ClassificationPoliciesController {
  constructor(
    @Inject(FinalResultsService) private readonly service: FinalResultsService,
  ) {}

  @Get("active")
  @ApiOkResponse({ type: ClassificationPolicyDto })
  active(@Req() req: Request & { actor: Actor }) {
    return this.service.activePolicy(req.actor);
  }

  @Post("activate")
  @HttpCode(200)
  @ApiBody({ type: ActivateClassificationPolicyInput })
  @ApiOkResponse({ type: ClassificationPolicyDto })
  @ApiHeader({ name: "x-idempotency-key", required: true })
  activate(
    @Req() req: Request & { actor: Actor },
    @Headers("x-idempotency-key") idempotencyKey: string,
    @Body() body: unknown,
  ) {
    return this.service.activatePolicy(req.actor, idempotencyKey, body);
  }
}

@ApiTags("student-results")
@Controller("students/me/results")
export class StudentResultsController {
  constructor(
    @Inject(FinalResultsService) private readonly service: FinalResultsService,
  ) {}

  @Get()
  @ApiOkResponse({ type: StudentResultsDto })
  @ApiQuery({ name: "termId", type: Number, required: false })
  async list(
    @Req() req: Request & { actor: Actor },
    @Query("termId") termId?: string,
  ) {
    return {
      items: await this.service.myResults(
        req.actor,
        termId === undefined ? undefined : Number(termId),
      ),
    };
  }
}
