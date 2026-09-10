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
import { TeachersService } from "../application/teachers.js";
export class TeachersInput {
  @ApiProperty({ type: Number }) ma_giao_vien!: number;
  @ApiProperty({ type: String }) ho_ten!: string;
  @ApiProperty({ type: String, nullable: true }) to_chuyen_mon!: string | null;
  @ApiProperty({ type: String, nullable: true }) email!: string | null;
  @ApiProperty({ type: String, nullable: true }) dien_thoai!: string | null;
}
export class TeachersDto extends TeachersInput {
  @ApiProperty({ type: String }) label!: string;
}
export class TeachersPage {
  @ApiProperty({ type: [TeachersDto] }) items!: TeachersDto[];
  @ApiProperty({ type: String, nullable: true }) nextCursor!: string | null;
}
@ApiTags("teachers")
@Controller("catalog/teachers")
export class TeachersController {
  constructor(
    @Inject(TeachersService) private readonly service: TeachersService,
  ) {}
  @Get()
  @ApiQuery({ name: "cursor", required: false, type: String })
  @ApiQuery({ name: "q", required: false, type: String })
  @ApiOkResponse({ type: TeachersPage })
  list(
    @Req() req: Request & { actor: Actor },
    @Query("cursor") cursor?: string,
    @Query("q") q?: string,
  ) {
    return this.service.list(req.actor, cursor, q);
  }
  @Post()
  @HttpCode(200)
  @ApiBody({ type: TeachersInput })
  @ApiOkResponse({ type: TeachersDto })
  create(@Req() req: Request & { actor: Actor }, @Body() input: unknown) {
    return this.service.save(req.actor, input);
  }
  @Put(":id")
  @ApiBody({ type: TeachersInput })
  @ApiOkResponse({ type: TeachersDto })
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
