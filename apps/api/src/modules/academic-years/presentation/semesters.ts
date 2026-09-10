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
import { SemestersService } from "../application/semesters.js";
export class SemestersInput {
  @ApiProperty({ type: Number }) ma_nam_hoc!: number;
  @ApiProperty({ type: String }) ten!: string;
  @ApiProperty({ type: Number }) thu_tu!: number;
  @ApiProperty({ type: String, pattern: "^\\\\d{4}-\\\\d{2}-\\\\d{2}$" })
  ngay_bat_dau!: string;
  @ApiProperty({ type: String, pattern: "^\\\\d{4}-\\\\d{2}-\\\\d{2}$" })
  ngay_ket_thuc!: string;
}
export class SemestersDto extends SemestersInput {
  @ApiProperty({ type: String }) label!: string;
  @ApiProperty({ type: Number }) ma_hoc_ky!: number;
}
export class SemestersPage {
  @ApiProperty({ type: [SemestersDto] }) items!: SemestersDto[];
  @ApiProperty({ type: String, nullable: true }) nextCursor!: string | null;
}
@ApiTags("semesters")
@Controller("catalog/semesters")
export class SemestersController {
  constructor(
    @Inject(SemestersService) private readonly service: SemestersService,
  ) {}
  @Get()
  @ApiQuery({ name: "cursor", required: false, type: String })
  @ApiQuery({ name: "q", required: false, type: String })
  @ApiOkResponse({ type: SemestersPage })
  list(
    @Req() req: Request & { actor: Actor },
    @Query("cursor") cursor?: string,
    @Query("q") q?: string,
  ) {
    return this.service.list(req.actor, cursor, q);
  }
  @Post()
  @HttpCode(200)
  @ApiBody({ type: SemestersInput })
  @ApiOkResponse({ type: SemestersDto })
  create(@Req() req: Request & { actor: Actor }, @Body() input: unknown) {
    return this.service.save(req.actor, input);
  }
  @Put(":id")
  @ApiBody({ type: SemestersInput })
  @ApiOkResponse({ type: SemestersDto })
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
