import {
  Body,
  Controller,
  Get,
  HttpCode,
  Inject,
  Param,
  ParseIntPipe,
  Post,
  Put,
  Query,
  Req,
  Res,
} from "@nestjs/common";
import {
  ApiBody,
  ApiHeader,
  ApiOkResponse,
  ApiParam,
  ApiProperty,
  ApiPropertyOptional,
  ApiQuery,
  ApiTags,
} from "@nestjs/swagger";
import type { Request, Response } from "express";
import { SETTINGS, type Settings } from "../../../common/database.js";
import { isPublicFacing } from "../../../common/config.js";
import { allowQuery } from "../../../common/query.js";
import {
  type Actor,
  roles,
  type Role,
} from "../../authorization/application/policy.js";
import { IdentityService } from "../application/service.js";
import { WEB_SESSION_MS } from "../../authorization/application/session-policy.js";
export interface SessionRequest extends Request {
  actor: Actor;
  csrf: string;
}
export class LoginInput {
  @ApiProperty({ type: String }) username!: string;
  @ApiProperty({ type: String, format: "password" }) password!: string;
}
export class ProfileDto {
  @ApiProperty({ type: String }) name!: string;
  @ApiProperty({ type: String, nullable: true }) email!: string | null;
  @ApiProperty({ type: String, nullable: true }) phone!: string | null;
}
export class AccountInput extends LoginInput {
  @ApiProperty({ type: String, enum: roles }) role!: Role;
}
export class AccountUpdate {
  @ApiProperty({ type: String, enum: roles }) role!: Role;
  @ApiProperty({ type: Boolean }) active!: boolean;
  @ApiPropertyOptional({ type: String, format: "password" }) password?: string;
}
export class PasswordInput {
  @ApiProperty({ type: String, format: "password" }) currentPassword!: string;
  @ApiProperty({
    type: String,
    format: "password",
    minLength: 12,
    maxLength: 128,
  })
  newPassword!: string;
}
export class AccountDto {
  @ApiProperty({ type: Number }) id!: number;
  @ApiProperty({ type: String }) username!: string;
  @ApiProperty({ type: String, enum: roles }) role!: Role;
  @ApiProperty({ type: Boolean }) active!: boolean;
}
export class SessionDto extends AccountDto {
  @ApiPropertyOptional({ type: String, nullable: true })
  displayName?: string | null;
  @ApiProperty({ type: String, nullable: true }) token!: string | null;
  @ApiProperty({ type: String }) csrf!: string;
}
export class AccountsDto {
  @ApiProperty({ type: [AccountDto] }) items!: AccountDto[];
  @ApiProperty({ type: String, nullable: true }) nextCursor!: string | null;
}
export class AccountsImportInput {
  @ApiProperty({ type: [AccountInput], maxItems: 500 }) items!: AccountInput[];
}
export class AccountsImportResult {
  @ApiProperty({ type: Number }) imported!: number;
  @ApiProperty({ type: [AccountDto] }) items!: AccountDto[];
}
@ApiTags("identity")
@Controller("identity")
export class IdentityController {
  @Get("profile")
  @ApiOkResponse({ type: ProfileDto })
  profile(@Req() req: SessionRequest) {
    return this.service.profile(req.actor);
  }
  @Put("profile")
  @ApiBody({ type: ProfileDto })
  @ApiOkResponse({ type: ProfileDto })
  updateProfile(@Req() req: SessionRequest, @Body() input: unknown) {
    return this.service.profile(req.actor, input);
  }
  constructor(
    @Inject(IdentityService) private readonly service: IdentityService,
    @Inject(SETTINGS) private readonly settings: Settings,
  ) {}
  @Post("login")
  @ApiHeader({
    name: "x-client-platform",
    required: true,
    enum: ["web", "native"],
  })
  @HttpCode(200)
  @ApiBody({ type: LoginInput })
  @ApiOkResponse({ type: SessionDto })
  async login(
    @Body() input: unknown,
    @Req() req: Request,
    @Res({ passthrough: true }) res: Response,
  ) {
    const body = input as LoginInput;
    const result = await this.service.login(
      body?.username,
      body?.password,
      req.socket.remoteAddress ?? "unknown",
      req.header("x-client-platform") === "native",
    );
    res.setHeader("Cache-Control", "no-store");
    const { remember, ...session } = result;
    if (req.header("x-client-platform") === "web") {
      res.cookie("qld_session", result.token, {
        httpOnly: true,
        secure: isPublicFacing(this.settings),
        sameSite: "strict",
        path: "/api/v1",
        maxAge: WEB_SESSION_MS,
      });
      return { ...session, token: null };
    }
    if (remember) res.setHeader("x-remember-token", remember);
    return session;
  }
  @Post("resume")
  @ApiHeader({ name: "x-client-platform", required: true, enum: ["native"] })
  @ApiHeader({ name: "x-remember-token", required: true })
  @HttpCode(200)
  @ApiOkResponse({ type: SessionDto })
  async resume(@Req() req: Request, @Res({ passthrough: true }) res: Response) {
    const result = await this.service.resume(
      req.header("x-remember-token") ?? "",
    );
    res.setHeader("Cache-Control", "no-store");
    const { remember, ...session } = result;
    res.setHeader("x-remember-token", remember);
    return session;
  }
  @Get("me")
  @ApiOkResponse({ type: SessionDto })
  async me(@Req() req: SessionRequest) {
    return {
      id: req.actor.id,
      username: req.actor.username,
      displayName: await this.service.displayName(req.actor),
      role: req.actor.role,
      active: true,
      csrf: req.csrf,
      token: null,
    };
  }
  @Post("logout")
  @HttpCode(204)
  async logout(
    @Req() req: SessionRequest,
    @Res({ passthrough: true }) res: Response,
  ) {
    await this.service.logout(req.actor);
    res.clearCookie("qld_session", {
      path: "/api/v1",
      httpOnly: true,
      sameSite: "strict",
      secure: isPublicFacing(this.settings),
    });
  }
  @Post("password")
  @HttpCode(204)
  @ApiBody({ type: PasswordInput })
  password(@Req() req: SessionRequest, @Body() input: unknown) {
    const body = input as PasswordInput;
    return this.service.changePassword(
      req.actor,
      body?.currentPassword,
      body?.newPassword,
    );
  }
  @Get("accounts")
  @ApiOkResponse({ type: AccountsDto })
  @ApiQuery({ name: "cursor", type: String, required: false })
  @ApiQuery({ name: "q", type: String, required: false })
  @ApiQuery({
    name: "limit",
    type: Number,
    required: false,
    description: "Số dòng mỗi trang, từ 1 đến 500; vắng = 50",
  })
  @ApiQuery({
    name: "role",
    enum: roles,
    required: false,
    description: "Chỉ tài khoản của vai trò này; vắng = tất cả",
  })
  accounts(
    @Req() req: SessionRequest,
    @Query("cursor") cursor?: string,
    @Query("q") q?: string,
    @Query("limit") limit?: string,
    @Query("role") role?: string,
  ) {
    allowQuery(req.query, ["cursor", "q", "limit", "role"]);
    return this.service.accounts(
      req.actor,
      cursor ? Number(cursor) : 0,
      q,
      limit,
      role,
    );
  }
  @Post("accounts")
  @HttpCode(200)
  @ApiBody({ type: AccountInput })
  @ApiOkResponse({ type: AccountDto })
  createAccount(@Req() req: SessionRequest, @Body() body: unknown) {
    return this.service.createAccount(req.actor, body as AccountInput);
  }
  @Post("accounts/import")
  @HttpCode(200)
  @ApiBody({ type: AccountsImportInput })
  @ApiOkResponse({ type: AccountsImportResult })
  importAccounts(
    @Req() req: SessionRequest,
    @Body() body: AccountsImportInput,
  ) {
    return this.service.importAccounts(req.actor, body?.items ?? []);
  }
  @Put("accounts/:id")
  @ApiBody({ type: AccountUpdate })
  @ApiOkResponse({ type: AccountDto })
  @ApiParam({ name: "id", type: Number })
  updateAccount(
    @Req() req: SessionRequest,
    @Param("id", ParseIntPipe) id: number,
    @Body() body: unknown,
  ) {
    return this.service.updateAccount(req.actor, id, body as AccountUpdate);
  }
}
