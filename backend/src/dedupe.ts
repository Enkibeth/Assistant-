/**
 * Déduplication idempotente en mémoire avec TTL.
 * MVP : suffisant pour une seule instance. En prod, remplacer par un store
 * partagé (Cloudflare KV, Redis…) pour couvrir le multi-instance.
 */
export class DedupeStore {
  private readonly seen = new Map<string, number>();
  constructor(private readonly ttlMs: number = 24 * 60 * 60 * 1000) {}

  /** Renvoie true si la clé est nouvelle (et la marque), false si déjà vue. */
  claim(key: string, now: number = Date.now()): boolean {
    this.sweep(now);
    const expiry = this.seen.get(key);
    if (expiry !== undefined && expiry > now) {
      return false;
    }
    this.seen.set(key, now + this.ttlMs);
    return true;
  }

  private sweep(now: number): void {
    for (const [key, expiry] of this.seen) {
      if (expiry <= now) this.seen.delete(key);
    }
  }

  get size(): number {
    return this.seen.size;
  }
}

/** Instance partagée par défaut du process. */
export const dedupe = new DedupeStore();
