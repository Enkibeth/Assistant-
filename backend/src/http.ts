/** Petites primitives HTTP partagées entre le routeur et le serveur node:http. */
import { z } from "zod";

export interface ApiRequest {
  method: string;
  path: string;
  headers: Record<string, string | undefined>;
  /** Corps déjà parsé en JSON (ou undefined si vide / non-JSON). */
  body: unknown;
}

export interface ApiResponse {
  status: number;
  body: unknown;
}

export function json(status: number, body: unknown): ApiResponse {
  return { status, body };
}

export class HttpError extends Error {
  constructor(public readonly status: number, message: string, public readonly extra?: unknown) {
    super(message);
    this.name = "HttpError";
  }
}

/** Valide `body` avec un schéma Zod, lève 400 structuré si invalide. */
export function parse<S extends z.ZodTypeAny>(schema: S, body: unknown): z.infer<S> {
  const result = schema.safeParse(body);
  if (!result.success) {
    throw new HttpError(400, "validation_error", { issues: result.error.issues });
  }
  return result.data;
}
