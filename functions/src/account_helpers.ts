export const recentAuthenticationSeconds = 5 * 60;

export function hasRecentAuthentication(
  token: Record<string, unknown>,
  nowSeconds = Math.floor(Date.now() / 1000),
): boolean {
  const authTime = token.auth_time;
  if (typeof authTime !== "number" || !Number.isInteger(authTime)) return false;
  const age = nowSeconds - authTime;
  return age >= 0 && age <= recentAuthenticationSeconds;
}
