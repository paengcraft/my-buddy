const disallowedResourceLabels = [
  "D1 Database",
  "R2 Bucket",
  "KV Namespace",
  "Workers AI",
  "Vectorize",
  "Queue",
  "Hyperdrive",
  "Browser",
  "Email",
  "Images",
  "Stream",
  "Pipelines",
  "Secrets Store",
  "Service Binding",
];

export function findDisallowedBillingResources(output) {
  return disallowedResourceLabels.filter((label) => output.includes(label));
}
