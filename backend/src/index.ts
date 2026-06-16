import { config, isGlobalDryRun } from "./config.js";
import { log } from "./logger.js";
import { createApp } from "./server.js";

const app = createApp();
app.listen(config.port, () => {
  log.info("aria-backend.listening", {
    port: config.port,
    dryRun: isGlobalDryRun(),
    auth: config.apiToken ? "enabled" : "disabled",
  });
});
