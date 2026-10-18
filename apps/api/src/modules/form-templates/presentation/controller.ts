import {
  Body,
  Catch,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Inject,
  Param,
  Post,
  Put,
  Query,
  Req,
  UploadedFile,
  UseFilters,
  UseInterceptors,
  type ArgumentsHost,
  type ExceptionFilter,
} from "@nestjs/common";
import { FileInterceptor } from "@nestjs/platform-express";
import {
  ApiBody,
  ApiConsumes,
  ApiCreatedResponse,
  ApiOkResponse,
  ApiParam,
  ApiProperty,
  ApiQuery,
  ApiTags,
} from "@nestjs/swagger";
import { memoryStorage } from "multer";
import type { Request, Response } from "express";
import type { Actor } from "../../authorization/application/policy.js";
import { MAX_IMAGE_BYTES } from "../../recognition/application/image.js";
import { TemplateException } from "../application/errors.js";
import { FormTemplatesService } from "../application/service.js";

const roles = ["STT", "HO_TEN", "DIEM", "DIEM_CHU", "BO_QUA"];
const groups = ["TX", "GK", "CK"];
const statuses = ["NHAP", "DANG_DUNG", "NGUNG"];

/** Envelope lỗi ổn định (`code`, `message`, `details`, `requestId`) với mã lỗi riêng của mẫu bảng điểm. */
@Catch(TemplateException)
export class TemplateErrorFilter implements ExceptionFilter {
  catch(error: TemplateException, host: ArgumentsHost): void {
    const response = host.switchToHttp().getResponse<Response>();
    response.status(error.getStatus()).json({
      code: error.code,
      message: error.message,
      details: error.details,
      requestId: response.getHeader("x-request-id"),
    });
  }
}

export class TemplateColumnDto {
  @ApiProperty({ type: Number, minimum: 0, maximum: 63 }) index!: number;
  @ApiProperty({ type: String, enum: roles }) role!: string;
  @ApiProperty({ type: String, enum: groups, nullable: true })
  group!: string | null;
  @ApiProperty({
    type: Number,
    nullable: true,
    description: "Thứ tự trong nhóm hệ số, từ 1 (chỉ cột DIEM)",
  })
  order!: number | null;
  @ApiProperty({
    type: Number,
    nullable: true,
    description: "Chỉ số cột DIEM đi kèm (chỉ cột DIEM_CHU)",
  })
  pairedWith!: number | null;
  @ApiProperty({ type: String, nullable: true }) headerText!: string | null;
}

export class TemplateSummaryDto {
  @ApiProperty({ type: Number }) id!: number;
  @ApiProperty({ type: String }) name!: string;
  @ApiProperty({ type: String, nullable: true }) description!: string | null;
  @ApiProperty({ type: String, enum: statuses }) status!: string;
  @ApiProperty({ type: Number, description: "Số phiên bản của chuỗi mẫu" })
  revision!: number;
  @ApiProperty({ type: Number, nullable: true }) rootTemplateId!: number | null;
  @ApiProperty({ type: Number }) columnCount!: number;
  @ApiProperty({ type: Number }) gradeColumnCount!: number;
  @ApiProperty({
    type: Number,
    description: "Dùng làm expectedVersion khi sửa/kích hoạt/ngừng",
  })
  version!: number;
  @ApiProperty({ type: String, format: "date-time" }) createdAt!: string;
}

export class TemplateDetailDto extends TemplateSummaryDto {
  @ApiProperty({ type: [TemplateColumnDto] }) columns!: TemplateColumnDto[];
  @ApiProperty({
    type: String,
    description: "URL ký 300 giây của ảnh mẫu (kho lưu trữ private)",
  })
  imageUrl!: string;
  @ApiProperty({ type: Number, example: 300 })
  imageUrlExpiresInSeconds!: number;
}

export class TemplatePageDto {
  @ApiProperty({ type: [TemplateSummaryDto] }) items!: TemplateSummaryDto[];
  @ApiProperty({ type: String, nullable: true }) nextCursor!: string | null;
}

export class AnalyzedColumnDto {
  @ApiProperty({ type: Number }) index!: number;
  @ApiProperty({ type: Number, description: "Tỉ lệ 0–1 theo bề rộng bảng" })
  x0!: number;
  @ApiProperty({ type: Number }) x1!: number;
  @ApiProperty({ type: Number }) widthMm!: number;
  @ApiProperty({ type: String }) headerText!: string;
  @ApiProperty({ type: String, enum: roles, nullable: true })
  suggestedRole!: string | null;
  @ApiProperty({ type: String, enum: groups, nullable: true })
  suggestedGroup!: string | null;
  @ApiProperty({ type: Number, nullable: true }) suggestedOrder!: number | null;
}

