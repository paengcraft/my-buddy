import { describe, expect, test } from "vitest";
import { findDisallowedBillingResources } from "../scripts/billing-guardrails.mjs";

describe("billing guardrails", () => {
  test("allows the existing Worker and Durable Object binding", () => {
    const output = `
Your Worker has access to the following bindings:
Binding                             Resource
env.PAIRING_ROOM (PairingRoom)      Durable Object
`;

    expect(findDisallowedBillingResources(output)).toEqual([]);
  });

  test("flags paid or storage resources outside the approved relay shape", () => {
    const output = `
env.PAIRING_ROOM (PairingRoom)      Durable Object
env.DB (DB)                         D1 Database
env.BUCKET (BUCKET)                 R2 Bucket
env.AI                              Workers AI
`;

    expect(findDisallowedBillingResources(output)).toEqual([
      "D1 Database",
      "R2 Bucket",
      "Workers AI",
    ]);
  });
});
