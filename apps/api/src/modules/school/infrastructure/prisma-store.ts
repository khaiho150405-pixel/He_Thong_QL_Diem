import {
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import { Prisma } from "../../../generated/prisma/client.js";
import type { PrismaClient } from "../../../generated/prisma/client.js";
import { unit } from "../../../common/store.js";
import { sqlStateOf, transaction } from "../../../common/transaction.js";
import type {
  SchoolLogoRef,
  SchoolProfile,
  SchoolStore,
  SchoolUnit,
} from "../application/port.js";

const PROFILE = Prisma.sql`
  SELECT ten_truong AS name, ten_ngan AS "shortName", co_quan_chu_quan AS "governingBody", dia_chi AS address,
    dien_thoai AS phone, email, hieu_truong AS principal, (logo_key IS NOT NULL) AS "hasLogo", phien_ban AS version,
    to_char(cap_nhat_luc AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"') AS "updatedAt"
  FROM public.truong WHERE ma_truong = 1`;

@Injectable()
export class PrismaSchoolStore implements SchoolStore {
  constructor(@Inject("DATABASE") private readonly db: PrismaClient) {}

  async profile(): Promise<SchoolProfile> {
    return (await this.db.$queryRaw<SchoolProfile[]>(PROFILE))[0]!;
  }

  async logoRef(): Promise<SchoolLogoRef | null> {
    const rows = await this.db.$queryRaw<SchoolLogoRef[]>`
      SELECT logo_key AS key, logo_content_type AS "contentType" FROM public.truong
      WHERE ma_truong = 1 AND logo_key IS NOT NULL`;
    return rows[0] ?? null;
  }

  async run<T>(work: (tx: SchoolUnit) => Promise<T>): Promise<T> {
    try {
      return await transaction(this.db, (tx) =>
        work({
          authorization: unit(tx),
          profile: async () =>
            (await tx.$queryRaw<SchoolProfile[]>(PROFILE))[0]!,
          update: async (sessionHash, expectedVersion, data, call) => {
            await tx.$queryRaw`
              SELECT public.cap_nhat_thong_tin_truong(${sessionHash}::text,${expectedVersion}::integer,
                ${JSON.stringify(data)}::jsonb,${call.idempotencyKey}::text,${call.requestHash}::text)`;
          },
          setLogo: async (sessionHash, expectedVersion, logo, call) => {
            await tx.$queryRaw`
              SELECT public.dat_logo_truong(${sessionHash}::text,${expectedVersion}::integer,${logo?.key ?? null}::text,
                ${logo?.contentType ?? null}::text,${logo?.checksum ?? null}::text,${call.idempotencyKey}::text,${call.requestHash}::text)`;
          },
        }),
      );
    } catch (error) {
      const e = error as { code?: string };
      const state = sqlStateOf(error);
      if (e.code === "P2010" && state === "42501")
        throw new ForbiddenException();
      if (e.code === "P2010" && ["02000", "P0002"].includes(state ?? ""))
        throw new NotFoundException();
      if (
        e.code === "P2010" &&
        ["23514", "23505", "40001"].includes(state ?? "")
      )
        throw new ConflictException();
      throw error;
    }
  }
}
