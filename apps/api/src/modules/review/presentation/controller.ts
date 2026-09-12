import {
  Body,
  Controller,
  Headers,
  HttpCode,
  Inject,
  Param,
  ParseIntPipe,
  Post,
  Req,
} from "@nestjs/common";
import {
  ApiBody,
  ApiHeader,
  ApiOkResponse,
  ApiParam,
  ApiProperty,
  ApiTags,
} from "@nestjs/swagger";
import type { Request } from "express";
import type { Actor } from "../../authorization/application/policy.js";
import { ReviewService } from "../application/service.js";

export class ReviewDecisionInput {
  @ApiProperty({ type: String, description: "bigint recognition row ID" })
  rowId!: string;
  @ApiProperty({
    type: String,
    nullable: true,
    pattern: "^(10[.]0|[0-9][.][0-9])$",
  })
  value!: string | null;
  @ApiProperty({ type: String, minLength: 1, maxLength: 500 })
  reason!: string;
}

export class ReviewApprovalInput {
  @ApiProperty({ type: Number, minimum: 0 }) expectedTicketVersion!: number;
  @ApiProperty({ type: Number, minimum: 0 }) expectedGradebookVersion!: number;
  @ApiProperty({ type: [ReviewDecisionInput], minItems: 1, maxItems: 500 })
  decisions!: ReviewDecisionInput[];
}

export class ReviewApprovalResultDto {
  @ApiProperty({ type: String }) ticketId!: string;
  @ApiProperty({ type: Number }) ticketVersion!: number;
  @ApiProperty({ type: Number }) gradebookId!: number;
  @ApiProperty({ type: Number }) gradebookVersion!: number;
  @ApiProperty({ type: Number }) reviewedRows!: number;
  @ApiProperty({ type: Number }) machineMatchedRows!: number;
  @ApiProperty({ type: Number }) humanCorrectedRows!: number;
  @ApiProperty({ type: Number }) errorRows!: number;
  @ApiProperty({ type: String, enum: ["DA_DUYET"] }) status!: string;
}

@ApiTags("review")
@Controller("gradebooks/:gradebookId/recognition-tickets/:ticketId")
export class ReviewController {
  constructor(@Inject(ReviewService) private readonly service: ReviewService) {}

  @Post("approve")
  @HttpCode(200)
  @ApiParam({ name: "gradebookId", type: Number })
  @ApiParam({ name: "ticketId", type: String })
  @ApiHeader({ name: "x-idempotency-key", required: true })
  @ApiBody({ type: ReviewApprovalInput })
  @ApiOkResponse({ type: ReviewApprovalResultDto })
  approve(
    @Req() req: Request & { actor: Actor },
    @Param("gradebookId", ParseIntPipe) gradebookId: number,
    @Param("ticketId") ticketId: string,
    @Headers("x-idempotency-key") idempotencyKey: string,
    @Body() body: unknown,
  ) {
    return this.service.approve(
      req.actor,
      gradebookId,
      ticketId,
      idempotencyKey,
      body,
    );
  }
}
