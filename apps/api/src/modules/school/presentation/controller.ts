import {
  Body,
  Controller,
  Delete,
  Get,
  Headers,
  HttpCode,
  Inject,
  Put,
  Query,
  Req,
  Res,
  StreamableFile,
  UploadedFile,
  UseInterceptors,
} from "@nestjs/common";
import { FileInterceptor } from "@nestjs/platform-express";
import {
  ApiBody,
  ApiConsumes,
  ApiHeader,
  ApiOkResponse,
  ApiProduces,
  ApiProperty,
  ApiQuery,
  ApiTags,
} from "@nestjs/swagger";
import type { Request, Response } from "express";
import { memoryStorage } from "multer";
import type { Actor } from "../../authorization/application/policy.js";
import { SchoolService } from "../application/service.js";

export class SchoolProfileDto {
  @ApiProperty({ type: String }) name!: string;
  @ApiProperty({ type: String }) shortName!: string;
  @ApiProperty({ type: String, nullable: true }) governingBody!: string | null;
  @ApiProperty({ type: String, nullable: true }) address!: string | null;
  @ApiProperty({ type: String, nullable: true }) phone!: string | null;
  @ApiProperty({ type: String, nullable: true }) email!: string | null;
  @ApiProperty({ type: String, nullable: true }) principal!: string | null;
  @ApiProperty({ type: Boolean }) hasLogo!: boolean;
  @ApiProperty({ type: Number }) version!: number;
  @ApiProperty({ type: String }) updatedAt!: string;
}

const optionalText = (maxLength: number) => ({
  type: String,
  maxLength,
  required: false,
  nullable: true,
});

export class UpdateSchoolProfileInput {
  @ApiProperty({ type: Number, minimum: 1 }) expectedVersion!: number;
  @ApiProperty({ type: String, minLength: 3, maxLength: 200 }) name!: string;
  @ApiProperty({ type: String, minLength: 2, maxLength: 60 })
  shortName!: string;
  @ApiProperty(optionalText(200)) governingBody?: string | null;
  @ApiProperty(optionalText(300)) address?: string | null;
  @ApiProperty({ ...optionalText(11), pattern: "^[0-9]{10,11}$" })
  phone?: string | null;
  @ApiProperty({ ...optionalText(200), format: "email" })
  email?: string | null;
  @ApiProperty(optionalText(120)) principal?: string | null;
}

type Authed = Request & { actor: Actor };
const idem = { name: "x-idempotency-key", required: true } as const;

/** Hai route công khai (màn đăng nhập cũng dùng): SessionGuard cho qua theo tên lớp này, nên không thêm route khác vào đây. */
@ApiTags("school")
@Controller("school-profile")
export class SchoolProfilePublicController {
  constructor(@Inject(SchoolService) private readonly service: SchoolService) {}

  @Get()
  @ApiOkResponse({ type: SchoolProfileDto })
  profile() {
    return this.service.profile();
  }

  @Get("logo")
  @ApiProduces("image/png", "image/jpeg")
  @ApiOkResponse({
    schema: { type: "string", format: "binary" },
    description: "Logo trường (PNG hoặc JPEG); 404 NOT_FOUND nếu chưa có",
  })
  async logo(@Res({ passthrough: true }) res: Response) {
    const logo = await this.service.logo();
    res.setHeader("Cache-Control", "public, max-age=300");
    return new StreamableFile(logo.bytes, { type: logo.contentType });
  }
}

@ApiTags("school")
@Controller("admin/school-profile")
export class SchoolProfileAdminController {
  constructor(@Inject(SchoolService) private readonly service: SchoolService) {}

  @Put()
  @ApiHeader(idem)
  @ApiBody({ type: UpdateSchoolProfileInput })
  @ApiOkResponse({ type: SchoolProfileDto })
  update(
    @Req() req: Authed,
    @Headers("x-idempotency-key") key: string,
    @Body() body: unknown,
  ) {
    return this.service.update(req.actor, key, body);
  }

  @Put("logo")
  @ApiHeader(idem)
  @ApiConsumes("multipart/form-data")
  @ApiBody({
    schema: {
      type: "object",
      required: ["file", "expectedVersion"],
      properties: {
        file: { type: "string", format: "binary" },
        expectedVersion: { type: "integer", minimum: 1 },
      },
    },
  })
  @ApiOkResponse({ type: SchoolProfileDto })
  // Giới hạn multer rộng hơn 1 MB để file quá cỡ nhận INVALID_LOGO_FILE từ service thay vì 413.
  @UseInterceptors(
    FileInterceptor("file", {
      storage: memoryStorage(),
      limits: { files: 1, fileSize: 5 * 1024 * 1024 },
    }),
  )
  setLogo(
    @Req() req: Authed,
    @Headers("x-idempotency-key") key: string,
    @Body() body: { expectedVersion?: unknown },
    @UploadedFile() file?: Express.Multer.File,
  ) {
    return this.service.setLogo(req.actor, key, body?.expectedVersion, {
      bytes: file?.buffer ?? new Uint8Array(),
      claimedType: file?.mimetype ?? "",
    });
  }

  @Delete("logo")
  @HttpCode(200)
  @ApiHeader(idem)
  @ApiQuery({ name: "expectedVersion", type: Number })
  @ApiOkResponse({ type: SchoolProfileDto })
  removeLogo(
    @Req() req: Authed,
    @Headers("x-idempotency-key") key: string,
    @Query("expectedVersion") expectedVersion: string,
  ) {
    return this.service.removeLogo(req.actor, key, expectedVersion);
  }
}
