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
import type { Actor } from "../../authorization/application/policy.js";
import { SemesterWeightsService } from "../application/semester-weights.js";
export class SemesterWeightsInput {
  @ApiProperty({ type: String, enum: ["TX", "GK", "CK"] }) loai_he_so!: string;
  @ApiProperty({ type: Number }) ma_hoc_ky!: number;
  @ApiProperty({ type: String }) he_so!: string;
}
export class SemesterWeightsDto extends SemesterWeightsInput {
  @ApiProperty({ type: String }) label!: string;
  @ApiProperty({ type: Number }) ma_he_so!: number;
}
export class SemesterWeightsPage {
  @ApiProperty({ type: [SemesterWeightsDto] }) items!: SemesterWeightsDto[];
  @ApiProperty({ type: String, nullable: true }) nextCursor!: string | null;
}
@ApiTags("semester-weights")
@Controller("catalog/semester-weights")
export class SemesterWeightsController {
  constructor(
    @Inject(SemesterWeightsService)
    private readonly service: SemesterWeightsService,
  ) {}
  @Get()
  @ApiQuery({ name: "cursor", required: false, type: String })
  @ApiQuery({ name: "q", required: false, type: String })
  @ApiOkResponse({ type: SemesterWeightsPage })
  list(
    @Req() req: Request & { actor: Actor },
    @Query("cursor") cursor?: string,
    @Query("q") q?: string,
  ) {
    return this.service.list(req.actor, cursor, q);
  }
  @Post()
  @HttpCode(200)
  @ApiBody({ type: SemesterWeightsInput })
  @ApiOkResponse({ type: SemesterWeightsDto })
  create(@Req() req: Request & { actor: Actor }, @Body() input: unknown) {
    return this.service.save(req.actor, input);
  }
  @Put(":id")
  @ApiBody({ type: SemesterWeightsInput })
  @ApiOkResponse({ type: SemesterWeightsDto })
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
