import {
  Controller,
  Get,
  Inject,
  Injectable,
  ServiceUnavailableException,
} from "@nestjs/common";
import {
  ApiOkResponse,
  ApiProperty,
  ApiServiceUnavailableResponse,
  ApiTags,
} from "@nestjs/swagger";
import { ErrorDto } from "./http.js";

export const PROBE = Symbol("DEPENDENCY_PROBE");
export interface DependencyProbe {
  check(): Promise<boolean>;
  close(): Promise<void>;
}
export class HealthDto {
  @ApiProperty({ type: String, enum: ["ok"], example: "ok" })
  status = "ok" as const;
}
@Injectable()
export class HealthService {
  constructor(@Inject(PROBE) private readonly probe: DependencyProbe) {}
  async ready(): Promise<HealthDto> {
    if (!(await this.probe.check())) throw new ServiceUnavailableException();
    return new HealthDto();
  }
}
@ApiTags("health")
@Controller("health")
export class HealthController {
  constructor(@Inject(HealthService) private readonly service: HealthService) {}
  @Get("live")
  @ApiOkResponse({ type: HealthDto })
  live(): HealthDto {
    return new HealthDto();
  }
  @Get("ready")
  @ApiOkResponse({ type: HealthDto })
  @ApiServiceUnavailableResponse({ type: ErrorDto })
  ready(): Promise<HealthDto> {
    return this.service.ready();
  }
}
