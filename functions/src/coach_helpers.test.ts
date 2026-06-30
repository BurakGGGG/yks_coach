import assert from "node:assert/strict";
import test from "node:test";

import {
  dateKey,
  parseAskCoachInput,
  safeTimeZone,
  verifiedProvider,
} from "./coach_helpers.js";

test("askCoach input trims and validates fields", () => {
  assert.deepEqual(
    parseAskCoachInput({message: "  Plan yapalım  ", conversationId: "main"}),
    {message: "Plan yapalım", conversationId: "main"},
  );
  assert.throws(() => parseAskCoachInput({message: "", conversationId: "main"}));
  assert.throws(() =>
    parseAskCoachInput({message: "ok", conversationId: "../unsafe"}),
  );
});

test("daily quota key respects the user timezone", () => {
  const instant = new Date("2026-06-29T21:30:00.000Z");
  assert.equal(dateKey(instant, "Europe/Istanbul"), "2026-06-30");
  assert.equal(dateKey(instant, "UTC"), "2026-06-29");
  assert.equal(safeTimeZone("not/a-zone"), "Europe/Istanbul");
});

test("only verified password and Google providers pass", () => {
  assert.equal(
    verifiedProvider({
      email_verified: true,
      firebase: {sign_in_provider: "password"},
    }),
    true,
  );
  assert.equal(
    verifiedProvider({
      email_verified: true,
      firebase: {sign_in_provider: "google.com"},
    }),
    true,
  );
  assert.equal(
    verifiedProvider({
      email_verified: false,
      firebase: {sign_in_provider: "password"},
    }),
    false,
  );
  assert.equal(
    verifiedProvider({
      email_verified: true,
      firebase: {sign_in_provider: "anonymous"},
    }),
    false,
  );
});
