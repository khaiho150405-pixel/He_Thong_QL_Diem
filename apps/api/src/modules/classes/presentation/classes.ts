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
import { ClassesService } from "../application/classes.js";
export class ClassesInput {
  @ApiProperty({ type: Number }) ma_nam_hoc!: number;
  @ApiProperty({ type: Number }) ma_gv_chu_nhiem!: number;
  @ApiProperty({ type: String }) ten_lop!: string;
  @ApiProperty({ type: Number }) khoi!: number;
}
export class ClassesDto extends ClassesInput {
  @ApiProperty({ type: String }) label!: string;
  @ApiProperty({ type: Number }) ma_lop!: number;
}
export class ClassesPage {
  @ApiProperty({ type: [ClassesDto] }) items!: ClassesDto[];
  @ApiProperty({ type: String, nullable: true }) nextCursor!: string | null;
}
@ApiTags("classes")
@Controller("catalog/classes")
export class ClassesController {
  constructor(
    @Inject(ClassesService) private readonly service: ClassesService,
  ) {}
  @Get()
  @ApiQuery({ name: "cursor", required: false, type: String })
  @ApiQuery({ name: "q", required: false, type: String })
  @ApiOkResponse({ type: ClassesPage })
  list(
    @Req() req: Request & { actor: Actor },
    @Query("cursor") cursor?: string,
    @Query("q") q?: string,
  ) {
    return this.service.list(req.actor, cursor, q);
  }
  @Post()
  @HttpCode(200)
  @ApiBody({ type: ClassesInput })
  @ApiOkResponse({ type: ClassesDto })
  create(@Req() req: Request & { actor: Actor }, @Body() input: unknown) {
    return this.service.save(req.actor, input);
  }
  @Put(":id")
  @ApiBody({ type: ClassesInput })
  @ApiOkResponse({ type: ClassesDto })
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
