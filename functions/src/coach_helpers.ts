export const dailyCoachLimit = 20;

export interface AskCoachInput {
  message: string;
  conversationId: string;
}

export function parseAskCoachInput(data: unknown): AskCoachInput {
  if (typeof data !== "object" || data === null) {
    throw new Error("invalid-argument");
  }
  const record = data as Record<string, unknown>;
  const message = typeof record.message === "string" ? record.message.trim() : "";
  const conversationId =
    typeof record.conversationId === "string" ? record.conversationId.trim() : "";
  if (message.length < 1 || message.length > 2000) {
    throw new Error("invalid-message");
  }
  if (!/^[a-zA-Z0-9_-]{1,64}$/.test(conversationId)) {
    throw new Error("invalid-conversation");
  }
  return {message, conversationId};
}

export function dateKey(now: Date, timeZone: string): string {
  try {
    const parts = new Intl.DateTimeFormat("en-CA", {
      timeZone,
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
    }).formatToParts(now);
    const value = Object.fromEntries(parts.map((part) => [part.type, part.value]));
    return `${value.year}-${value.month}-${value.day}`;
  } catch {
    return dateKey(now, "Europe/Istanbul");
  }
}

export function safeTimeZone(value: unknown): string {
  if (typeof value !== "string" || value.length > 60) return "Europe/Istanbul";
  try {
    new Intl.DateTimeFormat("en", {timeZone: value}).format();
    return value;
  } catch {
    return "Europe/Istanbul";
  }
}

export function verifiedProvider(token: Record<string, unknown>): boolean {
  if (token.email_verified !== true) return false;
  const firebase = token.firebase;
  if (typeof firebase !== "object" || firebase === null) return false;
  const provider = (firebase as Record<string, unknown>).sign_in_provider;
  return provider === "password" || provider === "google.com";
}

export function boundedText(value: unknown, maximum = 120): string {
  return typeof value === "string" ? value.slice(0, maximum) : "";
}
