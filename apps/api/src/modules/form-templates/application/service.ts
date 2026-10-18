import { createHash, randomUUID } from "node:crypto";
import {
  BadRequestException,
  ForbiddenException,
  HttpException,
  HttpStatus,
  Inject,
  Injectable,
  Logger,
} from "@nestjs/common";
import {
  administrator,
  authenticated,
  type Actor,
} from "../../authorization/application/policy.js";
import { inspectImage } from "../../recognition/application/image.js";
import {
  RecognitionV2Error,
  type RecognitionV2Client,
} from "../../recognition/public.js";
import { OBJECT_STORAGE } from "../../files/application/port.js";
import type { ObjectStorage } from "../../files/application/port.js";
import {
  InvalidTemplateDefinition,
  parseDefinition,
  recognitionColumns,
  validateColumns,
  type TemplateDefinition,
} from "../domain/definition.js";
import {
  isTemplateErrorCode,
  templateError,
  type TemplateErrorCode,
} from "./errors.js";
import {
  FORM_TEMPLATE_RECOGNIZER,
  FORM_TEMPLATE_STORE,
  type FormTemplateStore,
  type SaveMode,
  type TemplateStatus,
} from "./port.js";

export interface ImageUpload {
  bytes: Uint8Array;
  claimedType: string;
}

const IMAGE_URL_TTL_SECONDS = 300;
const STATUSES: readonly TemplateStatus[] = ["NHAP", "DANG_DUNG", "NGUNG"];

function templateIdOf(value: unknown): number {
  const text = typeof value === "number" ? String(value) : value;
  if (typeof text !== "string" || !/^[1-9][0-9]{0,9}$/.test(text))
    throw new BadRequestException();
  const parsed = Number(text);
  if (!Number.isSafeInteger(parsed) || parsed > 2_147_483_647)
    throw new BadRequestException();
  return parsed;
}

function expectedVersionOf(value: unknown): number {
  if (
    typeof value !== "number" ||
    !Number.isSafeInteger(value) ||
    value < 0 ||
    value > 2_147_483_647
  )
    throw new BadRequestException();
  return value;
}

/** Định nghĩa không hợp lệ -> INVALID_TEMPLATE_DEFINITION (không kèm dữ liệu người dùng, chỉ lý do ổn định). */
function invalidDefinition(error: InvalidTemplateDefinition) {
  return templateError(
    "INVALID_TEMPLATE_DEFINITION",
    { reason: error.issue },
    error.message,
  );
}

function checkedDefinition(raw: unknown, expectedColumns?: number) {
  try {
    const definition = parseDefinition(raw);
    // Tự nhất quán trước (chưa biết số cột của ảnh): mọi cột 0..n-1 theo đúng luật.
    validateColumns(
      definition.columns,
      expectedColumns ?? definition.columns.length,
    );
    return definition;
  } catch (error) {
    if (error instanceof InvalidTemplateDefinition)
      throw invalidDefinition(error);
    throw error;
  }
}

function parseJsonObject(text: unknown): Record<string, unknown> {
  if (typeof text !== "string" || text.length > 64 * 1024)
    throw templateError("INVALID_TEMPLATE_DEFINITION", { reason: "SHAPE" });
  let value: unknown;
  try {
    value = JSON.parse(text);
  } catch {
    throw templateError("INVALID_TEMPLATE_DEFINITION", { reason: "SHAPE" });
  }
  if (!value || typeof value !== "object" || Array.isArray(value))
    throw templateError("INVALID_TEMPLATE_DEFINITION", { reason: "SHAPE" });
  return value as Record<string, unknown>;
}

/** Thân JSON của PUT/versions: `expectedVersion` cộng các trường của `definition`. */
function versionedBody(body: unknown): {
  expectedVersion: number;
  definition: TemplateDefinition;
} {
  if (!body || typeof body !== "object" || Array.isArray(body))
    throw new BadRequestException();
  const { expectedVersion, ...rest } = body as Record<string, unknown>;
  return {
    expectedVersion: expectedVersionOf(expectedVersion),
    definition: checkedDefinition(rest),
  };
}

@Injectable()
export class FormTemplatesService {
  private readonly logger = new Logger(FormTemplatesService.name);

  constructor(
    @Inject(FORM_TEMPLATE_STORE) private readonly store: FormTemplateStore,
    @Inject(FORM_TEMPLATE_RECOGNIZER)
    private readonly recognizer: RecognitionV2Client,
    @Inject(OBJECT_STORAGE) private readonly storage: ObjectStorage,
  ) {}

