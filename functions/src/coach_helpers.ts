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

export function zonedDayRange(
  now: Date,
  timeZone: string,
): {start: number; end: number} {
  const start = zonedDateStart(now, safeTimeZone(timeZone));
  const end = zonedDateStart(
    new Date(start + 36 * 60 * 60 * 1000),
    safeTimeZone(timeZone),
  );
  return {start, end};
}

function zonedDateStart(now: Date, timeZone: string): number {
  const key = dateKey(now, timeZone);
  const [year, month, day] = key.split("-").map(Number);
  const utcGuess = Date.UTC(
    year ?? now.getUTCFullYear(),
    (month ?? 1) - 1,
    day ?? 1,
  );
  const firstCandidate = utcGuess - zoneOffsetMilliseconds(utcGuess, timeZone);
  return utcGuess - zoneOffsetMilliseconds(firstCandidate, timeZone);
}

function zoneOffsetMilliseconds(epoch: number, timeZone: string): number {
  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
    hourCycle: "h23",
  }).formatToParts(new Date(epoch));
  const values = Object.fromEntries(parts.map((part) => [part.type, part.value]));
  const representedAsUtc = Date.UTC(
    Number(values.year),
    Number(values.month) - 1,
    Number(values.day),
    Number(values.hour),
    Number(values.minute),
    Number(values.second),
  );
  return representedAsUtc - epoch;
}
