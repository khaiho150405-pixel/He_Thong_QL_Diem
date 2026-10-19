import {
  Controller,
  Get,
  Inject,
  Param,
  Req,
  UseFilters,
} from "@nestjs/common";
import { ApiOkResponse, ApiParam, ApiProperty, ApiTags } from "@nestjs/swagger";
import type { Request } from "express";
import type { Actor } from "../../authorization/application/policy.js";
import { FormTemplateMappingService } from "../application/mapping-service.js";
import { TemplateErrorFilter } from "./controller.js";

export class MappingItemDto {
  @ApiProperty({ type: Number, description: "Chỉ số cột điểm trong mẫu" })
  templateColumnIndex!: number;
  @ApiProperty({ type: String, description: "Định danh cột điểm, ví dụ TX1" })
  key!: string;
  @ApiProperty({ type: String, enum: ["TX", "GK", "CK"] }) group!: string;
  @ApiProperty({ type: Number, description: "Thứ tự trong nhóm, từ 1" })
  order!: number;
  @ApiProperty({
    type: String,
    enum: ["SO", "SO_CHU"],
    description:
      "SO = chỉ điểm số (tối đa Vàng); SO_CHU = đọc cả điểm số lẫn điểm chữ",
  })
  channels!: string;
  @ApiProperty({
    type: Number,
    nullable: true,
    description:
      "Thành phần điểm của môn khớp (nhóm, thứ tự); null khi môn không có thành phần tương ứng",
  })
  componentId!: number | null;
  @ApiProperty({ type: String, nullable: true }) componentName!: string | null;
  @ApiProperty({
    type: Boolean,
    description:
      "Cột đã chốt, ngoài thời gian nhập, bảng đã chốt hoặc môn Đạt/Không đạt: không chọn được",
  })
  locked!: boolean;
  @ApiProperty({
    type: Boolean,
    description: "Đang có phiếu chờ xử lý/đối chiếu: không chọn được",
  })
  pending!: boolean;
}

export class MappingDto {
  @ApiProperty({ type: Number }) gradebookId!: number;
  @ApiProperty({ type: Number }) templateId!: number;
  @ApiProperty({ type: [MappingItemDto] }) items!: MappingItemDto[];
}

type Authed = Request & { actor: Actor };

@ApiTags("form-templates")
@UseFilters(TemplateErrorFilter)
@Controller("gradebooks/:gradebookId/form-templates")
export class FormTemplateMappingController {
  constructor(
    @Inject(FormTemplateMappingService)
    private readonly service: FormTemplateMappingService,
  ) {}

  @Get(":templateId/mapping")
  @ApiParam({ name: "gradebookId", type: Number })
  @ApiParam({ name: "templateId", type: Number })
  @ApiOkResponse({
    type: MappingDto,
    description:
      "Ánh xạ gợi ý (nhóm, thứ tự) -> thành phần điểm của môn; chỉ giáo viên được phân công của bảng điểm",
  })
  mapping(
    @Req() req: Authed,
    @Param("gradebookId") gradebookId: string,
    @Param("templateId") templateId: string,
  ) {
    return this.service.mapping(req.actor, gradebookId, templateId);
  }
}
