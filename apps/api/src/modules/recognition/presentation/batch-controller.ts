import {
  Body,
  Catch,
  Controller,
  Get,
  Headers,
  HttpCode,
  HttpStatus,
  Inject,
  Param,
  ParseIntPipe,
  Post,
  Req,
  UploadedFiles,
  UseFilters,
  UseInterceptors,
  type ArgumentsHost,
  type ExceptionFilter,
} from "@nestjs/common";
import { FilesInterceptor } from "@nestjs/platform-express";
import {
  ApiBody,
  ApiConsumes,
  ApiHeader,
  ApiOkResponse,
  ApiParam,
  ApiProperty,
  ApiResponse,
  ApiTags,
} from "@nestjs/swagger";
import { memoryStorage } from "multer";
import type { Request, Response } from "express";
import type { Actor } from "../../authorization/application/policy.js";
import { BatchException } from "../application/batch-errors.js";
import { MAX_BATCH_PAGES } from "../application/batch-port.js";
import { RecognitionBatchService } from "../application/batch-service.js";
import { MAX_IMAGE_BYTES } from "../application/image.js";

const batchStatuses = ["DANG_XU_LY", "XONG", "LOI", "DA_HUY"] as const;
const ticketStatuses = [
  "DANG_XU_LY",
  "CHO_DOI_CHIEU",
  "DA_DUYET",
  "LOI",
  "DA_HUY",
] as const;

/** Envelope lỗi ổn định (`code`, `message`, `details`, `requestId`) với mã lỗi riêng của lô nhận dạng. */
@Catch(BatchException)
export class BatchErrorFilter implements ExceptionFilter {
  catch(error: BatchException, host: ArgumentsHost): void {
    const response = host.switchToHttp().getResponse<Response>();
    response.status(error.getStatus()).json({
      code: error.code,
      message: error.message,
      details: error.details,
      requestId: response.getHeader("x-request-id"),
    });
  }
}

export class RecognitionBatchTicketReceiptDto {
  @ApiProperty({ type: String, description: "bigint recognition ticket ID" })
  ticketId!: string;
  @ApiProperty({ type: Number }) componentId!: number;
}

export class RecognitionBatchReceiptDto {
  @ApiProperty({ type: String, description: "bigint recognition batch ID" })
  batchId!: string;
  @ApiProperty({ type: String }) jobId!: string;
  @ApiProperty({ type: String, enum: ["DANG_XU_LY"] }) status!: string;
  @ApiProperty({
    type: [RecognitionBatchTicketReceiptDto],
    description: "Một phiếu cho mỗi thành phần được chọn",
  })
  tickets!: RecognitionBatchTicketReceiptDto[];
}

export class RecognitionBatchTicketDto {
  @ApiProperty({ type: String }) ticketId!: string;
  @ApiProperty({ type: Number }) componentId!: number;
  @ApiProperty({ type: String }) componentName!: string;
  @ApiProperty({
    type: Number,
    description: "Chỉ số cột điểm trong mẫu (chi_so_cot)",
  })
  templateColumnIndex!: number;
  @ApiProperty({ type: String, enum: ticketStatuses }) status!: string;
  @ApiProperty({ type: String, nullable: true }) errorCode!: string | null;
  @ApiProperty({
    type: Number,
    description: "Dùng làm expectedVersion khi duyệt/hủy phiếu",
  })
  version!: number;
  @ApiProperty({ type: Number, description: "Số dòng mức Xanh (mức cuối)" })
  greenRows!: number;
  @ApiProperty({ type: Number, description: "Số dòng mức Vàng (mức cuối)" })
  yellowRows!: number;
  @ApiProperty({ type: Number, description: "Số dòng mức Đỏ (mức cuối)" })
  redRows!: number;
}

export class RecognitionBatchPageDto {
  @ApiProperty({ type: Number, description: "Số trang, từ 1" }) page!: number;
  @ApiProperty({
    type: String,
    description:
      "URL ký 300 giây của ảnh trang; chuỗi rỗng khi lô đã hủy (ảnh đã bị xóa khỏi kho lưu trữ)",
  })
  imageUrl!: string;
}

export class RecognitionBatchDto {
  @ApiProperty({ type: String }) batchId!: string;
  @ApiProperty({ type: Number }) gradebookId!: number;
  @ApiProperty({ type: Number }) templateId!: number;
  @ApiProperty({ type: Number }) pageCount!: number;
  @ApiProperty({ type: String, enum: batchStatuses }) status!: string;
  @ApiProperty({
    type: String,
    nullable: true,
    description: "Mã lỗi chung của lô; mọi phiếu LOI của lô mang cùng mã",
  })
  errorCode!: string | null;
  @ApiProperty({
    type: Number,
    nullable: true,
    description:
      "Trang gây lỗi (1..pageCount); null khi lỗi không gắn với trang",
  })
  errorPage!: number | null;
  @ApiProperty({ type: String, nullable: true }) modelVersion!: string | null;
  @ApiProperty({ type: Number }) version!: number;
  @ApiProperty({ type: String, format: "date-time" }) createdAt!: string;
  @ApiProperty({ type: String, nullable: true }) cancelReason!: string | null;
  @ApiProperty({ type: String, format: "date-time", nullable: true })
  cancelledAt!: string | null;
  @ApiProperty({ type: Number, example: 300 })
  imageUrlExpiresInSeconds!: number;
  @ApiProperty({ type: [RecognitionBatchPageDto] })
  pages!: RecognitionBatchPageDto[];
  @ApiProperty({ type: [RecognitionBatchTicketDto] })
  tickets!: RecognitionBatchTicketDto[];
}