  /** Quản trị viên và giáo viên được đọc; học sinh bị từ chối (AGENTS mục 7, bất biến 9/10). */
  private reader(actor: Actor | undefined): asserts actor is Actor {
    authenticated(actor);
    if (actor.role === "HOC_SINH") throw new ForbiddenException();
  }

  async list(
    actor: Actor | undefined,
    cursorInput?: unknown,
    statusInput?: unknown,
  ) {
    this.reader(actor);
    let cursor: number | null = null;
    if (cursorInput !== undefined) {
      if (typeof cursorInput !== "string") throw new BadRequestException();
      cursor = templateIdOf(cursorInput);
    }
    let status: TemplateStatus | null = null;
    if (statusInput !== undefined) {
      if (
        typeof statusInput !== "string" ||
        !(STATUSES as readonly string[]).includes(statusInput)
      )
        throw new BadRequestException();
      status = statusInput as TemplateStatus;
    }
    return this.store.list(actor, cursor, status);
  }

  async detail(actor: Actor | undefined, idInput: unknown) {
    this.reader(actor);
    const detail = await this.store.detail(actor, templateIdOf(idInput));
    if (!detail) throw templateError("TEMPLATE_NOT_FOUND");
    const { imageKey, ...rest } = detail;
    return {
      ...rest,
      imageUrl: await this.storage.signedGetUrl(
        imageKey,
        IMAGE_URL_TTL_SECONDS,
      ),
      imageUrlExpiresInSeconds: IMAGE_URL_TTL_SECONDS,
    };
  }

  /** Proxy `/v2/layout/analyze`; không lưu gì. */
  async analyze(actor: Actor | undefined, upload: ImageUpload) {
    administrator(actor);
    inspectImage(upload.bytes, upload.claimedType);
    await this.consume(actor, "FORM_TEMPLATE_ANALYZE");
    const analysis = await this.callRecognizer(() =>
      this.recognizer.analyzeLayout(upload.bytes),
    );
    return {
      columnCount: analysis.columns.length,
      columns: analysis.columns,
      previewPngBase64: analysis.previewPngBase64,
    };
  }

  async create(
    actor: Actor | undefined,
    upload: ImageUpload,
    definitionText: unknown,
  ) {
    administrator(actor);
    const definition = checkedDefinition(parseJsonObject(definitionText));
    const image = inspectImage(upload.bytes, upload.claimedType);
    await this.consume(actor, "FORM_TEMPLATE_ANALYZE");
    // Server tự phân tích lại ảnh để tính chữ ký; không tin chữ ký/số cột do client gửi.
    const analysis = await this.callRecognizer(() =>
      this.recognizer.analyzeLayout(upload.bytes),
    );
    if (definition.columns.length !== analysis.columns.length)
      throw templateError("TEMPLATE_COLUMN_COUNT_MISMATCH", {
        definedColumns: definition.columns.length,
        analyzedColumns: analysis.columns.length,
      });
    const checksum = createHash("sha256").update(upload.bytes).digest("hex");
    const objectKey = `form-templates/${randomUUID()}.${image.extension}`;
    await this.storage.put({
      key: objectKey,
      bytes: upload.bytes,
      contentType: image.contentType,
      checksum,
    });
    let templateId: number;
    try {
      ({ templateId } = await this.store.save({
        actor,
        mode: "TAO",
        templateId: null,
        expectedVersion: null,
        name: definition.name,
        description: definition.description,
        columns: definition.columns,
        image: { signature: analysis.signature, objectKey, checksum },
      }));
    } catch (error) {
      await this.discard(objectKey);
      throw error;
    }
    return this.detail(actor, templateId);
  }

  async update(actor: Actor | undefined, idInput: unknown, body: unknown) {
    administrator(actor);
    const id = templateIdOf(idInput);
    const { expectedVersion, definition } = versionedBody(body);
    await this.saveExisting(actor, "SUA", id, expectedVersion, definition);
    return this.detail(actor, id);
  }

  async createVersion(
    actor: Actor | undefined,
    idInput: unknown,
    body: unknown,
  ) {
    administrator(actor);
    const id = templateIdOf(idInput);
    const { expectedVersion, definition } = versionedBody(body);
    const saved = await this.saveExisting(
      actor,
      "PHIEN_BAN",
      id,
      expectedVersion,
      definition,
    );
    return this.detail(actor, saved.templateId);
  }

