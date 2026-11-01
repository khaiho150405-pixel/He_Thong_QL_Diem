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
export function accountUsername(username: unknown, role: Role): boolean {
  return (
    typeof username === "string" &&
    (role === "QUAN_TRI_VIEN"
      ? /^[a-zA-Z0-9_.-]{3,50}$/.test(username)
      : /^0[0-9]{9}$/.test(username))
  );
}
const ONLY_ADMIN_MESSAGE =
  "Hệ thống chỉ có một tài khoản quản trị viên duy nhất, không thể cấp thêm vai trò này.";
const idle = 30 * 60 * 1000;
const rememberLifetime = 30 * 24 * 3600 * 1000;
/** Chỉ ghi lại hoat_dong_cuoi khi giá trị cũ đã quá 60 giây (hạn idle 30 phút vẫn kiểm đúng như cũ). */
const touchInterval = 60 * 1000;
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
        if (data.name.trim() !== row.ho_ten)
          throw new ForbiddenException(
            "Họ tên do nhà trường quản lý; liên hệ quản trị viên để điều chỉnh.",
          );
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
  async login(
    username: string,
    password: string,
    ip: string,
    remember = false,
  ) {
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
    const rememberToken = remember ? random() : null;
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
      if (rememberToken)
        await tx.create("phien_ghi_nho", {
          ma_bam: digest(rememberToken),
          ma_nguoi_dung: current.ma_nguoi_dung,
          het_han: new Date(+now + rememberLifetime),
        });
      await audit(tx, Number(current.ma_nguoi_dung), "LOGIN", "identity");
      return publicUser(current);
    });
    if (!result) throw new UnauthorizedException();
    return { ...result, token, csrf, remember: rememberToken };
  }
  /**
   * Mở lại app di động: đổi mã ghi nhớ (dùng một lần) lấy phiên mới và mã ghi nhớ mới.
   * Mã sai/hết hạn/đã dùng, hoặc tài khoản bị khóa → 401 (client xóa mã và về màn đăng nhập).
   */
  async resume(rememberToken: string) {
    if (!/^[a-f0-9]{64}$/.test(rememberToken ?? ""))
      throw new UnauthorizedException();
    const token = random();
    const csrf = random();
    const next = random();
    const now = new Date();
    const result = await this.store.run(async (tx) => {
      const key = digest(rememberToken);
      const saved = await tx.find("phien_ghi_nho", { ma_bam: key });
      if (!saved) return null;
      await tx.remove("phien_ghi_nho", { ma_bam: key });
      if ((saved.het_han as Date) <= now) return null;
      const user = await tx.find("nguoi_dung", {
        ma_nguoi_dung: saved.ma_nguoi_dung,
      });
      if (!user?.trang_thai || (user.khoa_den && (user.khoa_den as Date) > now))
        return null;
      await tx.create("phien_lam_viec", {
        ma_bam: digest(token),
        ma_nguoi_dung: user.ma_nguoi_dung,
        csrf,
        het_han: new Date(+now + 8 * 3600000),
        hoat_dong_cuoi: now,
      });
      await tx.create("phien_ghi_nho", {
        ma_bam: digest(next),
        ma_nguoi_dung: user.ma_nguoi_dung,
        het_han: new Date(+now + rememberLifetime),
      });
      await audit(tx, Number(user.ma_nguoi_dung), "SESSION_RESUME", "identity");
      return publicUser(user);
    });
    if (!result) throw new UnauthorizedException();
    return { ...result, token, csrf, remember: next };
  }
  /**
   * Gia hạn hoạt động của phiên bằng một UPDATE có điều kiện, ở mức ReadCommitted và ngoài giao dịch Serializable của request:
   * nhiều request song song của cùng phiên không còn ghi–đọc chéo nhau trên một dòng (nguồn của 40001 → 409). Request đến
   * sau thấy giá trị mới và không ghi gì. Điều kiện nằm trong WHERE nên không bao giờ lùi hoat_dong_cuoi.
   */
  private async touchSession(key: string): Promise<void> {
    const now = new Date();
    await this.store.run(
      (tx) =>
        tx.updateMany(
          "phien_lam_viec",
          {
            ma_bam: key,
            hoat_dong_cuoi: { lt: new Date(+now - touchInterval) },
          },
          { hoat_dong_cuoi: now },
        ),
      { isolationLevel: "ReadCommitted" },
    );
  }
  async authenticate(token: string): Promise<{ actor: Actor; csrf: string }> {
    if (!/^[a-f0-9]{64}$/.test(token)) throw new UnauthorizedException();
    const result = await this.store.run(async (tx) => {
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
      return {
        actor: { ...publicUser(user), sessionHash: key },
        csrf: String(session.csrf),
        // Chỉ cần chạm phiên khi giá trị cũ đã quá touchInterval; phần lớn request không ghi gì.
        stale: +(session.hoat_dong_cuoi as Date) + touchInterval <= +now,
      };
    });
    if (result.stale) await this.touchSession(result.actor.sessionHash);
    return { actor: result.actor, csrf: result.csrf };
  }
  async logout(actor: Actor) {
    authenticated(actor);
    await this.store.run(async (tx) => {
      await tx.remove("phien_lam_viec", { ma_bam: actor.sessionHash });
      await tx.remove("phien_ghi_nho", { ma_nguoi_dung: actor.id });
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
      !accountUsername(input.username, input.role) ||
      !roles.includes(input.role)
    )
      throw new BadRequestException(
        "Tài khoản giáo viên/học sinh phải dùng số điện thoại 10 chữ số, bắt đầu bằng 0.",
      );
    if (input.role === "QUAN_TRI_VIEN")
      throw new BadRequestException(ONLY_ADMIN_MESSAGE);
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
  async importAccounts(
    actor: Actor,
    inputs: Array<{ username: string; password: string; role: Role }>,
  ) {
    administrator(actor);
    if (!Array.isArray(inputs) || inputs.length < 1 || inputs.length > 500)
      throw new BadRequestException("Tệp nhập phải có từ 1 đến 500 dòng.");
    const prepared = await Promise.all(
      inputs.map(async (input) => {
        if (
          !input ||
          Object.keys(input).some(
            (key) => !["username", "password", "role"].includes(key),
          ) ||
          !accountUsername(input.username, input.role) ||
          !roles.includes(input.role)
        )
          throw new BadRequestException(
            "Tài khoản nhập không hợp lệ: giáo viên/học sinh phải dùng số điện thoại 10 chữ số bắt đầu bằng 0; giữ cột username ở dạng văn bản.",
          );
        if (input.role === "QUAN_TRI_VIEN")
          throw new BadRequestException(ONLY_ADMIN_MESSAGE);
        return { ...input, hashed: await passwordHash(input.password) };
      }),
    );
    return this.store.run(async (tx) => {
      await currentActor(tx, actor);
      const created: Row[] = [];
      for (const input of prepared) {
        const row = await tx.create("nguoi_dung", {
          ten_dang_nhap: input.username,
          mat_khau_ma_hoa: input.hashed,
          vai_tro: input.role,
        });
        await audit(tx, actor.id, "ACCOUNT_IMPORT", String(row.ma_nguoi_dung));
        created.push(row);
      }
      return { imported: created.length, items: created.map(publicUser) };
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
      if (input.role === "QUAN_TRI_VIEN" && user.vai_tro !== "QUAN_TRI_VIEN")
        throw new BadRequestException(ONLY_ADMIN_MESSAGE);
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
      await tx.remove("phien_ghi_nho", { ma_nguoi_dung: id });
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
    if (actor.role === "HOC_SINH")
      throw new ForbiddenException(
        "Học sinh không được tự đổi mật khẩu; liên hệ quản trị viên.",
      );
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
      await tx.remove("phien_ghi_nho", { ma_nguoi_dung: actor.id });
      await audit(tx, actor.id, "PASSWORD_CHANGE", String(actor.id));
    });
  }
}
