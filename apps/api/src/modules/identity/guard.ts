import {
  ForbiddenException,
  Inject,
  Injectable,
  type CanActivate,
  type ExecutionContext,
} from "@nestjs/common";
import { SETTINGS, type Settings } from "../../common/database.js";
import { IdentityService } from "./application/service.js";
import type { SessionRequest } from "./presentation/controller.js";
@Injectable()
export class SessionGuard implements CanActivate {
  constructor(
    @Inject(IdentityService) private readonly identity: IdentityService,
    @Inject(SETTINGS) private readonly settings: Settings,
  ) {}
  async canActivate(context: ExecutionContext) {
    const req = context.switchToHttp().getRequest<SessionRequest>();
    const res = context.switchToHttp().getResponse();
    const handler = context.getClass().name;
    if (handler === "HealthController" || handler === "NotFoundController")
      return true;
    res.setHeader("Cache-Control", "no-store");
    const origin = req.header("origin");
    const mutation = !["GET", "HEAD", "OPTIONS"].includes(req.method);
    if (origin && !this.settings.origins.includes(origin))
      throw new ForbiddenException();
    if (
      handler === "IdentityController" &&
      context.getHandler().name === "login"
    ) {
      if (!["web", "native"].includes(req.header("x-client-platform") ?? ""))
        throw new ForbiddenException();
      if (req.header("x-client-platform") === "web" && !origin)
        throw new ForbiddenException();
      return true;
    }
    const cookie = req.headers.cookie
      ?.split(";")
      .map((s) => s.trim())
      .find((s) => s.startsWith("qld_session="))
      ?.slice(12);
    const bearer = req
      .header("authorization")
      ?.match(/^Bearer ([a-f0-9]{64})$/)?.[1];
    const session = await this.identity.authenticate(cookie ?? bearer ?? "");
    if (
      cookie &&
      mutation &&
      (!origin || req.header("x-csrf-token") !== session.csrf)
    )
      throw new ForbiddenException();
    req.actor = session.actor;
    req.csrf = session.csrf;
    return true;
  }
}
