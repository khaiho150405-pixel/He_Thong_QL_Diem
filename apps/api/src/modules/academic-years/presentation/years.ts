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
import { YearsService } from "../application/years.js";
export class YearsInput {
  @ApiProperty({ type: String }) ten!: string;
  @ApiProperty({ type: String, pattern: "^\\\\d{4}-\\\\d{2}-\\\\d{2}$" })
  ngay_bat_dau!: string;
  @ApiProperty({ type: String, pattern: "^\\\\d{4}-\\\\d{2}-\\\\d{2}$" })
  ngay_ket_thuc!: string;
  @ApiProperty({ type: Boolean }) hien_hanh!: boolean;
}
export class YearsDto extends YearsInput {
  @ApiProperty({ type: String }) label!: string;
  @ApiProperty({ type: Number }) ma_nam_hoc!: number;
}
export class YearsPage {
  @ApiProperty({ type: [YearsDto] }) items!: YearsDto[];
  @ApiProperty({ type: String, nullable: true }) nextCursor!: string | null;
}
@ApiTags("years")
@Controller("catalog/years")
export class YearsController {
  constructor(@Inject(YearsService) private readonly service: YearsService) {}
  @Get()
  @ApiQuery({ name: "cursor", required: false, type: String })
  @ApiQuery({ name: "q", required: false, type: String })
  @ApiOkResponse({ type: YearsPage })
  list(
    @Req() req: Request & { actor: Actor },
    @Query("cursor") cursor?: string,
    @Query("q") q?: string,
  ) {
    return this.service.list(req.actor, cursor, q);
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
