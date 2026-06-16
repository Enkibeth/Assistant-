/**
 * Configuration dérivée des variables d'environnement.
 * Détecte automatiquement le mode "dry-run" par fournisseur : si les secrets
 * d'un fournisseur sont absents, ses envois sont simplement journalisés.
 */

function env(name: string): string | undefined {
  const v = process.env[name];
  return v && v.trim().length > 0 ? v.trim() : undefined;
}

export const config = {
  port: Number(env("PORT") ?? 8787),
  apiToken: env("ARIA_API_TOKEN"),

  apns: {
    keyId: env("APNS_KEY_ID"),
    teamId: env("APNS_TEAM_ID"),
    bundleId: env("APNS_BUNDLE_ID") ?? "com.example.aria",
    privateKey: env("APNS_PRIVATE_KEY"),
    environment: (env("APNS_ENVIRONMENT") ?? "sandbox") as "sandbox" | "production",
    get configured(): boolean {
      return Boolean(this.keyId && this.teamId && this.privateKey);
    },
  },

  sendgrid: {
    apiKey: env("SENDGRID_API_KEY"),
    fromEmail: env("SENDGRID_FROM_EMAIL"),
    euResidency: env("SENDGRID_EU_RESIDENCY") === "true",
    get configured(): boolean {
      return Boolean(this.apiKey && this.fromEmail);
    },
  },

  twilio: {
    accountSid: env("TWILIO_ACCOUNT_SID"),
    authToken: env("TWILIO_AUTH_TOKEN"),
    fromNumber: env("TWILIO_FROM_NUMBER"),
    region: env("TWILIO_REGION"),
    get configured(): boolean {
      return Boolean(this.accountSid && this.authToken && this.fromNumber);
    },
  },
} as const;

/** Vrai si AUCUN fournisseur n'est configuré (dry-run global). */
export function isGlobalDryRun(): boolean {
  return !config.apns.configured && !config.sendgrid.configured && !config.twilio.configured;
}
