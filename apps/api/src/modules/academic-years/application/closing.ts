import { BadRequestException, Inject, Injectable } from "@nestjs/common";
import { STORE, type Store } from "../../../common/store.js";
import {
  administrator,
  currentActor,
  type Actor,
} from "../../authorization/application/policy.js";
import { YEAR_CLOSING_STORE, type YearClosingStore } from "./closing-port.js";

function reasonOf(input: unknown) {
  const body =
    input && typeof input === "object" && !Array.isArray(input)
      ? (input as Record<string, unknown>)
      : {};
  const reason = typeof body.reason === "string" ? body.reason.trim() : "";
  if (!reason || reason.length > 500 || Object.keys(body).length !== 1)
    throw new BadRequestException("Cần nhập lý do từ 1 đến 500 ký tự.");
  return reason;
}

@Injectable()
export class YearClosingService {
  constructor(
    @Inject(STORE) private readonly store: Store,
    @Inject(YEAR_CLOSING_STORE) private readonly closing: YearClosingStore,
  ) {}

  async status(actor: Actor, yearId: number) {
    await this.authorize(actor, yearId);
    return this.closing.status(yearId);
  }

  async change(actor: Actor, yearId: number, close: boolean, input: unknown) {
    await this.authorize(actor, yearId);
    await this.closing.change(
      actor.sessionHash,
      yearId,
      close,
      reasonOf(input),
    );
    return this.closing.status(yearId);
  }

  private async authorize(actor: Actor, yearId: number) {
    administrator(actor);
    if (!Number.isSafeInteger(yearId) || yearId < 1 || yearId > 2147483647)
      throw new BadRequestException("Mã năm học không hợp lệ.");
    await this.store.run((tx) => currentActor(tx, actor));
  }
}
