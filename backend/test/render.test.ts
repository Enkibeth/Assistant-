import assert from "node:assert/strict";
import { test } from "node:test";
import { renderSummary, sortByPriority } from "../src/briefing/render.js";
import type { Briefing, BriefingItem } from "../src/schemas.js";

function briefing(items: BriefingItem[]): Briefing {
  return { userId: "u_1", date: "2026-06-16", summary: "", items };
}

test("journée vide → message dédié", () => {
  assert.match(renderSummary(briefing([])), /Journée libre/);
});

test("compte événements, échéances et conflits", () => {
  const s = renderSummary(
    briefing([
      { id: "1", kind: "event", title: "Réunion", priorityScore: 0.5 },
      { id: "2", kind: "event", title: "Déjeuner", priorityScore: 0.4 },
      { id: "3", kind: "deadline", title: "Rapport", priorityScore: 0.9 },
      { id: "4", kind: "conflict", title: "Chevauchement", priorityScore: 0.8 },
    ]),
  );
  assert.match(s, /2 événements/);
  assert.match(s, /1 échéance/);
  assert.match(s, /conflit/);
});

test("affiche le titre de l'anniversaire", () => {
  const s = renderSummary(
    briefing([{ id: "b", kind: "birthday", title: "Anniversaire de Paul (J-7)", priorityScore: 0.6 }]),
  );
  assert.match(s, /Paul/);
});

test("sortByPriority ordonne par score décroissant", () => {
  const sorted = sortByPriority([
    { id: "a", kind: "event", title: "A", priorityScore: 0.2 },
    { id: "b", kind: "event", title: "B", priorityScore: 0.9 },
    { id: "c", kind: "event", title: "C", priorityScore: 0.5 },
  ]);
  assert.deepEqual(sorted.map((i) => i.id), ["b", "c", "a"]);
});