  async activate(actor: Actor | undefined, idInput: unknown, body: unknown) {
    return this.changeStatus(actor, idInput, body, "DANG_DUNG");
  }

  async retire(actor: Actor | undefined, idInput: unknown, body: unknown) {
    return this.changeStatus(actor, idInput, body, "NGUNG");
  }

  /**
   * "Thử nhận dạng": `/v2/recognize` đồng bộ với layout dựng từ cột mẫu. Không ghép học sinh, không tạo phiếu hay kết quả
   * dòng, không lưu ảnh; chỉ ghi một dòng nhật ký "thử mẫu" (và bộ đếm hạn mức). Không log họ tên đọc được.
   */
  async tryTemplate(
    actor: Actor | undefined,
    idInput: unknown,
    upload: ImageUpload,
  ) {
    administrator(actor);
    const id = templateIdOf(idInput);
    inspectImage(upload.bytes, upload.claimedType);
    const template = await this.store.forTry(actor, id);
    if (!template) throw templateError("TEMPLATE_NOT_FOUND");
    await this.consume(actor, "FORM_TEMPLATE_TRY");
    const result = await this.callRecognizer(() =>
      this.recognizer.recognize(upload.bytes, {
        signature: template.signature,
        columns: recognitionColumns(template.columns),
      }),
    );
    await this.store.recordAudit(
      actor,
      "FORM_TEMPLATE_TRIED",
      `mau_bang_diem:${id}`,
    );
    return {
      templateId: id,
      modelVersion: result.modelVersion,
      templateMatchScore: result.templateMatch.score,
      pageStartStt: result.pageStartStt,
      rows: result.rows.map((row) => ({
        rowIndex: row.rowIndex,
        struck: row.struck,
        sttRead: row.stt.value,
        nameRead: row.name.raw,
        grades: row.grades.map((grade) => ({
          key: grade.key,
          numericValue: grade.numeric.value,
          numericConfidence: grade.numeric.confidence,
          writtenValue: grade.written?.value ?? null,
          writtenConfidence: grade.written?.confidence ?? null,
          comparison: grade.comparison,
          reviewLevel: grade.reviewLevel,
          suggestedSource: grade.suggestedSource,
        })),
      })),
    };
  }

  private async saveExisting(
    actor: Actor,
    mode: SaveMode,
    id: number,
    expectedVersion: number,
    definition: TemplateDefinition,
  ) {
    return this.store.save({
      actor,
      mode,
      templateId: id,
      expectedVersion,
      name: definition.name,
      description: definition.description,
      columns: definition.columns,
    });
  }

  private async changeStatus(
    actor: Actor | undefined,
    idInput: unknown,
    body: unknown,
    status: "DANG_DUNG" | "NGUNG",
  ) {
    administrator(actor);
    const id = templateIdOf(idInput);
    if (
      !body ||
      typeof body !== "object" ||
      Array.isArray(body) ||
      Object.keys(body).length !== 1 ||
      !Object.hasOwn(body, "expectedVersion")
    )
      throw new BadRequestException();
    await this.store.setStatus(
      actor,
      id,
      expectedVersionOf(
        (body as { expectedVersion?: unknown }).expectedVersion,
      ),
      status,
    );
    return this.detail(actor, id);
  }

  private async consume(
    actor: Actor,
    operation: "FORM_TEMPLATE_TRY" | "FORM_TEMPLATE_ANALYZE",
  ) {
    if (!(await this.store.consumeRateLimit(actor, operation)))
      throw new HttpException(
        "Rate limit exceeded",
        HttpStatus.TOO_MANY_REQUESTS,
      );
  }

  /** Dịch lỗi của client v2 sang mã lỗi ổn định của API. Không để lộ thông điệp tự do của dịch vụ. */
  private async callRecognizer<T>(call: () => Promise<T>): Promise<T> {
    try {
      return await call();
    } catch (error) {
      if (error instanceof RecognitionV2Error) {
        const code: TemplateErrorCode = isTemplateErrorCode(error.code)
          ? error.code
          : "RECOGNITION_SERVICE_ERROR";
        throw templateError(code, error.details);
      }
      throw error;
    }
  }

  private async discard(objectKey: string) {
    try {
      await this.storage.remove(objectKey);
    } catch {
      // Ảnh mồ côi không chứa họ tên; dọn dẹp là việc vận hành, không đổi kết quả lỗi gốc.
      this.logger.warn(
        JSON.stringify({ event: "form_template_cleanup_failed" }),
      );
    }
  }
}
