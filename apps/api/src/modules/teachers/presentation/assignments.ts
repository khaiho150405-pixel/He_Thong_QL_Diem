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
import { AssignmentsService } from "../application/assignments.js";
export class AssignmentsInput {
  @ApiProperty({ type: Number }) ma_giao_vien!: number;
  @ApiProperty({ type: Number }) ma_lop!: number;
  @ApiProperty({ type: Number }) ma_mon!: number;
  @ApiProperty({ type: Number }) ma_hoc_ky!: number;
  @ApiProperty({ type: String, pattern: "^\\\\d{4}-\\\\d{2}-\\\\d{2}$" })
  ngay_phan_cong!: string;
}
export class AssignmentsDto extends AssignmentsInput {
  @ApiProperty({ type: String }) label!: string;
  @ApiProperty({ type: Number }) ma_phan_cong!: number;
}
export class AssignmentsPage {
  @ApiProperty({ type: [AssignmentsDto] }) items!: AssignmentsDto[];
  @ApiProperty({ type: String, nullable: true }) nextCursor!: string | null;
}
@ApiTags("assignments")
@Controller("catalog/assignments")
export class AssignmentsController {
  constructor(
    @Inject(AssignmentsService) private readonly service: AssignmentsService,
  ) {}
  @Get()
  @ApiQuery({ name: "cursor", required: false, type: String })
  @ApiQuery({ name: "q", required: false, type: String })
  @ApiOkResponse({ type: AssignmentsPage })
  list(
    @Req() req: Request & { actor: Actor },
    @Query("cursor") cursor?: string,
    @Query("q") q?: string,
  ) {
    return this.service.list(req.actor, cursor, q);
  }
  @Post()
  @HttpCode(200)
  @ApiBody({ type: AssignmentsInput })
  @ApiOkResponse({ type: AssignmentsDto })
  create(@Req() req: Request & { actor: Actor }, @Body() input: unknown) {
    return this.service.save(req.actor, input);
  }
  @Put(":id")
  @ApiBody({ type: AssignmentsInput })
  @ApiOkResponse({ type: AssignmentsDto })
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
