import assert from "node:assert/strict";
import test from "node:test";
import { BadRequestException } from "@nestjs/common";
import { allowQuery } from "../src/common/query.js";

test("allowQuery accepts only listed query keys", () => {
  assert.doesNotThrow(() => allowQuery({}, ["cursor"]));
  assert.doesNotThrow(() =>
    allowQuery({ cursor: "1", yearId: "2" }, ["cursor", "q", "yearId"]),
  );
  for (const query of [
    { sort: "secret" },
    { limit: "999999" },
    { cursor: "1", sort: "secret" },
  ])
    assert.throws(
      () => allowQuery(query, ["cursor", "q", "yearId"]),
      BadRequestException,
    );
});
