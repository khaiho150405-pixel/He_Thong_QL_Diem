import {
  Body,
  Controller,
  Get,
  Headers,
  HttpCode,
  HttpStatus,
  Inject,
  Param,
  ParseIntPipe,
  Post,
  Query,
  Req,
  UploadedFile,
  UseInterceptors,
} from "@nestjs/common";
import { FileInterceptor } from "@nestjs/platform-express";
import {
  ApiBody,
  ApiConsumes,
  ApiHeader,
  ApiParam,
  ApiProperty,
  ApiQuery,
  ApiResponse,
  ApiTags,
  ApiOkResponse,
} from "@nestjs/swagger";
import { memoryStorage } from "multer";
import type { Request } from "express";
import type { Actor } from "../../authorization/application/policy.js";
import { MAX_IMAGE_BYTES } from "../application/image.js";
import { RecognitionService } from "../application/service.js";

export class RecognitionReceiptDto {
  @ApiProperty({ type: String, description: "bigint recognition ticket ID" })
  ticketId!: string;
  @ApiProperty({ type: String }) jobId!: string;
  @ApiProperty({ type: String, enum: ["DANG_XU_LY"] }) status!: string;
}

const ticketStatuses = [
  "DANG_XU_LY",
  "CHO_DOI_CHIEU",
  "DA_DUYET",
  "LOI",
  "DA_HUY",
] as const;

export class RecognitionTicketDto {
  @ApiProperty({ type: String }) ticketId!: string;
  @ApiProperty({ type: Number }) gradebookId!: number;
  @ApiProperty({ type: Number }) componentId!: number;
  @ApiProperty({ type: String }) componentName!: string;
  @ApiProperty({ type: Number }) declaredRows!: number;
  @ApiProperty({ type: Number, nullable: true }) detectedRows!: number | null;
  @ApiProperty({ type: String, enum: ticketStatuses }) status!: string;
  @ApiProperty({ type: String, nullable: true }) errorCode!: string | null;
  @ApiProperty({ type: String, nullable: true }) modelVersion!: string | null;
  @ApiProperty({ type: Number }) version!: number;
  @ApiProperty({ type: String, format: "date-time" }) createdAt!: string;
  @ApiProperty({
    type: String,
    nullable: true,
    description: "Lý do hủy phiếu; null khi phiếu chưa hủy",
  })
  cancelReason!: string | null;
  @ApiProperty({
    type: String,
    format: "date-time",
    nullable: true,
    description: "Thời điểm hủy phiếu; null khi phiếu chưa hủy",
  })
  cancelledAt!: string | null;
  @ApiProperty({ type: Number, description: "Số dòng mức Xanh (mức cuối)" })
  greenRows!: number;
  @ApiProperty({ type: Number, description: "Số dòng mức Vàng (mức cuối)" })
  yellowRows!: number;
  @ApiProperty({ type: Number, description: "Số dòng mức Đỏ (mức cuối)" })
  redRows!: number;
}

export class RecognitionEvidenceRowDto {
  @ApiProperty({ type: String }) rowId!: string;
  @ApiProperty({ type: Number, description: "Vị trí dòng trên ảnh" })
  order!: number;
  @ApiProperty({
    type: Number,
    nullable: true,
    description: "STT hệ thống trong danh sách lớp đã chốt của phiếu",
  })
  stt!: number | null;
  @ApiProperty({
    type: Number,
    nullable: true,
    description: "STT in trên giấy đọc được",
  })
  sttOnPaper!: number | null;
  @ApiProperty({ type: Number }) studentId!: number;
  @ApiProperty({
    type: String,
    description: "Họ tên học sinh theo danh sách lớp đã chốt",
  })
  studentName!: string;
  @ApiProperty({
    type: Boolean,
    description:
      "Học sinh được miễn cột điểm này: dòng chỉ duyệt được với giá trị null",
  })
  exempt!: boolean;
  @ApiProperty({
    type: String,
    nullable: true,
    description: "Họ tên máy đọc được trên giấy",
  })
  nameRead!: string | null;
  @ApiProperty({
    type: String,
    nullable: true,
    description: "Độ tin cậy ghép dòng với học sinh, 0..1",
  })
  matchConfidence!: string | null;
  @ApiProperty({ type: String, nullable: true }) matchNote!: string | null;
  @ApiProperty({ type: String, nullable: true }) numericRaw!: string | null;
  @ApiProperty({ type: String, nullable: true }) numericValue!: string | null;
  @ApiProperty({ type: String, nullable: true }) numericConfidence!:
    | string
    | null;
  @ApiProperty({ type: String, nullable: true }) writtenRaw!: string | null;
  @ApiProperty({ type: String, nullable: true }) writtenValue!: string | null;
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
  @ApiProperty({
    type: String,
    enum: ["SO", "CHU"],
    nullable: true,
    description:
      "Kênh cho giá trị gợi ý (SO = điểm số, CHU = điểm chữ); null khi mức Đỏ: không gợi ý giá trị",
  })
  suggestedSource!: string | null;
  @ApiProperty({
    type: String,
    enum: ["XANH", "VANG", "DO"],
    nullable: true,
    description:
      "Mức ghép học sinh (riêng khỏi mức điểm); null với phiếu cũ không lưu mức ghép",
  })
  matchLevel!: string | null;
  @ApiProperty({
    type: String,
    enum: ["XANH", "VANG", "DO"],
    nullable: true,
    description:
      "Mức điểm của hai kênh: hai kênh khớp = XANH; có kênh gợi ý = VANG; còn lại = DO",
  })
  gradeLevel!: string | null;
  @ApiProperty({ type: String, nullable: true }) finalValue!: string | null;
  @ApiProperty({ type: String, nullable: true }) numericCropUrl!: string | null;
  @ApiProperty({ type: String, nullable: true }) writtenCropUrl!: string | null;
  @ApiProperty({
    type: String,
    nullable: true,
    description: "Ảnh ô họ tên trên giấy (URL ký 300 giây)",
  })
  nameCropUrl!: string | null;
}

