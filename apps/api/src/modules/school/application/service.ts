import { createHash } from "node:crypto";
import {
  BadRequestException,
  Inject,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import { CodedException } from "../../../common/coded-error.js";
import {
  administrator,
  currentActor,
  type Actor,
} from "../../authorization/application/policy.js";
import { OBJECT_STORAGE } from "../../files/application/port.js";
import type { ObjectStorage } from "../../files/public.js";
import { inspectImage } from "../../recognition/application/image.js";
import {
  SCHOOL_STORE,
  type IdempotentCall,
  type SchoolProfile,
  type SchoolStore,
} from "./port.js";

const MAX_LOGO_BYTES = 1024 * 1024;
/** Độ dài [tối thiểu, tối đa] đã trim; 0 nghĩa là được để trống (lưu null). */
const LIMITS: Record<string, [number, number]> = {
  name: [3, 200],
  shortName: [2, 60],
  governingBody: [0, 200],
  address: [0, 300],
  phone: [0, 11],
  email: [0, 200],
  principal: [0, 120],
};

function idempotencyKey(value: unknown) {
  if (typeof value !== "string" || !/^[a-zA-Z0-9_-]{1,64}$/.test(value))
    throw new BadRequestException();
  return value;
}
/** Số nguyên dương; nhận cả chuỗi vì multipart/query không có kiểu số. */
function version(value: unknown) {
  const n =
    typeof value === "string" && /^[0-9]{1,10}$/.test(value)
      ? Number(value)
      : value;
  if (
    typeof n !== "number" ||
    !Number.isSafeInteger(n) ||
    n < 1 ||
    n > 2147483647
  )
    throw new BadRequestException();
  return n;
}
function call(key: string, payload: unknown): IdempotentCall {
  return {
    idempotencyKey: key,
    requestHash: createHash("sha256")
      .update(JSON.stringify(payload))
      .digest("hex"),
  };
}
const invalidLogo = (message: string) =>
  new CodedException("INVALID_LOGO_FILE", message);

/** Kiểm tra và chuẩn hóa nội dung sửa thông tin trường; chuỗi rỗng của trường tùy chọn → null. */
function profileData(body: unknown) {
  if (!body || typeof body !== "object" || Array.isArray(body))
    throw new BadRequestException();
  const input = body as Record<string, unknown>;
  const fields = Object.keys(input).filter(
    (k) => k !== "expectedVersion" && !(k in LIMITS),
  );
  const data: Record<string, string | null> = {};
  for (const [key, [min, max]] of Object.entries(LIMITS)) {
    const raw = input[key];
    if (raw !== undefined && raw !== null && typeof raw !== "string") {
      fields.push(key);
      continue;
    }
    const value = raw?.trim() || null;
    if (
      (value === null ? min > 0 : value.length < min || value.length > max) ||
      (key === "phone" && value !== null && !/^[0-9]{10,11}$/.test(value)) ||
      (key === "email" &&
        value !== null &&
        !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(value))
    )
      fields.push(key);
    data[key] = value;
  }
  if (fields.length)
    throw new CodedException(
      "INVALID_SCHOOL_PROFILE",
      "Thông tin trường không hợp lệ.",
      { fields },
    );
  return { expectedVersion: version(input.expectedVersion), data };
}

@Injectable()
export class SchoolService {
  constructor(
    @Inject(SCHOOL_STORE) private readonly store: SchoolStore,
    @Inject(OBJECT_STORAGE) private readonly storage: ObjectStorage,
  ) {}

  profile(): Promise<SchoolProfile> {
    return this.store.profile();
  }

  async logo() {
    const ref = await this.store.logoRef();
    if (!ref) throw new NotFoundException();
    return {
      bytes: await this.storage.get(ref.key),
      contentType: ref.contentType,
    };
  }

  update(actor: Actor, key: unknown, body: unknown) {
    const idem = idempotencyKey(key);
    const { expectedVersion, data } = profileData(body);
    const idempotent = call(idem, { expectedVersion, data });
    return this.store.run(async (tx) => {
      await currentActor(tx.authorization, actor);
      administrator(actor);
      await tx.update(actor.sessionHash, expectedVersion, data, idempotent);
      return tx.profile();
    });
  }

  async setLogo(
    actor: Actor,
    key: unknown,
    expectedVersion: unknown,
    file: { bytes: Uint8Array; claimedType: string },
  ) {
    const idem = idempotencyKey(key);
    const expected = version(expectedVersion);
    // Chỉ QTV mới được ghi kho; session còn hạn được kiểm lại trong giao dịch bên dưới.
    administrator(actor);
    if (file.bytes.byteLength > MAX_LOGO_BYTES)
      throw invalidLogo("Logo tối đa 1 MB.");
    let inspected;
    try {
      inspected = inspectImage(file.bytes, file.claimedType);
    } catch {
      throw invalidLogo("Logo phải là ảnh PNG hoặc JPEG hợp lệ.");
    }
    const checksum = createHash("sha256").update(file.bytes).digest("hex");
    const logo = {
      key: `school/logo-${checksum}.${inspected.extension}`,
      contentType: inspected.contentType,
      checksum,
    };
    // Key theo nội dung và không xóa file cũ, nên file mồ côi khi giao dịch sau đó lỗi là chấp nhận được.
    await this.storage.put({
      key: logo.key,
      bytes: file.bytes,
      contentType: inspected.contentType,
      checksum,
    });
    return this.store.run(async (tx) => {
      await currentActor(tx.authorization, actor);
      await tx.setLogo(
        actor.sessionHash,
        expected,
        logo,
        call(idem, { expected, checksum }),
      );
      return tx.profile();
    });
  }

  removeLogo(actor: Actor, key: unknown, expectedVersion: unknown) {
    const idem = idempotencyKey(key);
    const expected = version(expectedVersion);
    return this.store.run(async (tx) => {
      await currentActor(tx.authorization, actor);
      administrator(actor);
      await tx.setLogo(
        actor.sessionHash,
        expected,
        null,
        call(idem, { expected, remove: true }),
      );
      return tx.profile();
    });
  }
}
