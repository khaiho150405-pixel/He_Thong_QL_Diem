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
import { ComponentsService } from "../application/components.js";
export class ComponentsInput {
  @ApiProperty({ type: Number }) ma_mon!: number;
  @ApiProperty({ type: String }) ten_thanh_phan!: string;
  @ApiProperty({ type: String }) he_so!: string;
  @ApiProperty({ type: Boolean }) bat_buoc!: boolean;
  @ApiProperty({ type: Number }) thu_tu_hien_thi!: number;
}
export class ComponentsDto extends ComponentsInput {
  @ApiProperty({ type: String }) label!: string;
  @ApiProperty({ type: Number }) ma_thanh_phan!: number;
}
export class ComponentsPage {
  @ApiProperty({ type: [ComponentsDto] }) items!: ComponentsDto[];
  @ApiProperty({ type: String, nullable: true }) nextCursor!: string | null;
}
@ApiTags("components")
@Controller("catalog/components")
export class ComponentsController {
  constructor(
    @Inject(ComponentsService) private readonly service: ComponentsService,
  ) {}
  @Get()
  @ApiQuery({ name: "cursor", required: false, type: String })
  @ApiQuery({ name: "q", required: false, type: String })
  @ApiOkResponse({ type: ComponentsPage })
  list(
    @Req() req: Request & { actor: Actor },
    @Query("cursor") cursor?: string,
    @Query("q") q?: string,
  ) {
    return this.service.list(req.actor, cursor, q);
  }
  @Post()
  @HttpCode(200)
  @ApiBody({ type: ComponentsInput })
  @ApiOkResponse({ type: ComponentsDto })
  create(@Req() req: Request & { actor: Actor }, @Body() input: unknown) {
    return this.service.save(req.actor, input);
  }
  @Put(":id")
  @ApiBody({ type: ComponentsInput })
  @ApiOkResponse({ type: ComponentsDto })
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
