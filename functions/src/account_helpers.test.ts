import assert from "node:assert/strict";
import test from "node:test";

import {
  hasRecentAuthentication,
  recentAuthenticationSeconds,
} from "./account_helpers.js";

test("account deletion requires a recent authentication", () => {
  const now = 2_000_000_000;
  assert.equal(hasRecentAuthentication({auth_time: now}, now), true);
  assert.equal(
    hasRecentAuthentication(
      {auth_time: now - recentAuthenticationSeconds},
      now,
    ),
    true,
  );
  assert.equal(
    hasRecentAuthentication(
      {auth_time: now - recentAuthenticationSeconds - 1},
      now,
    ),
    false,
  );
  assert.equal(hasRecentAuthentication({auth_time: now + 1}, now), false);
  assert.equal(hasRecentAuthentication({}, now), false);
});
