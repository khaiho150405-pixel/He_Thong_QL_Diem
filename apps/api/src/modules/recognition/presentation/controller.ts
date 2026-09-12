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
}

export class RecognitionEvidenceRowDto {
  @ApiProperty({ type: String }) rowId!: string;
  @ApiProperty({ type: Number }) order!: number;
  @ApiProperty({ type: Number }) studentId!: number;
  @ApiProperty({ type: String }) studentName!: string;
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
  @ApiProperty({ type: String, nullable: true }) finalValue!: string | null;
  @ApiProperty({ type: String, nullable: true }) numericCropUrl!: string | null;
  @ApiProperty({ type: String, nullable: true }) writtenCropUrl!: string | null;
}

export class RecognitionTicketDetailDto extends RecognitionTicketDto {
  @ApiProperty({ type: String }) sourceImageUrl!: string;
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
  @ApiOkResponse({ type: [RecognitionTicketDto] })
  list(
    @Req() req: Request & { actor: Actor },
    @Param("gradebookId", ParseIntPipe) gradebookId: number,
  ) {
    return this.service.list(req.actor, gradebookId);
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

  @Post()
  @HttpCode(HttpStatus.ACCEPTED)
  @ApiConsumes("multipart/form-data")
  @ApiParam({ name: "gradebookId", type: Number })
  @ApiHeader({ name: "x-idempotency-key", required: true })
  @ApiBody({
    schema: {
      type: "object",
      required: ["image", "componentId", "declaredRows"],
      properties: {
        image: { type: "string", format: "binary" },
        componentId: { type: "integer", minimum: 1 },
        declaredRows: { type: "integer", minimum: 1 },
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
    @Body() body: { componentId?: unknown; declaredRows?: unknown },
    @UploadedFile() file?: Express.Multer.File,
  ) {
    return this.service.upload(req.actor, gradebookId, idempotencyKey, {
      bytes: file?.buffer ?? new Uint8Array(),
      claimedType: file?.mimetype ?? "",
      componentId: body.componentId,
      declaredRows: body.declaredRows,
    });
  }
}
