import {
  Body,
  Controller,
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

@ApiTags("recognition")
@Controller("gradebooks/:gradebookId/recognition-tickets")
export class RecognitionController {
  constructor(
    @Inject(RecognitionService) private readonly service: RecognitionService,
  ) {}

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
