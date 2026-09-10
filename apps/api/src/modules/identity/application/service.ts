import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  HttpException,
  Inject,
  Injectable,
  UnauthorizedException,
} from "@nestjs/common";
import { createHash, randomBytes } from "node:crypto";
import { argon2id, hash, verify } from "argon2";
import { STORE, type Store, type Row } from "../../../common/store.js";
import {
  administrator,
  authenticated,
  currentActor,
  roles,
  type Actor,
  type Role,
} from "../../authorization/application/policy.js";
import { audit } from "../../audit/application/write.js";

export const digest = (token: string) =>
  createHash("sha256").update(token).digest("hex");
const random = () => randomBytes(32).toString("hex");
const idle = 30 * 60 * 1000;
const publicUser = (u: Row) => ({
  id: Number(u.ma_nguoi_dung),
  username: String(u.ten_dang_nhap),
  role: u.vai_tro as Role,
  active: Boolean(u.trang_thai),
});
async function passwordHash(password: string) {
  if (
    typeof password !== "string" ||
    password.length < 12 ||
    password.length > 128
  )
    throw new BadRequestException();
  const memoryCost = Number(process.env.ARGON2_MEMORY_KIB ?? 65536);
  const timeCost = Number(process.env.ARGON2_TIME_COST ?? 3);
  if (
    !Number.isInteger(memoryCost) ||
    memoryCost < 65536 ||
    memoryCost > 262144 ||
    !Number.isInteger(timeCost) ||
    timeCost < 3 ||
    timeCost > 10
  )
    throw new Error("Invalid Argon2 settings");
  return hash(password, {
    type: argon2id,
    memoryCost,
    timeCost,
    parallelism: 1,
  });
}
@Injectable()
export class IdentityService {
  async profile(actor: Actor, input?: unknown) {
    authenticated(actor);
    return this.store.run(async (tx) => {
      await currentActor(tx, actor);
      const table = actor.role === "GIAO_VIEN" ? "giao_vien" : "hoc_sinh";
      if (actor.role === "QUAN_TRI_VIEN") throw new ForbiddenException();
      const where =
        table === "giao_vien"
          ? { ma_giao_vien: actor.id }
          : { ma_nguoi_dung: actor.id };
      const row = await tx.find(table, where);
      if (!row) throw new ConflictException();
      if (input !== undefined) {
        const data = input as Row;
        if (
          !data ||
          typeof data !== "object" ||
          Object.keys(data).some(
            (k) => !["name", "email", "phone"].includes(k),
          ) ||
          typeof data.name !== "string" ||
          !data.name.trim() ||
          data.name.length > 100 ||
          (data.email != null &&
            (typeof data.email !== "string" ||
              data.email.length > 254 ||
              !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(data.email))) ||
          (data.phone != null &&
            (typeof data.phone !== "string" || data.phone.length > 20))
        )
          throw new BadRequestException();
        if (table === "hoc_sinh" && (data.email != null || data.phone != null))
          throw new BadRequestException();
        const update = {
          ho_ten: data.name.trim(),
          ...(table === "giao_vien"
            ? { email: data.email ?? null, dien_thoai: data.phone ?? null }
            : {}),
        };
        await tx.update(table, where, update);
        Object.assign(row, update);
        await audit(tx, actor.id, "PROFILE_UPDATE", `${table}:${actor.id}`);
      }
      return {
        name: String(row.ho_ten),
        email: (row.email as string | undefined) ?? null,
        phone: (row.dien_thoai as string | undefined) ?? null,
      };
    });
  }
  private dummy = passwordHash(random());
  constructor(@Inject(STORE) private readonly store: Store) {}
  async login(username: string, password: string, ip: string) {
    if (
      typeof username !== "string" ||
      username.length > 50 ||
      typeof password !== "string" ||
      password.length > 128
    )
      throw new BadRequestException();
    const allowed = await this.store.run(async (tx) => {
      const key = digest(ip);
      const now = new Date();
      const previous = await tx.find("gioi_han_dang_nhap", { ma_bam: key });
      const count =
        previous && (previous.het_han as Date) > now
          ? Number(previous.so_lan) + 1
          : 1;
      const data = {
        so_lan: Math.min(count, 31),
        het_han: count === 1 ? new Date(+now + 60000) : previous!.het_han,
      };
      if (previous)
        await tx.update("gioi_han_dang_nhap", { ma_bam: key }, data);
      else await tx.create("gioi_han_dang_nhap", { ma_bam: key, ...data });
      return count <= 30;
    });
    if (!allowed) throw new HttpException("Rate limited", 429);
    // Expensive hashing is outside the transaction; recheck the hash before issuing a session.
    const user = await this.store.run((tx) =>
      tx.find("nguoi_dung", { ten_dang_nhap: username }),
    );
    const valid = await verify(
      user ? String(user.mat_khau_ma_hoa) : await this.dummy,
      password,
    );
    const token = random();
    const csrf = random();
    const now = new Date();
    const result = await this.store.run(async (tx) => {
      const current = user
        ? await tx.find("nguoi_dung", { ma_nguoi_dung: user.ma_nguoi_dung })
        : null;
      if (
        !current ||
        !current.trang_thai ||
        (current.khoa_den && (current.khoa_den as Date) > now) ||
        current.mat_khau_ma_hoa !== user?.mat_khau_ma_hoa ||
        !valid
      ) {
        if (
          current &&
          current.trang_thai &&
          (!current.khoa_den || (current.khoa_den as Date) <= now)
        ) {
          const failures =
            (current.khoa_den ? 0 : Number(current.so_lan_dang_nhap_sai)) + 1;
          await tx.update(
            "nguoi_dung",
            { ma_nguoi_dung: current.ma_nguoi_dung },
            {
              so_lan_dang_nhap_sai: failures,
              khoa_den: failures >= 5 ? new Date(+now + 15 * 60000) : null,
            },
          );
        }
        await audit(
          tx,
          current ? Number(current.ma_nguoi_dung) : null,
          "LOGIN_FAILED",
          "identity",
        );
        return null;
      }
      await tx.update(
        "nguoi_dung",
        { ma_nguoi_dung: current.ma_nguoi_dung },
        { so_lan_dang_nhap_sai: 0, khoa_den: null },
      );
      await tx.create("phien_lam_viec", {
        ma_bam: digest(token),
        ma_nguoi_dung: current.ma_nguoi_dung,
        csrf,
        het_han: new Date(+now + 8 * 3600000),
        hoat_dong_cuoi: now,
      });
      await audit(tx, Number(current.ma_nguoi_dung), "LOGIN", "identity");
      return publicUser(current);
    });
    if (!result) throw new UnauthorizedException();
    return { ...result, token, csrf };
  }
  async authenticate(token: string): Promise<{ actor: Actor; csrf: string }> {
    if (!/^[a-f0-9]{64}$/.test(token)) throw new UnauthorizedException();
    return this.store.run(async (tx) => {
      const key = digest(token);
      const now = new Date();
      const session = await tx.find("phien_lam_viec", { ma_bam: key });
      if (
        !session ||
        (session.het_han as Date) <= now ||
        +(session.hoat_dong_cuoi as Date) + idle <= +now
      )
        throw new UnauthorizedException();
      const user = await tx.find("nguoi_dung", {
        ma_nguoi_dung: session.ma_nguoi_dung,
      });
      if (!user?.trang_thai) throw new UnauthorizedException();
      await tx.update(
        "phien_lam_viec",
        { ma_bam: key },
        { hoat_dong_cuoi: now },
      );
      return {
        actor: { ...publicUser(user), sessionHash: key },
        csrf: String(session.csrf),
      };
    });
  }
  async logout(actor: Actor) {
    authenticated(actor);
    await this.store.run(async (tx) => {
      await tx.remove("phien_lam_viec", { ma_bam: actor.sessionHash });
      await audit(tx, actor.id, "LOGOUT", "identity");
    });
  }
  async accounts(actor: Actor, after = 0, q?: string) {
    if (q && q.length > 100) throw new BadRequestException();
    administrator(actor);
    return this.store.run(async (tx) => {
      if (!Number.isSafeInteger(after) || after < 0 || after > 2147483647)
        throw new BadRequestException();
      await currentActor(tx, actor);
      const rows = await tx.list(
        "nguoi_dung",
        {
          ma_nguoi_dung: { gt: after },
          ...(q ? { ten_dang_nhap: { contains: q, mode: "insensitive" } } : {}),
        },
        "ma_nguoi_dung",
      );
      return {
        items: rows.slice(0, 50).map(publicUser),
        nextCursor: rows.length > 50 ? String(rows[49]!.ma_nguoi_dung) : null,
      };
    });
  }
  async createAccount(
    actor: Actor,
    input: { username: string; password: string; role: Role },
  ) {
    administrator(actor);
    if (
      !input ||
      typeof input.username !== "string" ||
      Object.keys(input).some(
        (k) => !["username", "password", "role"].includes(k),
      )
    )
      throw new BadRequestException();
    if (
      !/^[a-zA-Z0-9_.-]{3,50}$/.test(input.username) ||
      !roles.includes(input.role)
    )
      throw new BadRequestException();
    const hashed = await passwordHash(input.password);
    return this.store.run(async (tx) => {
      const row = await tx.create("nguoi_dung", {
        ten_dang_nhap: input.username,
        mat_khau_ma_hoa: hashed,
        vai_tro: input.role,
      });
      await currentActor(tx, actor);
      await audit(tx, actor.id, "ACCOUNT_CREATE", String(row.ma_nguoi_dung));
      return publicUser(row);
    });
  }
  async updateAccount(
    actor: Actor,
    id: number,
    input: { role: Role; active: boolean; password?: string },
  ) {
    administrator(actor);
    if (
      !input ||
      Object.keys(input).some(
        (k) => !["role", "active", "password"].includes(k),
      )
    )
      throw new BadRequestException();
    if (!roles.includes(input.role) || typeof input.active !== "boolean")
      throw new BadRequestException();
    const hashed = input.password
      ? await passwordHash(input.password)
      : undefined;
    return this.store.run(async (tx) => {
      const user = await tx.find("nguoi_dung", { ma_nguoi_dung: id });
      if (!user) throw new BadRequestException();
      await currentActor(tx, actor);
      if (
        user.vai_tro === "QUAN_TRI_VIEN" &&
        user.trang_thai &&
        (input.role !== "QUAN_TRI_VIEN" || !input.active) &&
        (await tx.count("nguoi_dung", {
          vai_tro: "QUAN_TRI_VIEN",
          trang_thai: true,
        })) <= 1
      )
        throw new ConflictException();
      if (
        input.role !== user.vai_tro &&
        ((await tx.count("giao_vien", { ma_giao_vien: id })) ||
          (await tx.count("hoc_sinh", { ma_nguoi_dung: id })))
      )
        throw new ConflictException();
      const row = await tx.update(
        "nguoi_dung",
        { ma_nguoi_dung: id },
        {
          vai_tro: input.role,
          trang_thai: input.active,
          khoa_den: null,
          so_lan_dang_nhap_sai: 0,
          ...(hashed ? { mat_khau_ma_hoa: hashed } : {}),
        },
      );
      await tx.remove("phien_lam_viec", { ma_nguoi_dung: id });
      await audit(tx, actor.id, "ACCOUNT_SECURITY_CHANGE", String(id));
      return publicUser(row);
    });
  }
  async changePassword(
    actor: Actor,
    currentPassword: string,
    newPassword: string,
  ) {
    authenticated(actor);
    const user = await this.store.run((tx) =>
      tx.find("nguoi_dung", { ma_nguoi_dung: actor.id }),
    );
    if (
      !user ||
      typeof currentPassword !== "string" ||
      currentPassword.length > 128 ||
      !(await verify(String(user.mat_khau_ma_hoa), currentPassword))
    )
      throw new ForbiddenException();
    const hashed = await passwordHash(newPassword);
    await this.store.run(async (tx) => {
      const current = await tx.find("nguoi_dung", { ma_nguoi_dung: actor.id });
      await currentActor(tx, actor);
      if (current?.mat_khau_ma_hoa !== user.mat_khau_ma_hoa)
        throw new ConflictException();
      await tx.update(
        "nguoi_dung",
        { ma_nguoi_dung: actor.id },
        { mat_khau_ma_hoa: hashed },
      );
      await tx.remove("phien_lam_viec", { ma_nguoi_dung: actor.id });
      await audit(tx, actor.id, "PASSWORD_CHANGE", String(actor.id));
    });
  }
}
