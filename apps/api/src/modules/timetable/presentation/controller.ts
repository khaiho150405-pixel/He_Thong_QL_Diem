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
  ApiQuery,
  ApiTags,
} from "@nestjs/swagger";
import type { Request } from "express";
import type { Actor } from "../../authorization/application/policy.js";
import { TimetableService } from "../application/service.js";
import {
  CreateTimetableItemInput,
  TimetableItemDto,
  TimetableListDto,
} from "./dto.js";

@ApiTags("timetable")
@Controller("timetable")
export class TimetableController {
  constructor(
    @Inject(TimetableService) private readonly service: TimetableService,
  ) {}

  @Get()
  @ApiQuery({ name: "classId", required: false, type: Number })
  @ApiQuery({ name: "teacherId", required: false, type: Number })
  @ApiQuery({ name: "semesterId", required: false, type: Number })
  @ApiQuery({ name: "dayOfWeek", required: false, type: Number })
  @ApiOkResponse({ type: TimetableListDto })
  list(
    @Req() req: Request & { actor: Actor },
    @Query("classId") classId?: string,
    @Query("teacherId") teacherId?: string,
    @Query("semesterId") semesterId?: string,
    @Query("dayOfWeek") dayOfWeek?: string,
  ) {
    return this.service.getTimetable(req.actor, {
      classId: classId ? Number(classId) : undefined,
      teacherId: teacherId ? Number(teacherId) : undefined,
      semesterId: semesterId ? Number(semesterId) : undefined,
      dayOfWeek: dayOfWeek ? Number(dayOfWeek) : undefined,
    });
  }

  @Post()
  @HttpCode(201)
  @ApiBody({ type: CreateTimetableItemInput })
  @ApiOkResponse({ type: TimetableItemDto })
  create(
    @Req() req: Request & { actor: Actor },
    @Body() input: CreateTimetableItemInput,
  ) {
    return this.service.createItem(req.actor, input);
  }

  @Put(":id")
  @ApiParam({ name: "id", type: Number })
  @ApiBody({ type: CreateTimetableItemInput })
  @ApiOkResponse({ type: TimetableItemDto })
  update(
    @Req() req: Request & { actor: Actor },
    @Param("id", ParseIntPipe) id: number,
    @Body() input: CreateTimetableItemInput,
  ) {
    return this.service.updateItem(req.actor, id, input);
  }

  @Delete(":id")
  @HttpCode(204)
  @ApiParam({ name: "id", type: Number })
  remove(
    @Req() req: Request & { actor: Actor },
    @Param("id", ParseIntPipe) id: number,
  ) {
    return this.service.deleteItem(req.actor, id);
  }
}