export class AnalyzeResultDto {
  @ApiProperty({ type: Number }) columnCount!: number;
  @ApiProperty({ type: [AnalyzedColumnDto] }) columns!: AnalyzedColumnDto[];
  @ApiProperty({
    type: String,
    description: "Ảnh PNG (base64) đã nắn, vẽ lưới và số thứ tự cột từ 0",
  })
  previewPngBase64!: string;
}

export class TemplateDefinitionInput {
  @ApiProperty({ type: String, minLength: 1, maxLength: 100 }) name!: string;
  @ApiProperty({
    type: String,
    required: false,
    nullable: true,
    maxLength: 500,
  })
  description?: string | null;
  @ApiProperty({
    type: [TemplateColumnDto],
    description:
      "Mọi cột 0..n-1 của tờ mẫu (cột không đọc dùng BO_QUA). Đúng một HO_TEN, tối đa một STT, ít nhất một DIEM; cặp (group, order) không trùng; mỗi DIEM_CHU trỏ tới một DIEM bằng pairedWith.",
  })
  columns!: TemplateColumnDto[];
}

export class VersionedDefinitionInput extends TemplateDefinitionInput {
  @ApiProperty({ type: Number, minimum: 0 }) expectedVersion!: number;
}

export class ExpectedVersionInput {
  @ApiProperty({ type: Number, minimum: 0 }) expectedVersion!: number;
}

export class TryGradeDto {
  @ApiProperty({ type: String, description: "Định danh cột điểm, ví dụ TX1" })
  key!: string;
  @ApiProperty({ type: String, nullable: true }) numericValue!: string | null;
  @ApiProperty({ type: String, nullable: true }) numericConfidence!:
    | string
    | null;
  @ApiProperty({
    type: String,
    nullable: true,
    description: "null với cột chỉ có kênh điểm số",
  })
  writtenValue!: string | null;
  @ApiProperty({ type: String, nullable: true }) writtenConfidence!:
    | string
    | null;
  @ApiProperty({
    type: String,
    enum: ["KHOP", "LECH", "MOT_KENH", "KHONG_DOC_DUOC"],
  })
  comparison!: string;
  @ApiProperty({ type: String, enum: ["XANH", "VANG", "DO"] })
  reviewLevel!: string;
  @ApiProperty({ type: String, enum: ["SO", "CHU"], nullable: true })
  suggestedSource!: string | null;
}

export class TryRowDto {
  @ApiProperty({ type: Number }) rowIndex!: number;
  @ApiProperty({ type: Boolean }) struck!: boolean;
  @ApiProperty({ type: Number, nullable: true, description: "STT đọc được" })
  sttRead!: number | null;
  @ApiProperty({
    type: String,
    nullable: true,
    description: "Họ tên máy đọc được (không ghép với học sinh hệ thống)",
  })
  nameRead!: string | null;
  @ApiProperty({ type: [TryGradeDto] }) grades!: TryGradeDto[];
}

export class TryResultDto {
  @ApiProperty({ type: Number }) templateId!: number;
  @ApiProperty({ type: String }) modelVersion!: string;
  @ApiProperty({ type: Number, description: "Điểm khớp mẫu 0–1" })
  templateMatchScore!: number;
  @ApiProperty({ type: Number, nullable: true }) pageStartStt!: number | null;
  @ApiProperty({ type: [TryRowDto] }) rows!: TryRowDto[];
}

const imageInterceptor = () =>
  FileInterceptor("image", {
    storage: memoryStorage(),
    limits: { files: 1, fileSize: MAX_IMAGE_BYTES },
  });

type Authed = Request & { actor: Actor };

/**
 * Mẫu bảng điểm (ADR-0016). Quyền ghi chỉ QTV; giáo viên chỉ đọc mẫu DANG_DUNG; học sinh bị từ chối ở service và store
 * (không tin UI). Mọi nghiệp vụ nằm ở FormTemplatesService, controller chỉ chuyển tham số.
 */
@ApiTags("form-templates")
@UseFilters(TemplateErrorFilter)
@Controller("catalog/form-templates")
export class FormTemplatesController {
  constructor(
    @Inject(FormTemplatesService)
    private readonly service: FormTemplatesService,
  ) {}

