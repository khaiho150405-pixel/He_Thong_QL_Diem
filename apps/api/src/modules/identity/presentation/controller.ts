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
import {
  type Actor,
  roles,
  type Role,
} from "../../authorization/application/policy.js";
import { IdentityService } from "../application/service.js";
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
  @ApiProperty({ type: String, nullable: true }) token!: string | null;
  @ApiProperty({ type: String }) csrf!: string;
}
export class AccountsDto {
  @ApiProperty({ type: [AccountDto] }) items!: AccountDto[];
  @ApiProperty({ type: String, nullable: true }) nextCursor!: string | null;
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
    );
    res.setHeader("Cache-Control", "no-store");
    if (req.header("x-client-platform") === "web") {
      res.cookie("qld_session", result.token, {
        httpOnly: true,
        secure: this.settings.environment !== "development",
        sameSite: "strict",
        path: "/api/v1",
        maxAge: 8 * 3600000,
      });
      return { ...result, token: null };
    }
    return result;
  }
  @Get("me")
  @ApiOkResponse({ type: SessionDto })
  me(@Req() req: SessionRequest) {
    return {
      id: req.actor.id,
      username: req.actor.username,
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
      secure: this.settings.environment !== "development",
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
  accounts(
    @Req() req: SessionRequest,
    @Query("cursor") cursor?: string,
    @Query("q") q?: string,
  ) {
    return this.service.accounts(req.actor, cursor ? Number(cursor) : 0, q);
  }
  @Post("accounts")
  @HttpCode(200)
  @ApiBody({ type: AccountInput })
  @ApiOkResponse({ type: AccountDto })
  createAccount(@Req() req: SessionRequest, @Body() body: unknown) {
    return this.service.createAccount(req.actor, body as AccountInput);
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
