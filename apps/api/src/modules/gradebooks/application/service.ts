import {
  BadRequestException,
  Inject,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import { validateInput } from "../../../common/catalog.js";
import type { Actor } from "../../authorization/application/policy.js";
import {
  gradebookAccess,
  gradebookActor,
} from "../../authorization/application/gradebook-policy.js";
import {
  GRADEBOOK_STORE,
  type GradebookStore,
  type GradebookScope,
} from "./port.js";

function id(value: number, allowZero = false) {
  if (
    !Number.isSafeInteger(value) ||
    value < (allowZero ? 0 : 1) ||
    value > 2147483647
  )
    throw new BadRequestException();
  return value;
}
function page<T extends { id: number | string }>(rows: T[]) {
  const items = rows.slice(0, 50);
  return { items, nextCursor: rows.length > 50 ? items[49]!.id : null };
}

@Injectable()
export class GradebooksService {
  constructor(
    @Inject(GRADEBOOK_STORE) private readonly store: GradebookStore,
  ) {}

  create(actor: Actor, input: unknown) {
    const data = validateInput(input, {
      classId: { kind: "int" },
      subjectId: { kind: "int" },
      termId: { kind: "int" },
    }) as unknown as GradebookScope;
    return this.store.run(async (tx) => {
      await gradebookAccess(tx.authorization, actor, data, true);
      return tx.createBlankGrid(actor.sessionHash, data);
    });
  }

  list(actor: Actor, after = 0) {
    id(after, true);
    return this.store.run(async (tx) => {
      await gradebookActor(tx.authorization, actor);
      return page(
        await tx.list(actor.role === "QUAN_TRI_VIEN" ? null : actor.id, after),
      );
    });
  }

  cells(actor: Actor, bookId: number, after = "0") {
    id(bookId);
    if (
      typeof after !== "string" ||
      !/^(0|[1-9][0-9]{0,18})$/.test(after) ||
      BigInt(after) > 9223372036854775807n
    )
      throw new BadRequestException();
    return this.store.run(async (tx) => {
      await gradebookActor(tx.authorization, actor);
      const book = await tx.find(bookId);
      if (!book) throw new NotFoundException();
      await gradebookAccess(tx.authorization, actor, book);
      return { book, ...page(await tx.cells(bookId, after)) };
    });
  }
}
