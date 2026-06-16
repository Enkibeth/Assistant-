export interface DeliveryResult {
  status: "sent" | "dry-run";
  id: string;
  provider: string;
}

export function newOutboundId(prefix: string): string {
  return `${prefix}_${Date.now().toString(36)}${Math.random().toString(36).slice(2, 8)}`;
}
