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
import { StudentsService } from "../application/students.js";
export class StudentsInput {
  @ApiProperty({ type: Number, nullable: true }) ma_nguoi_dung!: number | null;
  @ApiProperty({ type: Number }) ma_lop!: number;
  @ApiProperty({ type: String }) ho_ten!: string;
  @ApiProperty({ type: String, pattern: "^[0-9]{4}-[0-9]{2}-[0-9]{2}$" })
  ngay_sinh!: string;
  @ApiProperty({ type: Boolean }) dang_theo_hoc!: boolean;
}
export class StudentsDto extends StudentsInput {
  @ApiProperty({ type: String }) label!: string;
  @ApiProperty({ type: Number }) ma_hoc_sinh!: number;
  @ApiProperty({ type: Number, nullable: true }) stt_toan_truong!:
    | number
    | null;
  @ApiProperty({ type: Number, nullable: true }) stt_lop!: number | null;
}
export class StudentsPage {
  @ApiProperty({ type: [StudentsDto] }) items!: StudentsDto[];
  @ApiProperty({ type: String, nullable: true }) nextCursor!: string | null;
}
export class StudentsImportInput {
  @ApiProperty({ type: [StudentsInput], maxItems: 500 })
  items!: StudentsInput[];
}
export class StudentsImportResult {
  @ApiProperty({ type: Number }) imported!: number;
  @ApiProperty({ type: [StudentsDto] }) items!: StudentsDto[];
}
@ApiTags("students")
@Controller("catalog/students")
export class StudentsController {
  constructor(
    @Inject(StudentsService) private readonly service: StudentsService,
  ) {}
  @Get()
  @ApiQuery({ name: "cursor", required: false, type: String })
  @ApiQuery({ name: "q", required: false, type: String })
  @ApiOkResponse({ type: StudentsPage })
  list(
    @Req() req: Request & { actor: Actor },
    @Query("cursor") cursor?: string,
    @Query("q") q?: string,
  ) {
    return this.service.list(req.actor, cursor, q);
  }
  @Post()
  @HttpCode(200)
  @ApiBody({ type: StudentsInput })
  @ApiOkResponse({ type: StudentsDto })
  create(@Req() req: Request & { actor: Actor }, @Body() input: unknown) {
    return this.service.save(req.actor, input);
  }
  @Post("import")
  @HttpCode(200)
  @ApiBody({ type: StudentsImportInput })
  @ApiOkResponse({ type: StudentsImportResult })
  importMany(
    @Req() req: Request & { actor: Actor },
    @Body() input: StudentsImportInput,
  ) {
    return this.service.saveMany(req.actor, input?.items ?? []);
  }
  @Put(":id")
  @ApiBody({ type: StudentsInput })
  @ApiOkResponse({ type: StudentsDto })
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