export class CancelBatchInput {
  @ApiProperty({ type: String, minLength: 1, maxLength: 200 }) reason!: string;
}

type Authed = Request & { actor: Actor };

/**
 * Lô nhận dạng nhiều trang, nhiều thành phần theo mẫu (ADR-0016). Mọi nghiệp vụ nằm ở RecognitionBatchService và hàm SQL;
 * controller chỉ chuyển tham số. Duyệt từng phiếu của lô dùng endpoint phiếu hiện có.
 */
@ApiTags("recognition-batches")
@UseFilters(BatchErrorFilter)
@Controller("gradebooks/:gradebookId/recognition-batches")
export class RecognitionBatchController {
  constructor(
    @Inject(RecognitionBatchService)
    private readonly service: RecognitionBatchService,
  ) {}

  @Post()
  @HttpCode(HttpStatus.ACCEPTED)
  @ApiConsumes("multipart/form-data")
  @ApiParam({ name: "gradebookId", type: Number })
  @ApiHeader({ name: "x-idempotency-key", required: true })
  @ApiBody({
    schema: {
      type: "object",
      required: ["images", "templateId", "components"],
      properties: {
        images: {
          type: "array",
          minItems: 1,
          maxItems: MAX_BATCH_PAGES,
          items: { type: "string", format: "binary" },
          description: "Ảnh các trang theo thứ tự (trang 1 đứng đầu)",
        },
        templateId: { type: "integer", minimum: 1 },
        components: {
          type: "string",
          description:
            'JSON `[{"templateColumnIndex": n, "componentId": m}]` (1–20 mục); cột mẫu phải là cột điểm và khớp thành phần theo ánh xạ gợi ý',
        },
      },
    },
  })
  @ApiResponse({ status: 202, type: RecognitionBatchReceiptDto })
  @ApiResponse({ status: 413, description: "Image exceeds upload limit" })
  // Nhận tối đa MAX_BATCH_PAGES + 1 tệp để trang thứ 5 được báo TOO_MANY_PAGES (mã ổn định) thay vì lỗi multipart chung.
  @UseInterceptors(
    FilesInterceptor("images", MAX_BATCH_PAGES + 1, {
      storage: memoryStorage(),
      limits: { files: MAX_BATCH_PAGES + 1, fileSize: MAX_IMAGE_BYTES },
    }),
  )
  upload(
    @Req() req: Authed,
    @Param("gradebookId", ParseIntPipe) gradebookId: number,
    @Headers("x-idempotency-key") idempotencyKey: string,
    @Body() body: { templateId?: unknown; components?: unknown },
    @UploadedFiles() files?: Express.Multer.File[],
  ) {
    return this.service.upload(req.actor, gradebookId, idempotencyKey, {
      templateId: body?.templateId,
      components: body?.components,
      pages: (files ?? []).map((file) => ({
        bytes: file.buffer,
        claimedType: file.mimetype,
      })),
    });
  }

  @Get(":batchId")
  @ApiParam({ name: "gradebookId", type: Number })
  @ApiParam({ name: "batchId", type: String })
  @ApiOkResponse({ type: RecognitionBatchDto })
  detail(
    @Req() req: Authed,
    @Param("gradebookId", ParseIntPipe) gradebookId: number,
    @Param("batchId") batchId: string,
  ) {
    return this.service.detail(req.actor, gradebookId, batchId);
  }

  @Post(":batchId/cancel")
  @HttpCode(HttpStatus.OK)
  @ApiParam({ name: "gradebookId", type: Number })
  @ApiParam({ name: "batchId", type: String })
  @ApiHeader({ name: "x-idempotency-key", required: true })
  @ApiBody({ type: CancelBatchInput })
  @ApiOkResponse({
    type: RecognitionBatchDto,
    description:
      "Hủy mềm mọi phiếu chưa duyệt của lô (phiếu DA_DUYET giữ nguyên); lô đã hủy trả lại chính nó",
  })
  cancel(
    @Req() req: Authed,
    @Param("gradebookId", ParseIntPipe) gradebookId: number,
    @Param("batchId") batchId: string,
    @Headers("x-idempotency-key") idempotencyKey: string,
    @Body() body: unknown,
  ) {
    return this.service.cancel(
      req.actor,
      gradebookId,
      batchId,
      idempotencyKey,
      body,
    );
  }
}
