import {safeTimeZone} from "./coach_helpers.js";

export const motivationHour = 17;

export function localHour(now: Date, timeZone: unknown): number {
  const safeZone = safeTimeZone(timeZone);
  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone: safeZone,
    hour: "2-digit",
    hourCycle: "h23",
  }).formatToParts(now);
  return Number(parts.find((part) => part.type === "hour")?.value ?? -1);
}

export function isMotivationWindow(now: Date, timeZone: unknown): boolean {
  return localHour(now, timeZone) === motivationHour;
}

export function isPermanentMessagingError(code: unknown): boolean {
  return (
    code === "messaging/invalid-registration-token" ||
    code === "messaging/registration-token-not-registered"
  );
}

export function motivationCopy(dayKey: string): {
  title: string;
  body: string;
} {
  const messages = [
    "Bugünün hedefi için yalnızca bir odak oturumu başlatman yeterli.",
    "Küçük bir tekrar bile ilerlemedir. Şimdi 25 dakikayı tek derse ayır.",
    "Mükemmel planı bekleme; sıradaki görevi açıp ilk adımı tamamla.",
    "Bugünkü emeğin sınav günündeki güvenini oluşturur. Kısa bir oturum başlat.",
  ];
  const seed = [...dayKey].reduce((total, char) => total + char.charCodeAt(0), 0);
  return {
    title: "Küçük bir adım yeter",
    body: messages[seed % messages.length]!,
  };
}
