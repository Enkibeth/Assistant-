/**
 * Génération du résumé textuel d'un briefing. Fonction PURE — même logique que
 * le rendu local côté app (BriefingGenerator.swift). Le rendu local reste le
 * défaut ; cette route serveur sert à centraliser la formulation si besoin.
 */
import type { Briefing, BriefingItem } from "../schemas.js";

function count(items: BriefingItem[], kind: BriefingItem["kind"]): number {
  return items.filter((i) => i.kind === kind).length;
}

function plural(n: number, singular: string, plural: string): string {
  return `${n} ${n > 1 ? plural : singular}`;
}

export function renderSummary(b: Briefing): string {
  if (b.items.length === 0) {
    return "Rien de prévu aujourd'hui. Journée libre 🎉";
  }

  const parts: string[] = [];
  const events = count(b.items, "event");
  const deadlines = count(b.items, "deadline");
  const reminders = count(b.items, "reminder");
  const conflicts = count(b.items, "conflict");
  const birthdays = count(b.items, "birthday");
  const forgotten = count(b.items, "forgotten");

  if (events > 0) parts.push(`tu as ${plural(events, "événement", "événements")}`);
  if (deadlines > 0) parts.push(plural(deadlines, "échéance", "échéances"));
  if (reminders > 0) parts.push(plural(reminders, "rappel", "rappels"));

  let summary = parts.length > 0
    ? `Aujourd'hui, ${parts.join(", ")}.`
    : "Aujourd'hui :";

  if (conflicts > 0) {
    summary += ` ⚠️ ${plural(conflicts, "conflit d'agenda", "conflits d'agenda")} à arbitrer.`;
  }
  if (birthdays > 0) {
    const next = b.items.find((i) => i.kind === "birthday");
    summary += ` 🎂 ${next?.title ?? "Un anniversaire approche"}.`;
  }
  if (forgotten > 0) {
    summary += ` 💡 ${plural(forgotten, "oubli probable", "oublis probables")} à vérifier.`;
  }

  return summary;
}

/** Trie par priorité décroissante (utile pour l'ordre d'affichage). */
export function sortByPriority(items: BriefingItem[]): BriefingItem[] {
  return [...items].sort((a, b) => b.priorityScore - a.priorityScore);
}
