/** Logger minimal et structuré. Ne journalise jamais de contenu sensible brut. */

type Level = "info" | "warn" | "error";

function emit(level: Level, msg: string, meta?: Record<string, unknown>): void {
  const line = {
    ts: new Date().toISOString(),
    level,
    msg,
    ...(meta ?? {}),
  };
  const sink = level === "error" ? console.error : console.log;
  sink(JSON.stringify(line));
}

export const log = {
  info: (msg: string, meta?: Record<string, unknown>) => emit("info", msg, meta),
  warn: (msg: string, meta?: Record<string, unknown>) => emit("warn", msg, meta),
  error: (msg: string, meta?: Record<string, unknown>) => emit("error", msg, meta),
};

/** Tronque un texte pour éviter de logger un message complet. */
export function redact(text: string | undefined, keep = 12): string {
  if (!text) return "";
  return text.length <= keep ? "***" : `${text.slice(0, keep)}…(${text.length})`;
}