  @Post("analyze")
  @HttpCode(HttpStatus.OK)
  @ApiConsumes("multipart/form-data")
  @ApiBody({
    schema: {
      type: "object",
      required: ["image"],
      properties: { image: { type: "string", format: "binary" } },
    },
  })
  @ApiOkResponse({ type: AnalyzeResultDto })
  @UseInterceptors(imageInterceptor())
  analyze(@Req() req: Authed, @UploadedFile() file?: Express.Multer.File) {
    return this.service.analyze(req.actor, {
      bytes: file?.buffer ?? new Uint8Array(),
      claimedType: file?.mimetype ?? "",
    });
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiConsumes("multipart/form-data")
  @ApiBody({
    schema: {
      type: "object",
      required: ["image", "definition"],
      properties: {
        image: { type: "string", format: "binary" },
        definition: {
          type: "string",
          description:
            "JSON của TemplateDefinitionInput (name, description, columns)",
        },
      },
    },
  })
  @ApiCreatedResponse({ type: TemplateDetailDto })
  @UseInterceptors(imageInterceptor())
  create(
    @Req() req: Authed,
    @Body() body: { definition?: unknown },
    @UploadedFile() file?: Express.Multer.File,
  ) {
    return this.service.create(
      req.actor,
      {
        bytes: file?.buffer ?? new Uint8Array(),
        claimedType: file?.mimetype ?? "",
      },
      body?.definition,
    );
  }

  @Get()
  @ApiQuery({ name: "cursor", required: false, type: String })
  @ApiQuery({ name: "status", required: false, enum: statuses })
  @ApiOkResponse({ type: TemplatePageDto })
  list(
    @Req() req: Authed,
    @Query("cursor") cursor?: string,
    @Query("status") status?: string,
  ) {
    return this.service.list(req.actor, cursor, status);
  }

  @Get(":id")
  @ApiParam({ name: "id", type: Number })
  @ApiOkResponse({ type: TemplateDetailDto })
  detail(@Req() req: Authed, @Param("id") id: string) {
    return this.service.detail(req.actor, id);
  }

  @Put(":id")
  @ApiParam({ name: "id", type: Number })
  @ApiBody({ type: VersionedDefinitionInput })
  @ApiOkResponse({
    type: TemplateDetailDto,
    description:
      "Sửa tại chỗ khi chưa có phiếu tham chiếu; ngược lại 409 TEMPLATE_IN_USE (tạo phiên bản mới)",
  })
  update(@Req() req: Authed, @Param("id") id: string, @Body() body: unknown) {
    return this.service.update(req.actor, id, body);
  }

  @Post(":id/versions")
  @HttpCode(HttpStatus.CREATED)
  @ApiParam({ name: "id", type: Number })
  @ApiBody({ type: VersionedDefinitionInput })
  @ApiCreatedResponse({
    type: TemplateDetailDto,
    description: "Phiên bản mới (NHAP); bản cũ chuyển NGUNG",
  })
  createVersion(
    @Req() req: Authed,
    @Param("id") id: string,
    @Body() body: unknown,
  ) {
    return this.service.createVersion(req.actor, id, body);
  }

  @Post(":id/activate")
  @HttpCode(HttpStatus.OK)
  @ApiParam({ name: "id", type: Number })
  @ApiBody({ type: ExpectedVersionInput })
  @ApiOkResponse({ type: TemplateDetailDto })
  activate(@Req() req: Authed, @Param("id") id: string, @Body() body: unknown) {
    return this.service.activate(req.actor, id, body);
  }

  @Post(":id/retire")
  @HttpCode(HttpStatus.OK)
  @ApiParam({ name: "id", type: Number })
  @ApiBody({ type: ExpectedVersionInput })
  @ApiOkResponse({ type: TemplateDetailDto })
  retire(@Req() req: Authed, @Param("id") id: string, @Body() body: unknown) {
    return this.service.retire(req.actor, id, body);
  }

  @Post(":id/try")
  @HttpCode(HttpStatus.OK)
  @ApiConsumes("multipart/form-data")
  @ApiParam({ name: "id", type: Number })
  @ApiBody({
    schema: {
      type: "object",
      required: ["image"],
      properties: { image: { type: "string", format: "binary" } },
    },
  })
  @ApiOkResponse({
    type: TryResultDto,
    description:
      "Kết quả đọc thử đồng bộ; không ghép học sinh, không lưu phiếu hay ảnh",
  })
  @UseInterceptors(imageInterceptor())
  tryTemplate(
    @Req() req: Authed,
    @Param("id") id: string,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    return this.service.tryTemplate(req.actor, id, {
      bytes: file?.buffer ?? new Uint8Array(),
      claimedType: file?.mimetype ?? "",
    });
  }
}
