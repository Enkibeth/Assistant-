/**
 * Contrats partagés (source de vérité) — voir docs/backend-api.md.
 * Miroir Codable côté Swift : ios-app/Assistant/Models/SharedContracts.swift
 */
import { z } from "zod";

export const interruptionLevel = z.enum(["passive", "active", "time-sensitive"]);
export type InterruptionLevel = z.infer<typeof interruptionLevel>;

export const briefingItemKind = z.enum([
  "event",
  "reminder",
  "birthday",
  "conflict",
  "deadline",
  "forgotten",
]);
export type BriefingItemKind = z.infer<typeof briefingItemKind>;

export const briefingItem = z.object({
  id: z.string().min(1),
  kind: briefingItemKind,
  title: z.string().min(1),
  detail: z.string().optional(),
  date: z.string().datetime({ offset: true }).optional(),
  priorityScore: z.number().min(0).max(1),
});
export type BriefingItem = z.infer<typeof briefingItem>;

export const briefing = z.object({
  userId: z.string().min(1),
  date: z.string().min(1),
  summary: z.string(),
  items: z.array(briefingItem),
});
export type Briefing = z.infer<typeof briefing>;

export const pushRequest = z.object({
  userId: z.string().min(1),
  deviceToken: z.string().min(1),
  title: z.string().min(1),
  body: z.string().min(1),
  interruptionLevel: interruptionLevel.default("active"),
  dedupeKey: z.string().min(1),
  context: z.record(z.unknown()).optional(),
});
export type PushRequest = z.infer<typeof pushRequest>;

export const emailRequest = z.object({
  userId: z.string().min(1),
  to: z.string().email(),
  subject: z.string().min(1),
  text: z.string().min(1),
  dedupeKey: z.string().min(1),
});
export type EmailRequest = z.infer<typeof emailRequest>;

export const smsRequest = z.object({
  userId: z.string().min(1),
  to: z.string().regex(/^\+[1-9]\d{6,14}$/, "numéro E.164 attendu (+33…)"),
  body: z.string().min(1).max(1600),
  dedupeKey: z.string().min(1),
});
export type SmsRequest = z.infer<typeof smsRequest>;
