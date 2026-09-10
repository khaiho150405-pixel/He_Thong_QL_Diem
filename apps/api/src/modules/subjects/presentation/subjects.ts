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
import { SubjectsService } from "../application/subjects.js";
export class SubjectsInput {
  @ApiProperty({ type: String }) ten_mon!: string;
  @ApiProperty({ type: Number }) so_tiet_tuan!: number;
}
export class SubjectsDto extends SubjectsInput {
  @ApiProperty({ type: String }) label!: string;
  @ApiProperty({ type: Number }) ma_mon!: number;
}
export class SubjectsPage {
  @ApiProperty({ type: [SubjectsDto] }) items!: SubjectsDto[];
  @ApiProperty({ type: String, nullable: true }) nextCursor!: string | null;
}
@ApiTags("subjects")
@Controller("catalog/subjects")
export class SubjectsController {
  constructor(
    @Inject(SubjectsService) private readonly service: SubjectsService,
  ) {}
  @Get()
  @ApiQuery({ name: "cursor", required: false, type: String })
  @ApiQuery({ name: "q", required: false, type: String })
  @ApiOkResponse({ type: SubjectsPage })
  list(
    @Req() req: Request & { actor: Actor },
    @Query("cursor") cursor?: string,
    @Query("q") q?: string,
  ) {
    return this.service.list(req.actor, cursor, q);
  }
  @Post()
  @HttpCode(200)
  @ApiBody({ type: SubjectsInput })
  @ApiOkResponse({ type: SubjectsDto })
  create(@Req() req: Request & { actor: Actor }, @Body() input: unknown) {
    return this.service.save(req.actor, input);
  }
  @Put(":id")
  @ApiBody({ type: SubjectsInput })
  @ApiOkResponse({ type: SubjectsDto })
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
