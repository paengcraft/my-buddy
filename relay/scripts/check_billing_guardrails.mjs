import { spawnSync } from "node:child_process";
import { findDisallowedBillingResources } from "./billing-guardrails.mjs";

const result = spawnSync(
  "./node_modules/.bin/wrangler",
  ["deploy", "--config", "wrangler.toml", "--dry-run"],
  { encoding: "utf8" },
);

const output = `${result.stdout ?? ""}\n${result.stderr ?? ""}`;
process.stdout.write(output);

if (result.status !== 0) {
  process.exit(result.status ?? 1);
}

const disallowedResources = findDisallowedBillingResources(output);
if (disallowedResources.length > 0) {
  console.error(
    `Billing guard failed. Disallowed resources detected: ${disallowedResources.join(", ")}`,
  );
  process.exit(1);
}

console.log("Billing guard passed. Only the Worker and approved Durable Object binding were detected.");