export class CancelTicketInput {
  @ApiProperty({ type: Number, minimum: 0 }) expectedVersion!: number;
  @ApiProperty({ type: String, minLength: 1, maxLength: 200 }) reason!: string;
}

export class RecognitionTicketDetailDto extends RecognitionTicketDto {
  @ApiProperty({
    type: String,
    description:
      "URL ký 300 giây của ảnh gốc; chuỗi rỗng khi phiếu đã hủy (ảnh đã bị xóa khỏi kho lưu trữ)",
  })
  sourceImageUrl!: string;
  @ApiProperty({ type: Number, example: 300 })
  imageUrlExpiresInSeconds!: number;
  @ApiProperty({ type: [RecognitionEvidenceRowDto] })
  rows!: RecognitionEvidenceRowDto[];
}

@ApiTags("recognition")
@Controller("gradebooks/:gradebookId/recognition-tickets")
export class RecognitionController {
  constructor(
    @Inject(RecognitionService) private readonly service: RecognitionService,
  ) {}

  @Get()
  @ApiParam({ name: "gradebookId", type: Number })
  @ApiQuery({
    name: "includeCancelled",
    required: false,
    type: Boolean,
    description: "true: hiện cả phiếu đã hủy (DA_HUY); mặc định ẩn",
  })
  @ApiOkResponse({ type: [RecognitionTicketDto] })
  list(
    @Req() req: Request & { actor: Actor },
    @Param("gradebookId", ParseIntPipe) gradebookId: number,
    @Query("includeCancelled") includeCancelled?: string,
  ) {
    return this.service.list(req.actor, gradebookId, includeCancelled);
  }

  @Get(":ticketId")
  @ApiParam({ name: "gradebookId", type: Number })
  @ApiParam({ name: "ticketId", type: String })
  @ApiOkResponse({ type: RecognitionTicketDetailDto })
  detail(
    @Req() req: Request & { actor: Actor },
    @Param("gradebookId", ParseIntPipe) gradebookId: number,
    @Param("ticketId") ticketId: string,
  ) {
    return this.service.detail(req.actor, gradebookId, ticketId);
  }

  @Post(":ticketId/cancel")
  @HttpCode(HttpStatus.OK)
  @ApiParam({ name: "gradebookId", type: Number })
  @ApiParam({ name: "ticketId", type: String })
  @ApiHeader({ name: "x-idempotency-key", required: true })
  @ApiBody({ type: CancelTicketInput })
  @ApiOkResponse({
    type: RecognitionTicketDetailDto,
    description:
      "Hủy mềm phiếu DANG_XU_LY/CHO_DOI_CHIEU/LOI (phiếu DA_DUYET trả 409, phiếu đã DA_HUY trả lại chính nó)",
  })
  cancel(
    @Req() req: Request & { actor: Actor },
    @Param("gradebookId", ParseIntPipe) gradebookId: number,
    @Param("ticketId") ticketId: string,
    @Headers("x-idempotency-key") idempotencyKey: string,
    @Body() body: unknown,
  ) {
    return this.service.cancel(
      req.actor,
      gradebookId,
      ticketId,
      idempotencyKey,
      body,
    );
  }

  @Post()
  @HttpCode(HttpStatus.ACCEPTED)
  @ApiConsumes("multipart/form-data")
  @ApiParam({ name: "gradebookId", type: Number })
  @ApiHeader({ name: "x-idempotency-key", required: true })
  @ApiBody({
    schema: {
      type: "object",
      required: ["image", "componentId"],
      properties: {
        image: { type: "string", format: "binary" },
        componentId: { type: "integer", minimum: 1 },
        declaredRows: {
          type: "integer",
          minimum: 1,
          deprecated: true,
          description:
            "Deprecated và bị bỏ qua: hệ thống tự chốt danh sách lớp khi tạo phiếu (ADR-0015).",
        },
      },
    },
  })
  @ApiResponse({ status: 202, type: RecognitionReceiptDto })
  @ApiResponse({ status: 413, description: "Image exceeds upload limit" })
  @UseInterceptors(
    FileInterceptor("image", {
      storage: memoryStorage(),
      limits: { files: 1, fileSize: MAX_IMAGE_BYTES },
    }),
  )
  upload(
    @Req() req: Request & { actor: Actor },
    @Param("gradebookId", ParseIntPipe) gradebookId: number,
    @Headers("x-idempotency-key") idempotencyKey: string,
    // `declaredRows` do client cũ gửi được bỏ qua (ADR-0015).
    @Body() body: { componentId?: unknown },
    @UploadedFile() file?: Express.Multer.File,
  ) {
    return this.service.upload(req.actor, gradebookId, idempotencyKey, {
      bytes: file?.buffer ?? new Uint8Array(),
      claimedType: file?.mimetype ?? "",
      componentId: body.componentId,
    });
  }
}
