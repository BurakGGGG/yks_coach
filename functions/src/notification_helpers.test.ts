import assert from "node:assert/strict";
import test from "node:test";

import {
  isMotivationWindow,
  isPermanentMessagingError,
  localHour,
  motivationCopy,
} from "./notification_helpers.js";

test("motivation window respects device timezone", () => {
  const instant = new Date("2026-06-30T14:10:00.000Z");
  assert.equal(localHour(instant, "Europe/Istanbul"), 17);
  assert.equal(isMotivationWindow(instant, "Europe/Istanbul"), true);
  assert.equal(isMotivationWindow(instant, "UTC"), false);
  assert.equal(localHour(instant, "invalid/timezone"), 17);
});

test("only permanent FCM token errors trigger device cleanup", () => {
  assert.equal(
    isPermanentMessagingError("messaging/registration-token-not-registered"),
    true,
  );
  assert.equal(
    isPermanentMessagingError("messaging/invalid-registration-token"),
    true,
  );
  assert.equal(isPermanentMessagingError("messaging/internal-error"), false);
});

test("motivation copy is deterministic and non-empty", () => {
  assert.deepEqual(motivationCopy("2026-06-30"), motivationCopy("2026-06-30"));
  assert.ok(motivationCopy("2026-06-30").title.length > 0);
  assert.ok(motivationCopy("2026-06-30").body.length > 20);
});
